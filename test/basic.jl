using Blaze
using Test

@testset "Blaze.jl" begin
  # neuron.jl
  @test typeof( Blaze.new(Blaze.NeuronCache) ) == Blaze.NeuronCache
  @test iszero( Blaze.new(Blaze.NeuronParams).MinUpdateIntervalSeconds )
  n = Blaze.NeuronBase(
    "testName",
    zero(UInt128),
    "something here, safe to change any time",
    1695614400,
    String["x1", "x2", "longitude"],
    DataType[Vector{Int}, Float64, String],
    Vector{Float64},
    )
  Blaze.GenerateUUID!(n)
  @test !iszero(n.UUID)
end
