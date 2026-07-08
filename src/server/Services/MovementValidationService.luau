local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared.Config.GameConstants)
local RateLimiter = require(Shared.Utility.RateLimiter)
local MathUtil = require(Shared.Utility.MathUtil)

local MovementValidationService = {}

local CharacterService = nil
local CooldownService = nil
local remotes = {}
local limiter = RateLimiter.new({
	capacity = GameConstants.Movement.RemoteRateLimitCapacity,
	refillPerSecond = GameConstants.Movement.RemoteRateLimitRefill,
})

local allowedActions = {
	[GameConstants.Actions.SprintBegin] = true,
	[GameConstants.Actions.SprintEnd] = true,
	[GameConstants.Actions.Dash] = true,
	[GameConstants.Actions.AirDash] = true,
	[GameConstants.Actions.Slide] = true,
	[GameConstants.Actions.DoubleJump] = true,
	[GameConstants.Actions.WallKick] = true,
}

local function ensureRemote(remoteName)
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end

	local remote = folder:FindFirstChild(remoteName)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = remoteName
		remote.Parent = folder
	end

	return remote
end

local function getCharacterParts(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return character, humanoid, root
end

local function feedback(player, payload)
	if remotes.CombatFeedback then
		remotes.CombatFeedback:FireClient(player, payload)
	end
end

local function deny(player, actionName, reason, remaining)
	feedback(player, {
		kind = reason,
		action = actionName,
		remaining = remaining,
	})
end

local function validatePlayer(player, actionName)
	if not allowedActions[actionName] then
		return false, "invalid"
	end

	local allowed, _, deniedCount = limiter:Allow(player.UserId)
	if not allowed then
		if deniedCount == 1 or deniedCount % 10 == 0 then
			warn(("[Aniverse Royale] Movement remote spam blocked for %s (%s)."):format(player.Name, actionName))
		end
		return false, "rateLimited"
	end

	local _, humanoid, root = getCharacterParts(player)
	if not humanoid or not root or humanoid.Health <= 0 then
		return false, "noCharacter"
	end

	local worldRoot = workspace:FindFirstChild(GameConstants.World.RootName)
	local dojo = worldRoot and worldRoot:FindFirstChild(GameConstants.World.TrainingDojoName)
	local arena = dojo and dojo:FindFirstChild(GameConstants.World.CombatArenaName)
	local arenaFloor = arena and arena:FindFirstChild("ArenaFloor")

	local arena3v3 = worldRoot and worldRoot:FindFirstChild(GameConstants.World.Arena3v3Name)
	local arena3v3Floor = arena3v3 and arena3v3:FindFirstChild("ArenaFloor")
	local tooFarFromDojo = arenaFloor and (root.Position - arenaFloor.Position).Magnitude > GameConstants.Movement.MaxRemoteDistanceFromDojo
	local tooFarFromArena = arena3v3Floor and (root.Position - arena3v3Floor.Position).Magnitude > GameConstants.Movement.MaxRemoteDistanceFromDojo
	if tooFarFromDojo and (not arena3v3Floor or tooFarFromArena) then
		return false, "tooFar"
	end

	return true, nil, humanoid, root
end

local function spendFlow(player, actionName, amount)
	if amount <= 0 then
		return true
	end

	if not CharacterService.TrySpendFlow(player, amount) then
		deny(player, actionName, "noFlow")
		return false
	end

	return true
end

local function useCooldown(player, actionName, cooldown)
	local ok, remaining = CooldownService.TryUse(player, actionName, cooldown)
	if not ok then
		deny(player, actionName, "cooldown", remaining)
		return false
	end
	return true
end

local function reserveMovement(player, actionName, cooldown, flowCost)
	local remaining = CooldownService.GetRemaining(player, actionName)
	if remaining > 0.05 then
		deny(player, actionName, "cooldown", remaining)
		return false
	end

	if not spendFlow(player, actionName, flowCost or 0) then
		return false
	end

	CooldownService.TryUse(player, actionName, cooldown)
	return true
end

local function moveDirection(humanoid, root)
	local direction = humanoid.MoveDirection
	if direction.Magnitude < 0.1 then
		direction = root.CFrame.LookVector
	end
	return MathUtil.flatUnit(direction, root.CFrame.LookVector)
end

local function handleDash(player, humanoid, root, isAirDash)
	local actionName = isAirDash and GameConstants.Actions.AirDash or GameConstants.Actions.Dash
	local cooldown = isAirDash and GameConstants.Movement.AirDashCooldown or GameConstants.Movement.DashCooldown
	local flowCost = isAirDash and GameConstants.Movement.AirDashFlowCost or GameConstants.Movement.DashFlowCost

	if isAirDash and humanoid.FloorMaterial ~= Enum.Material.Air then
		actionName = GameConstants.Actions.Dash
		cooldown = GameConstants.Movement.DashCooldown
		flowCost = GameConstants.Movement.DashFlowCost
	end

	if not reserveMovement(player, actionName, cooldown, flowCost) then
		return
	end

	local lift = isAirDash and GameConstants.Movement.AirDashLift or 4
	root.AssemblyLinearVelocity = moveDirection(humanoid, root) * GameConstants.Movement.DashSpeed + Vector3.new(0, lift, 0)
	CharacterService.SetMovementState(player, {
		dashing = true,
		lastDashAt = os.clock(),
	})
	feedback(player, {
		kind = "movement",
		action = actionName,
		position = root.Position,
	})
end

local function handleSlide(player, humanoid, root)
	if humanoid.FloorMaterial == Enum.Material.Air then
		deny(player, GameConstants.Actions.Slide, "invalid")
		return
	end
	if not reserveMovement(player, GameConstants.Actions.Slide, GameConstants.Movement.SlideCooldown, GameConstants.Movement.SlideFlowCost) then
		return
	end

	root.AssemblyLinearVelocity = moveDirection(humanoid, root) * GameConstants.Movement.SlideSpeed + Vector3.new(0, 1, 0)
	CharacterService.SetMovementState(player, {
		sliding = true,
		lastSlideAt = os.clock(),
	})
	feedback(player, {
		kind = "movement",
		action = GameConstants.Actions.Slide,
		position = root.Position,
	})
end

local function handleDoubleJump(player, humanoid, root)
	if humanoid.FloorMaterial ~= Enum.Material.Air then
		return
	end
	if not useCooldown(player, GameConstants.Actions.DoubleJump, GameConstants.Movement.DoubleJumpCooldown) then
		return
	end

	root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, GameConstants.Movement.DoubleJumpPower, root.AssemblyLinearVelocity.Z)
	CharacterService.SetMovementState(player, {
		doubleJumped = true,
		lastDoubleJumpAt = os.clock(),
	})
	feedback(player, {
		kind = "movement",
		action = GameConstants.Actions.DoubleJump,
		position = root.Position,
	})
end

local function handleWallKick(player, humanoid, root, normal)
	if humanoid.FloorMaterial ~= Enum.Material.Air then
		return
	end
	if typeof(normal) ~= "Vector3" or normal.Magnitude < 0.1 then
		normal = -root.CFrame.LookVector
	end
	if not useCooldown(player, GameConstants.Actions.WallKick, GameConstants.Movement.WallKickCooldown) then
		return
	end

	local kick = MathUtil.flatUnit(normal, -root.CFrame.LookVector)
	root.AssemblyLinearVelocity = kick * GameConstants.Movement.WallKickHorizontalPower + Vector3.new(0, GameConstants.Movement.WallKickVerticalPower, 0)
	CharacterService.SetMovementState(player, {
		lastWallKickAt = os.clock(),
	})
	feedback(player, {
		kind = "movement",
		action = GameConstants.Actions.WallKick,
		position = root.Position,
	})
end

local function handleMovement(player, actionName, payload)
	actionName = tostring(actionName or "")
	local ok, reason, humanoid, root = validatePlayer(player, actionName)
	if not ok then
		deny(player, actionName, reason)
		return
	end

	if actionName == GameConstants.Actions.SprintBegin then
		CharacterService.SetSprinting(player, true)
		feedback(player, { kind = "movement", action = actionName })
	elseif actionName == GameConstants.Actions.SprintEnd then
		CharacterService.SetSprinting(player, false)
	elseif actionName == GameConstants.Actions.Dash then
		handleDash(player, humanoid, root, false)
	elseif actionName == GameConstants.Actions.AirDash then
		handleDash(player, humanoid, root, true)
	elseif actionName == GameConstants.Actions.Slide then
		handleSlide(player, humanoid, root)
	elseif actionName == GameConstants.Actions.DoubleJump then
		handleDoubleJump(player, humanoid, root)
	elseif actionName == GameConstants.Actions.WallKick then
		local normal = type(payload) == "table" and payload.normal
		handleWallKick(player, humanoid, root, normal)
	end
end

function MovementValidationService.Start(dependencies)
	CharacterService = dependencies.CharacterService
	CooldownService = dependencies.CooldownService

	remotes.MovementAction = ensureRemote(GameConstants.Remotes.MovementAction)
	remotes.CombatFeedback = ensureRemote(GameConstants.Remotes.CombatFeedback)

	remotes.MovementAction.OnServerEvent:Connect(handleMovement)

	Players.PlayerRemoving:Connect(function(player)
		limiter:Clear(player.UserId)
	end)
end

return MovementValidationService
