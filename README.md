[![CI](https://github.com/sam-vermeulen/BrownianExits.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/sam-vermeulen/BrownianExits.jl/actions/workflows/CI.yml)

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

## License

This project is licensed under the MIT License - see the LICENSE file for details.