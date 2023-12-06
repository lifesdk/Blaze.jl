# directly copied from ../README.md

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

@testset "Blaze.jl" begin
	Blaze.RegisterNeuron("/root/spider", SomeSpider, [], "node description here")
	Blaze.RegisterNeuron("/analysis/1", SomeAnalysis, ["/root/spider"], "<- unique path name, handler function, input params")
	Blaze.RegisterNeuron("/analysis/2", OtherFactors, ["/root/spider"], "length(input_names) == number of input params of handler function")
	Blaze.RegisterNeuron("/output", Sumarrize, ["/analysis/1", "/analysis/2"], "pass input params in order")
	Blaze.AutoTrigger()
	Blaze.ExecuteRevision()
	@test isequal(Blaze.View("/output"), 3.0)
	end
