using Blaze
using Test

function RandomVectorFloat64()
  return rand(Float64, 20)
  end


@testset "Blaze.jl" begin
  tmpTs = round(Int,time())
  @test Blaze.RegisterNeuronSimple(RandomVectorFloat64, tmpTs, Vector{Float64})
  @test length(Blaze.Network) > 0
  @test haskey(Blaze.Network,Blaze.mapNameUUID["RandomVectorFloat64"])
  end
