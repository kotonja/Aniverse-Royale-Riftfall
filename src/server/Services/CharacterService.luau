local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared.Config.GameConstants)
local CharacterDefinitions = require(Shared.Config.CharacterDefinitions)
local TableUtil = require(Shared.Utility.TableUtil)

local CharacterService = {}

local statesByPlayer = {}
local remotes = {}
local padConnections = {}
local padDebounce = {}

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

local function selectedDefinition(state)
	return CharacterDefinitions.get(state.selectedCharacterId) or CharacterDefinitions.get(CharacterDefinitions.DefaultId)
end

local function buildStateFromDefinition(characterId)
	local definition = CharacterDefinitions.get(characterId) or CharacterDefinitions.get(CharacterDefinitions.DefaultId)
	local stats = definition.baseStats

	return {
		selectedCharacterId = definition.id,
		health = stats.health,
		maxHealth = stats.health,
		shield = stats.shield,
		maxShield = stats.shield,
		flow = stats.flow,
		maxFlow = stats.flow,
		guard = stats.guard,
		maxGuard = stats.guard,
		blocking = false,
		blockBrokenUntil = 0,
		sprinting = false,
		dashing = false,
		sliding = false,
		doubleJumped = false,
		lastDashAt = 0,
		lastSlideAt = 0,
		lastDoubleJumpAt = 0,
		lastWallKickAt = 0,
		sunburstGuardUntil = 0,
		lastStateSentAt = 0,
	}
end

local function applyMovementStats(player)
	local state = statesByPlayer[player]
	if not state then
		return
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local definition = selectedDefinition(state)
	local stats = definition.baseStats
	humanoid.MaxHealth = state.maxHealth
	humanoid.Health = math.clamp(state.health, 1, state.maxHealth)
	humanoid.WalkSpeed = state.sprinting and stats.sprintSpeed or stats.walkSpeed
end

local function serializeState(player, extra)
	local state = statesByPlayer[player]
	if not state then
		return nil
	end

	local definition = selectedDefinition(state)
	local payload = {
		character = {
			id = definition.id,
			displayName = definition.displayName,
			subtitle = definition.subtitle,
			role = definition.role,
			aura = definition.aura,
			abilities = TableUtil.shallowCopy(definition.abilities),
		},
		stats = {
			health = state.health,
			maxHealth = state.maxHealth,
			shield = state.shield,
			maxShield = state.maxShield,
			flow = state.flow,
			maxFlow = state.maxFlow,
			guard = state.guard,
			maxGuard = state.maxGuard,
			blocking = state.blocking,
			blockBroken = os.clock() < state.blockBrokenUntil,
		},
		movement = {
			sprinting = state.sprinting,
			dashing = state.dashing,
			sliding = state.sliding,
			doubleJumped = state.doubleJumped,
			lastDashAt = state.lastDashAt,
			lastSlideAt = state.lastSlideAt,
			lastDoubleJumpAt = state.lastDoubleJumpAt,
			lastWallKickAt = state.lastWallKickAt,
		},
		match = {
			mode = GameConstants.Match.ModeName,
			state = GameConstants.Match.SandboxState,
			teamSizeTarget = GameConstants.Match.TeamSizeTarget,
			futureTargetPlayers = GameConstants.Match.FutureTargetPlayers,
		},
	}

	if extra then
		for key, value in pairs(extra) do
			payload[key] = value
		end
	end

	return payload
end

local function fireFeedback(player, payload)
	if remotes.CombatFeedback then
		remotes.CombatFeedback:FireClient(player, payload)
	end
end

local function onCharacterAdded(player)
	task.defer(function()
		applyMovementStats(player)
		CharacterService.SendState(player)
	end)
end

local function onPlayerAdded(player)
	statesByPlayer[player] = buildStateFromDefinition(CharacterDefinitions.DefaultId)

	player.CharacterAdded:Connect(function()
		onCharacterAdded(player)
	end)

	if player.Character then
		onCharacterAdded(player)
	end

	CharacterService.SendState(player)
end

local function onPlayerRemoving(player)
	statesByPlayer[player] = nil
	padDebounce[player] = nil
end

local function findCharacterPads()
	local worldRoot = Workspace:FindFirstChild(GameConstants.World.RootName)
	local dojo = worldRoot and worldRoot:FindFirstChild(GameConstants.World.TrainingDojoName)
	return dojo and dojo:FindFirstChild(GameConstants.World.CharacterPadFolderName)
end

local function bindPad(pad)
	if padConnections[pad] or not pad:IsA("BasePart") then
		return
	end

	CollectionService:AddTag(pad, GameConstants.World.Tags.CharacterPad)
	padConnections[pad] = pad.Touched:Connect(function(hit)
		local character = hit and hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end

		local now = os.clock()
		local key = tostring(player.UserId) .. ":" .. pad:GetFullName()
		if padDebounce[key] and now - padDebounce[key] < 1 then
			return
		end
		padDebounce[key] = now

		local characterId = tostring(pad:GetAttribute("CharacterId") or "")
		if CharacterService.SetSelectedCharacter(player, characterId) then
			local definition = CharacterDefinitions.get(characterId)
			fireFeedback(player, {
				kind = "selected",
				action = definition and definition.displayName or characterId,
			})
		end
	end)
end

local function bindCharacterPads()
	local padsFolder = findCharacterPads()
	if not padsFolder then
		warn("[Aniverse Royale] CharacterPads folder missing. Apply the AR-002 blueprint for real selection pads.")
		return
	end

	for _, child in ipairs(padsFolder:GetChildren()) do
		bindPad(child)
	end

	padsFolder.ChildAdded:Connect(bindPad)
end

function CharacterService.Start()
	remotes.RequestCharacterChange = ensureRemote(GameConstants.Remotes.RequestCharacterChange)
	remotes.StateUpdate = ensureRemote(GameConstants.Remotes.StateUpdate)
	remotes.CombatFeedback = ensureRemote(GameConstants.Remotes.CombatFeedback)

	remotes.RequestCharacterChange.OnServerEvent:Connect(function(player, requestedCharacterId)
		if CharacterService.SetSelectedCharacter(player, tostring(requestedCharacterId or "")) then
			local definition = CharacterService.GetDefinition(player)
			fireFeedback(player, {
				kind = "selected",
				action = definition and definition.displayName or "Riftborn",
			})
		end
	end)

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end

	task.defer(bindCharacterPads)
end

function CharacterService.Step(deltaTime)
	local now = os.clock()

	for player, state in pairs(statesByPlayer) do
		if state.health > 0 then
			state.flow = math.min(state.maxFlow, state.flow + GameConstants.Movement.FlowRegenPerSecond * deltaTime)

			if not state.blocking and now >= state.blockBrokenUntil then
				state.guard = math.min(state.maxGuard, state.guard + GameConstants.Movement.GuardRegenPerSecond * deltaTime)
			end
		end

		if state.dashing and now - state.lastDashAt > GameConstants.Movement.DashDuration then
			state.dashing = false
		end

		if state.sliding and now - state.lastSlideAt > 0.45 then
			state.sliding = false
		end

		if now - state.lastStateSentAt >= 0.2 then
			CharacterService.SendState(player)
		end
	end
end

function CharacterService.GetState(player)
	return statesByPlayer[player]
end

function CharacterService.GetDefinition(player)
	local state = statesByPlayer[player]
	if not state then
		return nil
	end
	return selectedDefinition(state)
end

function CharacterService.SetSelectedCharacter(player, characterId)
	if not CharacterDefinitions.exists(characterId) then
		CharacterService.SendState(player, {
			error = "Unknown Riftborn.",
		})
		return false
	end

	statesByPlayer[player] = buildStateFromDefinition(characterId)
	applyMovementStats(player)
	CharacterService.SendState(player)
	return true
end

function CharacterService.SetSprinting(player, isSprinting)
	local state = statesByPlayer[player]
	if not state then
		return
	end

	state.sprinting = isSprinting == true
	applyMovementStats(player)
	CharacterService.SendState(player)
end

function CharacterService.SetMovementState(player, patch)
	local state = statesByPlayer[player]
	if not state then
		return
	end

	for key, value in pairs(patch or {}) do
		state[key] = value
	end

	CharacterService.SendState(player)
end

function CharacterService.TrySpendFlow(player, amount)
	local state = statesByPlayer[player]
	if not state or state.flow < amount then
		return false
	end

	state.flow -= amount
	CharacterService.SendState(player)
	return true
end

function CharacterService.SetBlocking(player, isBlocking)
	local state = statesByPlayer[player]
	if not state then
		return false
	end

	if isBlocking and os.clock() < state.blockBrokenUntil then
		return false
	end

	state.blocking = isBlocking == true
	CharacterService.SendState(player)
	return true
end

function CharacterService.SendState(player, extra)
	local state = statesByPlayer[player]
	if not state or not remotes.StateUpdate then
		return
	end

	state.lastStateSentAt = os.clock()
	remotes.StateUpdate:FireClient(player, serializeState(player, extra))
end

return CharacterService
