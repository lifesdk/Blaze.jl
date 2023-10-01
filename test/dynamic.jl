using Blaze
using Test
using Random

function CurrentTimestamp()::Int64
  round(Int,time())
  end
function BackgroundNoiseWhen(ts::Int64)::Vector{Float64}
  rng = Random.Xoshiro(ts)
  rand(rng,Float64,20)
  end
function AnotherBackgroundNoise(ts::Int64)::Vector{Float64}
  rng = Random.MersenneTwister(ts)
  rand(rng,Float64,20)
  end
function SomeEntangle(v1::Vector{Float64}, v2::Vector{Float64})::Vector{Float64}
  return v1 .- v2
  end
function SomeStatistic(v::Vector{Float64})::Float64
  return reduce(+,v) / length(v)
  end


@testset "Blaze.jl" begin
  tmpTs = 1696075200
  # unit test
  tmpIds = zeros(UInt128,5)
  tmpIds[1] = Blaze.RegisterNeuronAuto("/sys/timestamp", "", tmpTs, String[], CurrentTimestamp)
  tmpIds[2] = Blaze.RegisterNeuronAuto("/var/noise_1", "", tmpTs, String["/sys/timestamp"], BackgroundNoiseWhen)
  tmpIds[3] = Blaze.RegisterNeuronAuto("/var/noise_2", "", tmpTs, String["/sys/timestamp"], AnotherBackgroundNoise)
  tmpIds[4] = Blaze.RegisterNeuronAuto("/calc/foobar", "", tmpTs, String["/var/noise_1", "/var/noise_2"], SomeEntangle)
  tmpIds[5] = Blaze.RegisterNeuronAuto("/calc/result", "", tmpTs, String["/calc/foobar"], SomeStatistic)
  # basic
  @test all(map(id->id in collect(values(Blaze.mapNameUUID)),tmpIds))
  @test haskey(Blaze.Motivation, tmpIds[1])
  @test haskey(Blaze.Network,Blaze.mapNameUUID["/calc/foobar"])
  # trigger motivation
  @test isnothing( Blaze.Commit(tmpIds[1]) )
  @show @time Blaze.ExecuteRevision()
  @test Blaze.Network[tmpIds[5]].Cache[].LastUpdatedTimestamp > tmpTs
  @test !isnothing(Blaze.Network[tmpIds[5]].Cache[].LastResult[])
  @test typeof(Blaze.Network[tmpIds[5]].Cache[].LastResult[]) == Float64
  for i in 1:5
    @info i
    @info Blaze.Network[tmpIds[i]].Base[].UniqueName
    @info Blaze.Network[tmpIds[i]].Cache[].LastResult[]
  end
  end
