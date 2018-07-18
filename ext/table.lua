
--- Removes a value from a table as opposed to an index.
-- t = Table to be modified.
--value = Value to be removed.
-- return true on successful removal false otherwise.
function table.removeValue(t, value)
	for i,v in pairs(t) do
		if v == value then
			table.remove(t, i)
			return true
		end
	end
	return false
end

function table.copy(t)
	local copy = {}
	for i,v in ipairs(t) do
		copy[i] = v
	end
	return copy
end