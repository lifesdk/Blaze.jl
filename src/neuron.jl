using MsgPack, CRC32

ReviseLock = Threads.SpinLock();
ReviseList = UInt128[];
ReviseLockDelayed = Threads.SpinLock();
ReviseListDelayed = UInt128[];
ReviseListChannel = Channel(MaxSizeReviseListChannel);

mutable struct NeuronBase
	UniqueName::String
	UUID::UInt128
	Description::String
	VersionTimestamp::Int64
	NamesFactor::Vector{String}
	TypesFactor::Vector{DataType} # of types
	OutputFormat::DataType
	NumLevel::Int64
	end

mutable struct NeuronParams
	MinUpdateIntervalSeconds::Int64
	SwitchAllowCache::Bool
	WeightPriority::Float64
	end

mutable struct NeuronCache
	Calculation::Function
	ProcessLock::Threads.SpinLock
	UpstreamUUIDs::Vector{UInt128}
	DownstreamUUIDs::Vector{UInt128}
	LastUpdatedTimestamp::Int64
	LastResult::Base.RefValue
	ErrorLastTs::Int64
	ErrorLastInfo::String
	CounterCalled::Int64
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
	id += CRC32.crc32( join(n.NamesFactor) * join(n.TypesFactor) )
	id = id << 32
	# 25-32 rand; ignore
	id += CRC32.crc32( string(nameof(n.OutputFormat)) * join(n.OutputFormat.types) )
	n.UUID = id
	end
