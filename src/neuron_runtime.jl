
struct Neuron
	Base::Base.RefValue{NeuronBase}
	Params::Base.RefValue{NeuronParams}
	Cache::Base.RefValue{NeuronCache}
	end

Network = Dict{UInt128, Neuron}();
Motivation = Dict{UInt128, Float64}();
mapNameUUID = Dict{String, UInt128}();

function registerNeuron(name::String, desc::String, updated_ts::Real, input_names::Vector, input_types::Vector{DataType}, output_type::DataType, min_update_seconds::Real, flag_allow_cache::Bool, weight_priority::Float64, calculation::Function)::UInt128
	# check deps
	input_names = string.(input_names)
	if !(all(map(x->haskey(mapNameUUID,x),input_names)))
		throw("Incomplete upstream: " * join(filter(x->!haskey(mapNameUUID,x),input_names), ' '))
	end
	# check compatibility
	flagUpgrade = haskey(mapNameUUID,name)
	if flagUpgrade
		@assert isequal(output_type, Network[mapNameUUID[name]].Base[].OutputFormat)
		lock(ReviseLock)
	end
	# calculate level
	numLevel = 0
	if !isempty(input_names)
		numLevel = reduce(max, map(s->Network[mapNameUUID[s]].Base[].NumLevel, input_names)) + 1
	end
	# construct neuron
	n1 = NeuronBase(name, zero(UInt128), desc, updated_ts, input_names, input_types, output_type, numLevel)
	GenerateUUID!(n1)
	n2 = NeuronParams(min_update_seconds, flag_allow_cache, weight_priority)
	n3 = NeuronCache(calculation, Threads.SpinLock(), UInt128[], UInt128[], 0, Ref(nothing), 0, "", 0)
	# delete old reference
	if flagUpgrade
		prvId = mapNameUUID[name]
		tmpIds = Network[prvId].Cache[].DownstreamUUIDs
		for id in tmpIds
			replace!(Network[id].Cache[].UpstreamUUIDs, prvId => n1.UUID)
		end
		tmpIds = Network[prvId].Cache[].UpstreamUUIDs
		for id in tmpIds
			deleteat!(Network[id].Cache[].DownstreamUUIDs, findfirst(x->x==prvId, Network[id].Cache[].DownstreamUUIDs))
		end
		n3.ProcessLock = Network[prvId].Cache[].ProcessLock
		# n3.UpstreamUUIDs = Network[prvId].Cache[].UpstreamUUIDs
		n3.DownstreamUUIDs = Network[prvId].Cache[].DownstreamUUIDs
		n3.LastUpdatedTimestamp = Network[prvId].Cache[].LastUpdatedTimestamp
		n3.LastResult = Network[prvId].Cache[].LastResult
		n3.CounterCalled = Network[prvId].Cache[].CounterCalled
		delete!(Network, prvId)
		delete!(mapNameUUID, name)
	end
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
	if flagUpgrade
		unlock(ReviseLock)
	end
	return n1.UUID
	end

function RegisterNeuronSimple(f::Function, desc::String, updated_ts::Int64)::UInt128
	@assert length(methods(f)) == 1
	tmpMeta  = methods(f).ms[1]
	tmpNames = string(tmpMeta)
	tmpNames = eachmatch(r"[\(, ](.+?)::.+?[,\)]", tmpNames) |> collect
	tmpNames = map(x->string(x.captures[1]), tmpNames)
	tmpTypes = Vector{DataType}(collect(tmpMeta.sig.types[2:end]))
	output_type = Base.return_types(f)
	@assert length(output_type) == 1
	output_type = output_type[1]
	return registerNeuron( string(tmpMeta.name), desc, updated_ts, tmpNames, tmpTypes, output_type, 1.0, true, 0.0, f )
	end

function RegisterNeuronAuto(name::String, desc::String, updated_ts::Int64, input_names::Vector, calculation::Function, min_update_seconds::Real=1.0, flag_allow_cache::Bool=true, weight_priority::Real=0.0)::UInt128
	@assert length(methods(calculation)) == 1
	tmpMeta  = methods(calculation).ms[1]
	tmpTypes = Vector{DataType}(collect(tmpMeta.sig.types[2:end]))
	output_type = Base.return_types(calculation)
	@assert length(output_type) == 1
	output_type = output_type[1]
	return registerNeuron( name, desc, updated_ts, input_names, tmpTypes, output_type, min_update_seconds, flag_allow_cache, weight_priority, calculation )
	end

function SetNeuronParams(name::String, min_update_seconds::Real, flag_allow_cache::Bool, weight_priority::Real)::Nothing
	p = Network[ mapNameUUID[name] ].Params[]
	p.MinUpdateIntervalSeconds = min_update_seconds
	p.SwitchAllowCache = flag_allow_cache
	p.WeightPriority = weight_priority
	return nothing
	end











