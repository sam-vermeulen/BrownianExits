module BrownianExits

using Random
using LinearAlgebra
using Distributions
using DataFrames
using CSV
using Plots

# Export public interface
export simulate_brownian_motions
export visualize_random_paths
export find_exit_point

# Include implementation files
include("simulation.jl")
include("visualization.jl")

end # module