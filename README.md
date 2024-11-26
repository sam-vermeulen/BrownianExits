# Brownian Motion Exit Point Simulation

This Julia package simulates multiple simultaneous Brownian motion paths within a rectangular domain and tracks their exit points. The simulation efficiently handles parallel path generation, exact intersection point calculation, and provides detailed visualizations of the paths.

## Features

The simulation package offers functionality for studying Brownian motion paths on rectangular domains:

1. Parallel simulation of multiple Brownian paths using Julia's multi-threading capabilities
2. Exact calculation of domain boundary intersection points
3. Thread-safe data collection and processing
4. Detailed visualization of random paths with clear marking of start points, intersection points, and exit points
5. Comprehensive CSV output containing all path segments and intersection data
6. Configurable parameters via command-line interface

## Installation

First, ensure you have Julia 1.6 or later installed. Then install the required packages:

```julia
import Pkg
Pkg.add(["Random", "LinearAlgebra", "Distributions", "DataFrames", "CSV", "Plots", "ArgParse"])
```

Clone this repository and install the package:

```bash
git clone https://github.com/sam-vermeulen/BrownianExits.git
cd BrownianExits
julia --project -e 'using Pkg; Pkg.develop(path=".")'
```

## Command Line Interface

The package includes a command-line interface for running simulations. After installation, you can run simulations using the following syntax:

```bash
brownian_exits [options]
```

### Command Line Arguments

The simulation supports extensive customization through command-line arguments:

```
--domain-x-min FLOAT    Minimum x value of domain (default: 0.0)
--domain-x-max FLOAT    Maximum x value of domain (default: 1.0)
--domain-y-min FLOAT    Minimum y value of domain (default: -0.5)
--domain-y-max FLOAT    Maximum y value of domain (default: 0.5)
--max-exits INT         Maximum number of exits to simulate (default: 50000)
--paths-per-thread INT  Number of simultaneous paths per thread (default: 100)
--step-size FLOAT       Size of each step in the Brownian motion (default: 0.05)
--output-csv STRING     Output CSV file for path segments (default: "brownian_paths.csv")
--plot-output STRING    Output file for path visualization (default: "brownian_paths.png")
--plot-paths INT        Number of random paths to plot (default: 5)
--seed INT             Random seed for reproducibility (optional)
```

### Usage Examples

Basic simulation with default parameters:
```bash
brownian_exits
```

Custom domain and number of exits:
```bash
brownian_exits \
  --domain-x-min -2.0 \
  --domain-x-max 2.0 \
  --domain-y-min -1.0 \
  --domain-y-max 1.0 \
  --max-exits 10000
```

Control simulation parameters and output:
```bash
brownian_exits \
  --step-size 0.1 \
  --paths-per-thread 200 \
  --output-csv "results.csv" \
  --plot-output "paths.png" \
  --plot-paths 10
```

Reproducible simulation with random seed:
```bash
brownian_exits --seed 12345
```

### Performance Optimization

For optimal performance, set the number of threads and use performance flags:

```bash
# Set number of threads
export JULIA_NUM_THREADS=8

# Run with performance flags
julia -O3 --check-bounds=no brownian_exits \
  --max-exits 100000 \
  --paths-per-thread 200
```

## Output Format

### CSV Data Structure

The simulation generates a CSV file containing the following columns:

- `path_id`: Unique identifier for each path
- `step`: Step number within the path
- `start_x`: Starting x-coordinate of segment
- `start_y`: Starting y-coordinate of segment
- `end_x`: Ending x-coordinate of segment
- `end_y`: Ending y-coordinate of segment
- `has_exited`: Boolean indicating if this segment crossed the domain boundary
- `intersection_x`: x-coordinate of domain intersection point (if path exited)
- `intersection_y`: y-coordinate of domain intersection point (if path exited)

### Visualization

The generated visualization includes:
- Solid lines showing path trajectories inside the domain
- Dotted lines showing path continuations outside the domain
- Circle markers for start points
- Diamond markers for boundary intersection points
- Star markers for exit points
- Dashed lines showing the domain boundary
- Legend identifying all path components

## Programmatic Usage

You can also use the package programmatically in your Julia code:

```julia
using BrownianExits

# Define simulation parameters
domain_x = (0.0, 1.0)
domain_y = (-0.5, 0.5)

# Run simulation
path_segments = simulate_brownian_motions(
    domain_x, domain_y;
    max_global_exits = 50000,
    paths_per_thread = 100,
    step_size = 0.05
)

# Create visualization
visualize_random_paths(
    path_segments;
    n_paths = 5,
    domain_x = domain_x,
    domain_y = domain_y,
    output_file = "paths.png"
)
```

## Performance Considerations

The simulation is designed for parallel execution using Julia's multi-threading capabilities. For optimal performance:

1. Set the appropriate number of threads using the `JULIA_NUM_THREADS` environment variable
2. Adjust `paths_per_thread` based on your available computational resources
3. Choose an appropriate `step_size` for your required precision
4. Consider the tradeoff between `max_exits` and simulation time

## License

This project is licensed under the MIT License - see the LICENSE file for details.