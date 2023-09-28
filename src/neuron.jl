using MsgPack, CRC32

mutable struct NeuronBase
	UniqueName::String
	UUID::UInt128
	Description::String
	VersionTimestamp::Int64
	NamesFactor::Vector{String}
	CaseFactor::Vector{UInt8} # with types involved
	OutputFormat::DataType
	end

mutable struct NeuronParams
	MinUpdateIntervalMs::Int64
	MinMakeCacheIntervalMs::Int64
	SwitchMakeCache::Bool
	end

mutable struct NeuronCache
	Calculation::Function
	ProcessLock::Threads.SpinLock
	DownstreamUUIDs::Vector{UInt128}
	LastUpdatedTimestamp::Int64
	LastResultPacked::Vector{UInt8}
	ErrorLastTs::Int64
	ErrorLastFactorPacked::Vector{UInt8}
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
	id += CRC32.crc32( join(n.NamesFactor) * join(typeof.(unpack(n.CaseFactor))) )
	id = id << 32
	# 25-32 rand; ignore
	id += CRC32.crc32( string(nameof(n.OutputFormat)) * string(new(n.OutputFormat)) * join(n.OutputFormat.types) )
	n.UUID = id
	end
