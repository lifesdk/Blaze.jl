using Blaze
using Test

@testset "Blaze.jl" begin
  # neuron.jl
  n = Blaze.Neuron(
    "testName",
    zero(UInt128),
    "something here, safe to change any time",
    1695614400,
    String["x1", "x2", "longitude"],
    Blaze.MsgPack.pack([1,"2",3.0]),
    Vector{Float64},
    )
  @test !iszero(Blaze.GenerateUUID!(n))
end
