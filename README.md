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

# Explicit function definitions

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
Blaze.RegisterNeuron("/root/spider", SomeSpider, [], "node description here")
Blaze.RegisterNeuron("/analysis/1", SomeAnalysis, ["/root/spider"], "<- unique path name, handler function, input params")
Blaze.RegisterNeuron("/analysis/2", OtherFactors, ["/root/spider"], "length(input_names) == number of input params of handler function")
Blaze.RegisterNeuron("/output", Sumarrize, ["/analysis/1", "/analysis/2"], "pass input params in order")



# Runtime

#Blaze.Trigger("/root/spider") # shall be triggered by CRON
Blaze.AutoTrigger()            # equivalent; trigger all expired motivation
Blaze.ExecuteRevision()        # optional; idempotent.
@show Blaze.View("/output")    # just for REPL
# 3.0


```


### Todos
1. [ ] Structurized visualization.
1. [ ] Topology structure display in command line.
1. [ ] Simple HTTP interface.


### Issues

