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

# Example usage
function main()

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


if abspath(PROGRAM_FILE) == @__FILE__
    main()
end