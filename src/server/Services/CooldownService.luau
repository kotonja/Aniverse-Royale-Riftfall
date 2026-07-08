local CooldownService = {}

local cooldownsByUserId = {}

local function getBucket(player)
	local userId = player.UserId
	local bucket = cooldownsByUserId[userId]
	if not bucket then
		bucket = {}
		cooldownsByUserId[userId] = bucket
	end
	return bucket
end

function CooldownService.Start()
	return true
end

function CooldownService.TryUse(player, key, duration)
	local now = os.clock()
	local bucket = getBucket(player)
	local readyAt = bucket[key] or 0

	if readyAt > now then
		return false, readyAt - now
	end

	bucket[key] = now + duration
	return true, duration
end

function CooldownService.GetRemaining(player, key)
	local bucket = getBucket(player)
	return math.max(0, (bucket[key] or 0) - os.clock())
end

function CooldownService.GetSnapshot(player)
	local now = os.clock()
	local snapshot = {}
	local bucket = getBucket(player)

	for key, readyAt in pairs(bucket) do
		snapshot[key] = math.max(0, readyAt - now)
	end

	return snapshot
end

function CooldownService.ClearPlayer(player)
	cooldownsByUserId[player.UserId] = nil
end

function CooldownService.ResetPlayer(player)
	CooldownService.ClearPlayer(player)
end

return CooldownService
