using Blaze
using Test

@testset "Blaze.jl" begin
    # neuron.jl
    @test !iszero( Blaze.GenerateUUID!( Blaze.new(Blaze.Neuron) ) )
end
