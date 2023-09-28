using MsgPack, CRC32

mutable struct NeuronBase
	UniqueName::String
	UUID::UInt128
	Description::String
	VersionTimestamp::Int64
	NamesFactor::Vector{String}
	TypesFactor::Vector{String} # string.(nameof.(typeof.(input_params)))
	OutputFormat::DataType
	end

mutable struct NeuronParams
	MinUpdateIntervalSeconds::Int64
	MinMakeCacheIntervalSeconds::Int64
	SwitchMakeCache::Bool
	SwitchAutoTrigger::Bool
	WeightPriority::Float64
	end

mutable struct NeuronCache
	Calculation::Function
	ProcessLock::Threads.SpinLock
	UpsteamsChanged::Bool
	DownstreamUUIDs::Vector{UInt128}
	LastUpdatedTimestamp::Int64
	LastResultPacked::Vector{UInt8}
	ErrorLastTs::Int64
	ErrorLastInfo::String
	end

function GenerateUUID!(n::NeuronBase)::UInt128
	id = UInt128(0)
	# 1-8 timestamp
	id += UInt32(n.VersionTimestamp)
	id = id << 32
	# 9-16 ip; Sockets.getipaddr().host; ignore
	id += CRC32.crc32( n.UniqueName )
	id = id << 32
	# 17-24 hashcode
	id += CRC32.crc32( join(n.NamesFactor) * join(typeof.(unpack(n.TypesFactor))) )
	id = id << 32
	# 25-32 rand; ignore
	id += CRC32.crc32( string(nameof(n.OutputFormat)) * string(new(n.OutputFormat)) * join(n.OutputFormat.types) )
	n.UUID = id
	end
