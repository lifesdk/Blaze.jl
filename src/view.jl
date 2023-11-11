
struct NeuronView
	UniqueName::String
	UUID::String
	Description::String
	VersionTimestamp::Int64
	NamesFactor::String
	TypesFactor::String
	OutputFormat::String
	NumLevel::Int64
	# ---
	MinUpdateIntervalSeconds::Int64
	SwitchAllowCache::Bool
	WeightPriority::Float64
	# ---
	Calculation::String
	UpstreamUUIDs::String
	DownstreamUUIDs::String
	LastUpdatedTimestamp::Int64
	ErrorLastTs::Int64
	ErrorLastInfo::String
	CounterCalled::Int64
	end

function View(name::String)
	return Network[mapNameUUID[name]].Cache[].LastResult[]
	end
function View(UUID::UInt128)
	return Network[UUID].Cache[].LastResult[]
	end

function LastUpdated(name::String)::Int64
	return Network[mapNameUUID[name]].Cache[].LastUpdatedTimestamp
	end
function LastUpdated(UUID::UInt128)::Int64
	return Network[UUID].Cache[].LastUpdatedTimestamp
	end

function Detail(UUID::UInt128)::NeuronView
	n = Network[UUID]
	return NeuronView(
		n.Base[].UniqueName,
		string(n.Base[].UUID;base=16),
		n.Base[].Description,
		n.Base[].VersionTimestamp,
		join(n.Base[].NamesFactor, ", "),
		join(n.Base[].TypesFactor, ", "),
		string(n.Base[].OutputFormat),
		n.Base[].NumLevel,
		# ---
		n.Params[].MinUpdateIntervalSeconds,
		n.Params[].SwitchAllowCache,
		n.Params[].WeightPriority,
		# ---
		string(nameof(n.Cache[].Calculation)),
		join( map(id->string(id;base=16),n.Cache[].UpstreamUUIDs), ", "),
		join( map(id->string(id;base=16),n.Cache[].DownstreamUUIDs), ", "),
		n.Cache[].LastUpdatedTimestamp,
		n.Cache[].ErrorLastTs,
		n.Cache[].ErrorLastInfo,
		n.Cache[].CounterCalled,
	)
	end
function Detail(name::String)::NeuronView
	return Detail(mapNameUUID[name])
	end
