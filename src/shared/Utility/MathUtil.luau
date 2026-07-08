local MathUtil = {}

function MathUtil.clamp01(value)
	return math.clamp(value or 0, 0, 1)
end

function MathUtil.flatUnit(vector, fallback)
	local flat = Vector3.new(vector.X, 0, vector.Z)
	if flat.Magnitude < 0.001 then
		return fallback or Vector3.new(0, 0, -1)
	end
	return flat.Unit
end

function MathUtil.clampMagnitude(vector, maxMagnitude)
	local magnitude = vector.Magnitude
	if magnitude <= maxMagnitude then
		return vector
	end
	return vector.Unit * maxMagnitude
end

function MathUtil.ratio(value, maxValue)
	if not maxValue or maxValue <= 0 then
		return 0
	end
	return MathUtil.clamp01((value or 0) / maxValue)
end

return MathUtil
