# [test/runtests.jl]

using BrownianExits
using Test
using DataFrames

@testset "BrownianExits.jl" begin
    @testset "Simulation" begin
        # Test basic simulation
        domain_x = (0.0, 1.0)
        domain_y = (-0.5, 0.5)
        max_exits = 100
        
        df = simulate_brownian_motions(
            domain_x, domain_y;
            max_global_exits=max_exits
        )
        
        @test df isa DataFrame
        @test sum(df.has_exited) == max_exits
        @test all(x -> domain_x[1] <= x <= domain_x[2], df[.!df.has_exited, :start_x])
        @test all(x -> domain_y[1] <= x <= domain_y[2], df[.!df.has_exited, :start_y])
    end

    @testset "Exit Point Calculation" begin
        # Test intersection calculation
        x1, y1 = 0.5, 0.0  # Inside point
        x2, y2 = 1.5, 0.0  # Outside point (right boundary)
        domain_x = (0.0, 1.0)
        domain_y = (-0.5, 0.5)
        
        t = find_exit_point(x1, y1, x2, y2, domain_x, domain_y)
        @test 0.0 <= t <= 1.0
        
        # Test intersection point is on boundary
        ix = x1 + t * (x2 - x1)
        iy = y1 + t * (y2 - y1)
        @test isapprox(ix, 1.0, atol=1e-10)  # Right boundary
    end
end