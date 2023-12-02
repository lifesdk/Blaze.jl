# Blaze

[![Build Status](https://github.com/Cyvadra/Blaze.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/Cyvadra/Blaze.jl/actions/workflows/CI.yml?query=branch%3Amain)

### Purpose
- Implement data transparency like R Studio but production-ready and structurized.
- Automate pipelines by predefining procedures.
- Build a framework that helps project refactoring.


### Intro
A functional reactive programming framework.


### Usage
```julia

# Explicit functions

struct Row
	Timestamp::Float64
	Value::Float64
	Bias::Float64
	end
function SomeSpider()::Vector{Row}
	# ...
	return [ Row(time(), 1.0, 0.1), Row(time(), 2.0, 0.2) ]
	end
function SomeAnalysis(v::Vector{Row})::Vector{Float64}
	return map(x->x.Value + x.Bias, v)
	end
function OtherFactors(v::Vector{Row})::Vector{Float64}
	return map(x->x.Bias, v)
	end
function Sumarrize(value_mean::Vector{Float64}, factors::Vector{Float64})::Float64
	return sum( value_mean .- factors )
	end



# Register network

using Blaze
const REVISE_TIMESTAMP = 1701526800
rootUUID = Blaze.RegisterNeuronAuto("/root/spider", "since SomeSpider doesn't take any params, use an empty array as its input.", REVISE_TIMESTAMP, String[], SomeSpider)
Blaze.RegisterNeuronAuto("/analysis/1", "path names are user-defined", REVISE_TIMESTAMP, String["/root/spider"], SomeAnalysis)
Blaze.RegisterNeuronAuto("/analysis/2", "as long as you quote it correctly", REVISE_TIMESTAMP, String["/root/spider"], OtherFactors)
Blaze.RegisterNeuronAuto("/output", "pass neuron names in order", REVISE_TIMESTAMP, String["/analysis/1", "/analysis/2"], Sumarrize)



# Use CRON or similar logic to trigger updates, then

Blaze.Commit(rootUUID)
Blaze.ExecuteRevision()
@show Blaze.View("/output")



```
