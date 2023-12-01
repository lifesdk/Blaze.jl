
function CurrentTimestamp()::Float64
  time()
  end
function BackgroundNoiseWhen(ts::Float64)::Vector{Float64}
  # rng = Random.Xoshiro(ts)
  # rand(rng,Float64,20)
  rand(Float64,20)
  end
function AnotherBackgroundNoise(ts::Float64)::Vector{Float64}
  # rng = Random.MersenneTwister(ts)
  # rand(rng,Float64,20)
  rand(Float64,20)
  end
function SomeEntangle(v1::Vector{Float64}, v2::Vector{Float64})::Vector{Float64}
  return v1 .- v2
  end
function SomeEntangleRenewed(v1::Vector{Float64}, v2::Vector{Float64})::Vector{Float64}
  return v1 .- v2 .+ 10
  end
function SomeStatistic(v::Vector{Float64})::Float64
  return reduce(+,v) / length(v)
  end


@testset "Blaze.jl" begin
  tmpTs = 1696075200
  # unit test
  tmpIds = zeros(UInt128,5)
  tmpIds[1] = Blaze.RegisterNeuronAuto("/sys/timestamp", "desc: level 0", tmpTs, String[], CurrentTimestamp)
  tmpIds[2] = Blaze.RegisterNeuronAuto("/var/noise_1", "level 1, original", tmpTs, String["/sys/timestamp"], BackgroundNoiseWhen)
  tmpIds[3] = Blaze.RegisterNeuronAuto("/var/noise_2", "level 1", tmpTs, String["/sys/timestamp"], AnotherBackgroundNoise)
  tmpIds[4] = Blaze.RegisterNeuronAuto("/calc/foobar", "level 2", tmpTs, String["/var/noise_1", "/var/noise_2"], SomeEntangle)
  tmpIds[5] = Blaze.RegisterNeuronAuto("/calc/result", "level 3", tmpTs, String["/calc/foobar"], SomeStatistic)
  # basic
  @test all(map(id->id in collect(values(Blaze.mapNameUUID)),tmpIds))
  @test haskey(Blaze.Motivation, tmpIds[1])
  @test haskey(Blaze.Network,Blaze.mapNameUUID["/calc/foobar"])
  # detail
  @test iszero(Blaze.Detail(tmpIds[1]).NumLevel)
  @test isequal(Blaze.Detail("/calc/result").NumLevel, 3)
  # renew neuron
  tmpId = Blaze.RegisterNeuronAuto("/var/noise_1", "neuron upgrade test", tmpTs+10, String["/sys/timestamp"], BackgroundNoiseWhen)
  @test !isequal(tmpIds[2], tmpId)
  tmpIds[2] = tmpId
  # trigger motivation
  @test isnothing( Blaze.Commit(tmpIds[1]) )
  tmpTask = @async Blaze.ExecuteRevision()
  # upgrade inside runtime
  tmpIds[2] = Blaze.RegisterNeuronAuto("/var/noise_1", "neuron upgrade test", tmpTs+20, String["/sys/timestamp"], BackgroundNoiseWhen)
  tmpIds[4] = Blaze.RegisterNeuronAuto("/calc/foobar", "level 2 renewed", tmpTs+20, String["/var/noise_1", "/var/noise_2"], SomeEntangleRenewed)
  wait(tmpTask)
  # continue trigger
  @test Blaze.LastUpdated(tmpIds[5]) > tmpTs
  @test !isnothing(Blaze.Network[tmpIds[5]].Cache[].LastResult[])
  @test typeof(Blaze.View("/calc/result")) == Float64
  for i in 1:5
    @info i
    @info Blaze.Network[tmpIds[i]].Base[].UniqueName
    @info Blaze.Network[tmpIds[i]].Cache[].LastResult[]
  end
  end
