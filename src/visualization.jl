using Plots
using Random
using DataFrames
using ArgParse
using CSV


"""
Create a visualization of random Brownian motion paths from the simulation data.

# Arguments
- `path_segments`: DataFrame containing the path segments
- `n_paths`: Number of random paths to visualize (default: 5)
- `domain_x`: x-axis domain boundaries
- `domain_y`: y-axis domain boundaries
- `output_file`: Optional file to save the plot (default: "brownian_paths.png")

# Returns
- The generated plot object
"""
function visualize_random_paths(
    input_file::String;
    n_paths::Int = 5,
    domain_x::Tuple{Float64, Float64} = (0.0, 1.0),
    domain_y::Tuple{Float64, Float64} = (0.0, 1.0),
    output_file::String = "brownian_paths.png"
)

    path_segments = CSV.read(input_file, DataFrame)

    # Get unique path IDs
    unique_paths = unique(path_segments.path_id)
    
    # Randomly select paths to visualize
    rng = Random.default_rng()
    selected_paths = sort(shuffle(rng, unique_paths)[1:min(n_paths, length(unique_paths))])
    
    # Create the base plot
    plt = plot(
        xlabel = "x",
        ylabel = "y",
        title = "Brownian Motion Paths",
        aspect_ratio = :equal,
        legend = :outerright,
        xlims = (domain_x[1] - 0.05, domain_x[2] + 0.05),  # Slightly expanded limits
        ylims = (domain_y[1] - 0.05, domain_y[2] + 0.05),  # to show exit points
        grid = true,
        gridstyle = :dash,
        gridalpha = 0.3,
        framestyle = :box,  # Ensure box-style frame
        foreground_color_axis = :white,  # Make axis lines white
        foreground_color_border = :black,  # Keep border black
    )
    
    # Add domain boundary
    x_min, x_max = domain_x
    y_min, y_max = domain_y
    plot!(plt, 
        [x_min, x_max, x_max, x_min, x_min],
        [y_min, y_min, y_max, y_max, y_min],
        color = :black,
        label = "Domain",
        linestyle = :dash,
        linewidth = 1.5
    )

    # Plot each selected path
    colors = distinguishable_colors(n_paths, [RGB(0.5,0.5,0.5), RGB(0,0,0)])
    
    # First plot all paths
    for (i, path_id) in enumerate(selected_paths)
        path_data = path_segments[path_segments.path_id .== path_id, :]
        sort!(path_data, :step)
        
        # Collect points
        points_x = Float64[]
        points_y = Float64[]
        
        push!(points_x, path_data[1, :start_x])
        push!(points_y, path_data[1, :start_y])
        
        for row in eachrow(path_data)
            push!(points_x, row.end_x)
            push!(points_y, row.end_y)
        end
        
        # Plot the path
        plot!(plt, 
            points_x, 
            points_y,
            label = "Path $(path_id)",
            color = colors[i],
            linewidth = 1.5,
            alpha = 0.8
        )
    end
    
    # Then plot all start and exit points on top
    for (i, path_id) in enumerate(selected_paths)
        path_data = path_segments[path_segments.path_id .== path_id, :]
        sort!(path_data, :step)
        
        # Start point
        start_x = path_data[1, :start_x]
        start_y = path_data[1, :start_y]
        scatter!(plt,
            [start_x],
            [start_y],
            color = colors[i],
            label = nothing,
            markersize = 6,
            markershape = :circle,
            markerstrokewidth = 1,
            markerstrokecolor = :white
        )
        
        # Exit point if path exited
        if any(path_data.has_exited)

            exit_row = path_data[path_data.has_exited, :][1, :]

            # Intersection point
            scatter!(plt,
                [exit_row.intersection_x],
                [exit_row.intersection_y],
                color = colors[i],
                label = nothing,
                markersize = 6,
                markershape = :diamond,
                markerstrokewidth = 1,
                markerstrokecolor = :white
            )
            
            # Add exit point with white outline for visibility
            scatter!(plt,
                [exit_row.end_x],
                [exit_row.end_y],
                color = colors[i],
                label = nothing,
                markersize = 8,
                markershape = :star5,
                markerstrokewidth = 1,
                markerstrokecolor = :white
            )
        end
    end
    
    # Add legend entries for markers
    scatter!(plt, [], [], color = :black, markershape = :circle, 
            markersize = 6, label = "Start points", markerstrokewidth = 1, 
            markerstrokecolor = :white)
    scatter!(plt, [], [], color = :black, markershape = :diamond, 
            markersize = 6, label = "Intersection points", markerstrokewidth = 1, 
            markerstrokecolor = :white)
    scatter!(plt, [], [], color = :black, markershape = :star5, 
            markersize = 8, label = "Exit points", markerstrokewidth = 1, 
            markerstrokecolor = :white, alpha = 0.5)

    # Redraw the border on top
    plot!(plt, 
        [x_min, x_max, x_max, x_min, x_min],
        [y_min, y_min, y_max, y_max, y_min],
        color = :black,
        label = nothing,
        linestyle = :solid,
        linewidth = 1.0,
        primary = false
    )
    
    # Save if output file specified
    if !isnothing(output_file)
        savefig(plt, output_file)
        println("Plot saved to: $output_file")
    end
    
    return plt
end

function parse_arguments()
    s = ArgParseSettings(
        description = "Simulate Brownian motions with domain exits",
        version = "1.0",
        add_version = true
    )

    @add_arg_table! s begin
        "--input-csv"
            help = "Input csv file for the path data"
        "--plot-output"
            help = "Output file for path visualization"
            default = "brownian_paths.png"
        "--n-paths"
            help = "Number of random paths to plot"
            arg_type = Int
            default = 5
        "--domain-x-min"
            help = "Minimum x value of domain"
            arg_type = Float64
            default = 0.0
        "--domain-x-max"
            help = "Maximum x value of domain"
            arg_type = Float64
            default = 1.0
        "--domain-y-min"
            help = "Minimum y value of domain"
            arg_type = Float64
            default = 0.0
        "--domain-y-max"
            help = "Maximum y value of domain"
            arg_type = Float64
            default = 1.0
    end

    return parse_args(s)
end

function main(output_file::String = "brownian_paths.csv")

    args = parse_arguments()

    # Extract domain boundaries from arguments
    domain_x = (args["domain-x-min"], args["domain-x-max"])
    domain_y = (args["domain-y-min"], args["domain-y-max"])

    visualize_random_paths(args["input-csv"], 
        n_paths=args["n-paths"], 
        domain_x=domain_x, 
        domain_y=domain_y, 
        output_file=args["plot-output"])
end

# Run if script is called directly
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end