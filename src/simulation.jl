using Random
using LinearAlgebra
using Distributions
using DataFrames
using CSV
using ArgParse

"""
Simulate multiple simultaneous Brownian motions with a global exit limit.

# Arguments
- `domain_x`: Tuple defining the x-axis boundaries (min_x, max_x)
- `domain_y`: Tuple defining the y-axis boundaries (min_y, max_y)
- `max_global_exits`: Total number of exits allowed before termination
- `paths_per_thread`: Number of simultaneous paths per thread
- `step_size`: Size of each step (standard deviation of the normal distribution)

# Returns
- `path_segments`: DataFrame containing detailed path segment information
"""
function simulate_brownian_motions(
    domain_x::Tuple{Float64, Float64}, 
    domain_y::Tuple{Float64, Float64}; 
    max_global_exits::Int = 10000,
    paths_per_thread::Int = 100,
    step_size::Float64 = 0.1
)
    # Unpack domain boundaries
    x_min, x_max = domain_x
    y_min, y_max = domain_y

    # Thread-safe counters
    path_id_counter = Threads.Atomic{Int}(0)
    global_exit_counter = Threads.Atomic{Int}(0)

    # Prepare DataFrame to store path segments
    path_segments = DataFrame(
        path_id = Int[],
        step = Int[],
        start_x = Float64[],
        start_y = Float64[],
        end_x = Float64[],
        end_y = Float64[],
        has_exited = Bool[],
        intersection_x = Union{Float64, Missing}[],
        intersection_y = Union{Float64, Missing}[],
        exit_boundary = Union{String, Missing}[],
        boundary_value = Union{Float64, Missing}[]
    )

    # Synchronization primitives
    path_segments_lock = ReentrantLock()
    
    # Parallel simulation of Brownian motions
    Threads.@threads for _thread_idx in 1:Threads.nthreads()
        # Local RNG for this thread
        rng = MersenneTwister(rand(UInt))
        
        # State for each active path in this thread
        active_paths = []
        
        # Initialize paths for this thread
        for _ in 1:paths_per_thread
            # Get a unique path ID
            current_path_id = Threads.atomic_add!(path_id_counter, 1)
            
            # Random starting position
            start_x = x_min + rand(rng) * (x_max - x_min)
            start_y = y_min + rand(rng) * (y_max - y_min)
            
            push!(active_paths, (
                id = current_path_id,
                x = start_x,
                y = start_y,
                step_count = 0
            ))
        end
        
        # Continue until exit limit reached
        while !isempty(active_paths) && 
            Threads.atomic_add!(global_exit_counter, 0) < max_global_exits
            
            # Process one step for each active path
            i = 1
            while i <= length(active_paths)
                path = active_paths[i]
                
                # Generate step
                dx = step_size * randn(rng)
                dy = step_size * randn(rng)
                
                new_x = path.x + dx
                new_y = path.y + dy
                
                # Increment step count
                new_step_count = path.step_count + 1
                
                # Check for exit
                if (new_x < x_min || new_x > x_max || 
                    new_y < y_min || new_y > y_max)


                    # Find intersection point
                    t = find_exit_point(
                        path.x, path.y, 
                        new_x, new_y, 
                        domain_x, domain_y
                    )
                    
                    # Calculate intersection point
                    intersection_x = path.x + t * dx
                    intersection_y = path.y + t * dy
                    
                    # Determine which boundary was crossed
                    exit_boundary, boundary_value = identify_exit_boundary(
                        intersection_x, intersection_y,
                        x_min, x_max, y_min, y_max
                    )

                    # Check exit limit
                    if Threads.atomic_add!(global_exit_counter, 1) >= max_global_exits
                        break
                    end
                
                    # Record segment with an exit
                    Threads.lock(path_segments_lock) do
                        push!(path_segments, (
                            path_id = path.id,
                            step = new_step_count,
                            start_x = path.x,
                            start_y = path.y,
                            end_x = new_x,
                            end_y = new_y,
                            has_exited = true,
                            intersection_x = intersection_x,
                            intersection_y = intersection_y,
                            exit_boundary = exit_boundary,
                            boundary_value = boundary_value
                        ))
                    end

                    # Start new path
                    new_path_id = Threads.atomic_add!(path_id_counter, 1)
                    start_x = x_min + rand(rng) * (x_max - x_min)
                    start_y = y_min + rand(rng) * (y_max - y_min)
                    
                    # Replace current path with new one
                    active_paths[i] = (
                        id = new_path_id,
                        x = start_x,
                        y = start_y,
                        step_count = 0
                    )
                else
                
                    # Record segment without an exit
                    Threads.lock(path_segments_lock) do
                        push!(path_segments, (
                            path_id = path.id,
                            step = new_step_count,
                            start_x = path.x,
                            start_y = path.y,
                            end_x = new_x,
                            end_y = new_y,
                            has_exited = false,
                            intersection_x = missing,
                            intersection_y = missing,
                            exit_boundary = missing,
                            boundary_value = missing
                        ))
                    end
                    
                    # Update path position
                    active_paths[i] = (
                        id = path.id,
                        x = new_x,
                        y = new_y,
                        step_count = new_step_count
                    )
                    i += 1
                end
            end
        end
    end

    return remove_non_exiting_paths(path_segments)
end

function remove_non_exiting_paths(df::DataFrame)
    # Find all path IDs that have at least one exit
    exiting_paths = unique(df[df.has_exited, :path_id])
    
    # Filter the DataFrame to keep only paths that reached an exit
    filtered_df = df[in.(df.path_id, Ref(Set(exiting_paths))), :]
    
    # Calculate statistics for logging
    original_paths = length(unique(df.path_id))
    remaining_paths = length(exiting_paths)
    removed_paths = original_paths - remaining_paths
    original_segments = nrow(df)
    remaining_segments = nrow(filtered_df)
    removed_segments = original_segments - remaining_segments
    
    return filtered_df
end

"""
Identify which boundary was crossed and its value.

Returns a tuple of (boundary_name, boundary_value) where boundary_name is one of:
"left", "right", "bottom", "top"
"""
function identify_exit_boundary(
    x::Float64, y::Float64,
    x_min::Float64, x_max::Float64,
    y_min::Float64, y_max::Float64;
    tol::Float64 = 1e-10
)
    if isapprox(x, x_min, atol=tol)
        return "left", x_min
    elseif isapprox(x, x_max, atol=tol)
        return "right", x_max
    elseif isapprox(y, y_min, atol=tol)
        return "bottom", y_min
    elseif isapprox(y, y_max, atol=tol)
        return "top", y_max
    else
        error("Point ($x, $y) is not on any boundary")
    end
end

"""
Find the exact point of exit from the domain using line-domain intersection.
"""
function find_exit_point(
    x1::Float64, y1::Float64, 
    x2::Float64, y2::Float64, 
    domain_x::Tuple{Float64, Float64}, 
    domain_y::Tuple{Float64, Float64}
)
    x_min, x_max = domain_x
    y_min, y_max = domain_y

    dx = x2 - x1
    dy = y2 - y1

    tx_min = (x_min - x1) / dx
    tx_max = (x_max - x1) / dx
    ty_min = (y_min - y1) / dy
    ty_max = (y_max - y1) / dy

    t_candidates = [tx_min, tx_max, ty_min, ty_max]
    valid_candidates = filter(t -> (
        0 <= t <= 1 && 
        x1 + t*dx >= x_min && x1 + t*dx <= x_max &&
        y1 + t*dy >= y_min && y1 + t*dy <= y_max
    ), t_candidates)

    return isempty(valid_candidates) ? 1.0 : minimum(valid_candidates)
end