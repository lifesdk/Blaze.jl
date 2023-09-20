using Blaze
using Test

@testset "Blaze.jl" begin
    # Write your tests here.
    @test Blaze.greet_your_package_name() == "Hello YourPackageName!"
    @test Blaze.greet_your_package_name() != "Hello world!"
end
