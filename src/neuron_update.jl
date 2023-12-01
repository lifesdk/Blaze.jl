
function Commit(ids::Union{UInt128,Vector{UInt128}})::Nothing
	@assert all(map(id->haskey(Motivation,id),ids))
	put!(ReviseListChannel, ids)
	if length(ReviseListChannel.data)+1 >= ThredSizeAutoExecuteRevision
		@async ExecuteRevision()
	end
	return nothing
	end

function Revise(UUID::UInt128)::Bool
	# from top to bot
	# must only be triggered automatically
	n = Network[UUID]
	# cache check
		if n.Params[].SwitchAllowCache && time()-n.Cache[].LastUpdatedTimestamp < n.Params[].MinUpdateIntervalSeconds
			return true
		elseif haskey(Motivation,UUID) && Motivation[UUID] > round(Int,time())
			return true
		end
	# calculation
		lock(n.Cache[].ProcessLock)
		try
			n.Cache[].LastResult = n.Cache[].Calculation(
				map(x->Network[x].Cache[].LastResult[], n.Cache[].UpstreamUUIDs)...
			) |> Ref
			n.Cache[].LastUpdatedTimestamp = time()
			n.Cache[].CounterCalled += 1
		catch e
			@warn e
			@info "$(n.Base[].UniqueName) - $UUID"
			@info "UpstreamUUIDs: $(n.Cache[].UpstreamUUIDs) "
			@info "Names: " * join( map(x->Network[x].Base[].UniqueName, n.Cache[].UpstreamUUIDs), ", " )
			n.Cache[].ErrorLastTs = round(Int,time())
			n.Cache[].ErrorLastInfo = string(e)
		finally
			unlock(n.Cache[].ProcessLock)
		end
	# async append new downstream
		if iszero(n.Cache[].ErrorLastTs)
			lock(ReviseLockDelayed)
			append!(ReviseListDelayed, n.Cache[].DownstreamUUIDs)
			unlock(ReviseLockDelayed)
		end
	# update origin's timestamp
		if haskey(Motivation,UUID)
			Motivation[UUID] = n.Cache[].LastUpdatedTimestamp + n.Params[].MinUpdateIntervalSeconds
		end
	return iszero(n.Cache[].ErrorLastTs)
	end

function ExecuteRevision()::Nothing
	lock(ReviseLock)
	while length(ReviseListChannel.data) > 0
		append!(ReviseList, take!(ReviseListChannel))
	end
	if isempty(ReviseList)
		unlock(ReviseLock)
		return nothing
	end
	# pretreatment
		sort!(ReviseList, by=x->Network[x].Params[].WeightPriority, rev=true)
		unique!(ReviseList)
	# iterate
		tmpInds = zeros(Bool, length(ReviseList))
		for i in 1:length(ReviseList)
			tmpInds[i] = Revise(ReviseList[i])
		end
	# validate
		if !all(tmpInds)
			unlock(ReviseLock)
			map( UUID->Network[UUID].Cache[].ErrorLastInfo, ReviseList[findall(x->!x,tmpInds)] ) |> join |> throw
		end
	# concat
		lock(ReviseLockDelayed)
		empty!(ReviseList)
		append!(ReviseList, ReviseListDelayed)
		empty!(ReviseListDelayed)
		unlock(ReviseLockDelayed)
		unlock(ReviseLock)
	# next layer
		if !isempty(ReviseList)
			return ExecuteRevision()
		end
	return nothing
	end







































