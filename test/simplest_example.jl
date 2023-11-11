
function RandomVectorFloat64()::Vector{Float64}
  return rand(Float64, 20)
  end
function RandomeVectorSmoothed32(v::Vector{Float64})::Vector{Float32}
  vRet = zeros(Float32,length(v))
  numMa = 5
  vRet[1] = v[1]
  for i in 2:length(v)
    vRet[i] = ((numMa-1)*vRet[i-1] + 1.5v[i]) / (numMa+0.5)
  end
  return vRet
  end


@testset "Blaze.jl" begin
  tmpTs = round(Int,time())
  # unit test
  Blaze.RegisterNeuronSimple(RandomVectorFloat64, "generate a float64 vector whose length is 20", tmpTs)
  @test length(Blaze.Network) > 0
  @test haskey(Blaze.Network,Blaze.mapNameUUID["RandomVectorFloat64"])
  # name test
  Blaze.RegisterNeuronAuto("random_float64_20", "generate a random float64 vector whose length", tmpTs, String[], RandomVectorFloat64)
  @test length(Blaze.Network) > 1
  @test Blaze.SetNeuronParams("random_float64_20", 1, false, 0.0) |> isnothing
  # dependency test
  Blaze.RegisterNeuronAuto("random_float64_20_smoothed", "like random_float64_20", tmpTs, String["random_float64_20"], RandomeVectorSmoothed32)
  @test length(Blaze.Network) > 2
  end
