MaxSizeReviseListChannel = 64
ThredSizeAutoExecuteRevision = 60
function ModifyThredSizeAutoExecuteRevision(n::Int)
	@assert n > 1
	ThredSizeAutoExecuteRevision = n
	end
