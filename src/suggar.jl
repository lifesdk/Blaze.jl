
emptyInitials = Dict{Any, Any}(
	String => "",
	Threads.SpinLock => Threads.SpinLock(),
	DataType => UInt8,
	Bool => false,
	Function => x->x,
	Base.RefValue => Ref(nothing),
	);

function new(data_type::T) where T <: DataType
	data_type( map( t ->
		haskey(emptyInitials,t) ? deepcopy(emptyInitials[t]) :
			( t <: Vector ? t() : zero(t) ),
	data_type.types)... )
	end






