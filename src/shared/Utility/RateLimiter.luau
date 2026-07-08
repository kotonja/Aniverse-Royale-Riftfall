local RateLimiter = {}
RateLimiter.__index = RateLimiter

function RateLimiter.new(options)
	options = options or {}

	return setmetatable({
		_capacity = options.capacity or 12,
		_refillPerSecond = options.refillPerSecond or 6,
		_buckets = {},
	}, RateLimiter)
end

function RateLimiter:_bucket(key)
	local now = os.clock()
	local bucket = self._buckets[key]

	if not bucket then
		bucket = {
			tokens = self._capacity,
			updatedAt = now,
			denied = 0,
		}
		self._buckets[key] = bucket
		return bucket
	end

	local elapsed = math.max(0, now - bucket.updatedAt)
	bucket.updatedAt = now
	bucket.tokens = math.min(self._capacity, bucket.tokens + elapsed * self._refillPerSecond)
	return bucket
end

function RateLimiter:Allow(key, cost)
	cost = cost or 1

	local bucket = self:_bucket(key)
	if bucket.tokens >= cost then
		bucket.tokens -= cost
		return true, bucket.tokens, bucket.denied
	end

	bucket.denied += 1
	return false, bucket.tokens, bucket.denied
end

function RateLimiter:Clear(key)
	self._buckets[key] = nil
end

return RateLimiter
