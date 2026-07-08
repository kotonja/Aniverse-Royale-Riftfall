local TableUtil = {}

function TableUtil.shallowCopy(source)
	local copy = {}
	for key, value in pairs(source or {}) do
		copy[key] = value
	end
	return copy
end

function TableUtil.deepCopy(source)
	if type(source) ~= "table" then
		return source
	end

	local copy = {}
	for key, value in pairs(source) do
		copy[TableUtil.deepCopy(key)] = TableUtil.deepCopy(value)
	end
	return copy
end

function TableUtil.merge(base, override)
	local merged = TableUtil.shallowCopy(base)
	for key, value in pairs(override or {}) do
		merged[key] = value
	end
	return merged
end

return TableUtil
