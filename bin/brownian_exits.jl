#!/usr/bin/env julia

using BrownianExits
using ArgParse

function parse_arguments()
    s = ArgParseSettings(
        description = "Simulate Brownian motions with domain exits",
        version = "1.0",
        add_version = true
    )

    @add_arg_table! s begin
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
        "--max-exits"
            help = "Maximum number of exits to simulate"
            arg_type = Int
            default = 50000
        "--paths-per-thread"
            help = "Number of simultaneous paths per thread"
            arg_type = Int
            default = 100
        "--step-size"
            help = "Size of each step in the Brownian motion"
            arg_type = Float64
            default = 0.05
        "--output-csv"
            help = "Output CSV file for path segments"
            default = "brownian_paths.csv"
        "--seed"
            help = "Random seed for reproducibility"
            arg_type = Int
            default = nothing
            required = false
    end

    return parse_args(s)
end

function main()
    args = parse_arguments()

    # Set random seed if provided
    if !isnothing(args["seed"])
        Random.seed!(args["seed"])
    end 

    # Extract domain boundaries from arguments
    domain_x = (args["domain-x-min"], args["domain-x-max"])
    domain_y = (args["domain-y-min"], args["domain-y-max"])

    # Print simulation parameters
    println("Simulation Parameters:")
    println("---------------------")
    println("Domain X: ", domain_x)
    println("Domain Y: ", domain_y)
    println("Max Exits: ", args["max-exits"])
    println("Paths per Thread: ", args["paths-per-thread"])
    println("Step Size: ", args["step-size"])
    println("Number of Threads: ", Threads.nthreads())
    println("Random Seed: ", isnothing(args["seed"]) ? "random" : args["seed"])

    # Run simulation
    path_segments = simulate_brownian_motions(
        domain_x, domain_y; 
        max_global_exits=args["max-exits"],
        paths_per_thread=args["paths-per-thread"],
        step_size=args["step-size"]
    )

    CSV.write(args["output-csv"], path_segments)
    println("\nSaved path segments to: ", args["output-csv"])

    # Analysis
    println("\nResults:")
    println("Total path segments: ", nrow(path_segments))
    
    unique_path_ids = unique(path_segments.path_id)
    println("Total unique paths: ", length(unique_path_ids))
    
    exit_segments = path_segments[path_segments.has_exited, :]
    println("Total exits: ", nrow(exit_segments))
    
    # Time analysis
    steps_per_path = combine(
        groupby(path_segments, :path_id), 
        nrow => :steps
    )
    println("\nSteps per path:")
    display(describe(steps_per_path.steps))

    return path_segments
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end