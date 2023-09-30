
struct Neuron
	Base::Base.RefValue{NeuronBase}
	Params::Base.RefValue{NeuronParams}
	Cache::Base.RefValue{NeuronCache}
	end

Network = Dict{UInt128, Neuron}();
Motivation = Dict{UInt128, Int64}();
mapNameUUID = Dict{String, UInt128}();

function RegisterNeuron(name::String, desc::String, updated_ts::Int64, input_names::Vector, input_types::Vector{DataType}, output_type::DataType, min_update_seconds::Int64, min_update_cache_seconds::Int64, flag_allow_cache::Bool, flag_autotrigger::Bool, weight_priority::Float64, calculation::Function)::UInt128
	# check deps
	input_names = string.(input_names)
	all(map(x->haskey(mapNameUUID,x),input_names)) || throw("Incomplete upstream: " * join(input_names,' '))
	# construct neuron
	n1 = NeuronBase(name, zero(UInt128), desc, updated_ts, input_names, input_types, output_type)
	GenerateUUID!(n1)
	n2 = NeuronParams(min_update_seconds, min_update_cache_seconds, flag_allow_cache, flag_autotrigger, weight_priority)
	n3 = NeuronCache(calculation, Threads.SpinLock(), UInt128[], UInt128[], 0, Ref(nothing), 0, "")
	# register network
	Network[n1.UUID] = Neuron(Ref(n1), Ref(n2), Ref(n3))
	mapNameUUID[n1.UniqueName] = n1.UUID
	# register source
	if isempty(input_names)
		Motivation[n1.UUID] = n3.LastUpdatedTimestamp + n2.MinUpdateIntervalSeconds
	end
	# register stream
	for c in input_names
		if !( n1.UUID in Network[ mapNameUUID[c] ].Cache[].DownstreamUUIDs )
			push!( Network[ mapNameUUID[c] ].Cache[].DownstreamUUIDs, n1.UUID )
		end
		push!( n3.UpstreamUUIDs, mapNameUUID[c] )
	end
	return n1.UUID
	end

function RegisterNeuronSimple(f::Function, updated_ts::Int64, output_type::DataType)::UInt128
	@assert length(methods(f)) == 1
	tmpMeta  = methods(f).ms[1]
	tmpNames = string(tmpMeta)
	tmpNames = eachmatch(r"[\(, ](.+?)::.+?[,\)]", tmpNames) |> collect
	tmpNames = map(x->string(x.captures[1]), tmpNames)
	tmpTypes = Vector{DataType}(collect(tmpMeta.sig.types[2:end]))
	return RegisterNeuron( string(tmpMeta.name), "auto generated", updated_ts, tmpNames, tmpTypes, output_type, 3, 60, false, true, 10.0, f )
	end

function RegisterNeuronAuto(name::String, desc::String, updated_ts::Int64, input_names::Vector, output_type::DataType, calculation::Function)::UInt128
	@assert length(methods(calculation)) == 1
	tmpMeta  = methods(calculation).ms[1]
	tmpTypes = Vector{DataType}(collect(tmpMeta.sig.types[2:end]))
	return RegisterNeuron( name, desc, updated_ts, input_names, tmpTypes, output_type, 3, 60, false, true, 10.0, calculation )
	end

function SetNeuronParams(name::String, min_update_seconds::Int64, min_update_cache_seconds::Int64, flag_allow_cache::Bool, flag_autotrigger::Bool, weight_priority::Float64)::Nothing
	p = Network[ mapNameUUID[name] ].Params[]
	p.MinUpdateIntervalSeconds = min_update_seconds
	p.MinUpdateCacheIntervalSeconds = min_update_cache_seconds
	p.SwitchAllowCache = flag_allow_cache
	p.SwitchAutoTrigger = flag_autotrigger
	p.WeightPriority = weight_priority
	return nothing
	end











