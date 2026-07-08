local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared.Config.GameConstants)
local CharacterDefinitions = require(Shared.Config.CharacterDefinitions)
local TableUtil = require(Shared.Utility.TableUtil)

local CharacterService = {}

local TeamService = nil
local ArenaRoundService = nil
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
		tempShield = 0,
		flow = stats.flow,
		maxFlow = stats.flow,
		guard = stats.guard,
		maxGuard = stats.guard,
		ultimateCharge = 0,
		blocking = false,
		blockBrokenUntil = 0,
		sprinting = false,
		dashing = false,
		sliding = false,
		doubleJumped = false,
		defeated = false,
		lastDashAt = 0,
		lastSlideAt = 0,
		lastDoubleJumpAt = 0,
		lastWallKickAt = 0,
		sunburstGuardUntil = 0,
		slowUntil = 0,
		slowMultiplier = 1,
		damageReductionUntil = 0,
		damageReductionMultiplier = 0,
		lastStateSentAt = 0,
	}
end

local function getHumanoid(player)
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function getRoot(player)
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function applyMovementStats(player)
	local state = statesByPlayer[player]
	if not state then
		return
	end

	local humanoid = getHumanoid(player)
	if not humanoid then
		return
	end

	local definition = selectedDefinition(state)
	local stats = definition.baseStats
	local speed = state.sprinting and stats.sprintSpeed or stats.walkSpeed
	if os.clock() < (state.slowUntil or 0) then
		speed *= state.slowMultiplier or 1
	end

	humanoid.MaxHealth = state.maxHealth
	humanoid.Health = math.clamp(state.health, state.defeated and 1 or 1, state.maxHealth)
	humanoid.WalkSpeed = speed
end

local function getTeamPayload(player)
	if not TeamService then
		return {
			id = "spectator",
			name = "Spectator",
		}
	end

	local teamId = TeamService.GetPlayerTeam(player)
	local teamInfo = TeamService.GetTeamInfo(teamId)
	return {
		id = teamId,
		name = teamInfo.displayName,
	}
end

local function getArenaPayload()
	if not ArenaRoundService then
		return {
			mode = GameConstants.Match.ModeName,
			state = GameConstants.Match.SandboxState,
		}
	end

	return ArenaRoundService.GetClientState()
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
			passive = definition.passive,
			abilities = TableUtil.shallowCopy(definition.abilities),
		},
		stats = {
			health = state.health,
			maxHealth = state.maxHealth,
			shield = state.shield,
			maxShield = state.maxShield,
			tempShield = state.tempShield,
			flow = state.flow,
			maxFlow = state.maxFlow,
			guard = state.guard,
			maxGuard = state.maxGuard,
			ultimateCharge = state.ultimateCharge,
			blocking = state.blocking,
			blockBroken = os.clock() < state.blockBrokenUntil,
			defeated = state.defeated,
			slowed = os.clock() < (state.slowUntil or 0),
			damageReduction = os.clock() < (state.damageReductionUntil or 0),
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
		team = getTeamPayload(player),
		arena = getArenaPayload(),
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
	if not statesByPlayer[player] then
		statesByPlayer[player] = buildStateFromDefinition(CharacterDefinitions.DefaultId)
	end

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
		warn("[Aniverse Royale] CharacterPads folder missing. Apply the AR-002 or AR-003 blueprint.")
		return
	end

	for _, child in ipairs(padsFolder:GetChildren()) do
		bindPad(child)
	end

	padsFolder.ChildAdded:Connect(bindPad)
end

function CharacterService.Start(dependencies)
	dependencies = dependencies or {}
	TeamService = dependencies.TeamService
	ArenaRoundService = dependencies.ArenaRoundService

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

function CharacterService.SetArenaRoundService(service)
	ArenaRoundService = service
end

function CharacterService.Step(deltaTime)
	local now = os.clock()

	for player, state in pairs(statesByPlayer) do
		if state.health > 0 and not state.defeated then
			state.flow = math.min(state.maxFlow, state.flow + GameConstants.Movement.FlowRegenPerSecond * deltaTime)

			local guardRegen = GameConstants.Movement.GuardRegenPerSecond
			if state.selectedCharacterId == "atlas_null" then
				guardRegen *= 1.18
			end

			if not state.blocking and now >= state.blockBrokenUntil then
				state.guard = math.min(state.maxGuard, state.guard + guardRegen * deltaTime)
			end
		end

		if state.dashing and now - state.lastDashAt > GameConstants.Movement.DashDuration then
			state.dashing = false
		end

		if state.sliding and now - state.lastSlideAt > 0.45 then
			state.sliding = false
		end

		if state.slowUntil > 0 and now >= state.slowUntil then
			state.slowUntil = 0
			state.slowMultiplier = 1
			applyMovementStats(player)
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
	if ArenaRoundService and not ArenaRoundService.CanChangeCharacter(player) then
		CharacterService.SendState(player, {
			error = "Character locked during arena round.",
		})
		return false
	end

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

function CharacterService.ResetPlayerState(player)
	local state = statesByPlayer[player]
	local selectedCharacterId = state and state.selectedCharacterId or CharacterDefinitions.DefaultId
	statesByPlayer[player] = buildStateFromDefinition(selectedCharacterId)
	applyMovementStats(player)
	CharacterService.SendState(player)
end

function CharacterService.SetSprinting(player, isSprinting)
	local state = statesByPlayer[player]
	if not state or state.defeated then
		return
	end

	state.sprinting = isSprinting == true
	applyMovementStats(player)
	CharacterService.SendState(player)
end

function CharacterService.SetMovementState(player, patch)
	local state = statesByPlayer[player]
	if not state or state.defeated then
		return
	end

	for key, value in pairs(patch or {}) do
		state[key] = value
	end

	CharacterService.SendState(player)
end

function CharacterService.TrySpendFlow(player, amount)
	local state = statesByPlayer[player]
	if not state or state.defeated or state.flow < amount then
		return false
	end

	state.flow -= amount
	CharacterService.SendState(player)
	return true
end

function CharacterService.SetBlocking(player, isBlocking)
	local state = statesByPlayer[player]
	if not state or state.defeated then
		return false
	end

	if isBlocking and os.clock() < state.blockBrokenUntil then
		return false
	end

	state.blocking = isBlocking == true
	CharacterService.SendState(player)
	return true
end

function CharacterService.AddShield(player, amount)
	local state = statesByPlayer[player]
	if not state or state.defeated then
		return 0
	end

	local cap = state.maxShield + GameConstants.Combat.TemporaryShieldCap
	local before = state.shield
	state.shield = math.min(cap, state.shield + amount)
	state.tempShield = math.max(0, state.shield - state.maxShield)
	CharacterService.SendState(player)
	return state.shield - before
end

function CharacterService.Heal(player, amount)
	local state = statesByPlayer[player]
	if not state or state.defeated then
		return 0
	end

	local before = state.health
	state.health = math.min(state.maxHealth, state.health + amount)
	applyMovementStats(player)
	CharacterService.SendState(player)
	return state.health - before
end

function CharacterService.AddUltimateCharge(player, amount)
	local state = statesByPlayer[player]
	if not state then
		return
	end

	-- AR-003 still uses cooldown-based ultimates. This charge is saved for the AR-004+ conversion.
	state.ultimateCharge = math.clamp((state.ultimateCharge or 0) + amount, 0, 100)
	CharacterService.SendState(player)
end

function CharacterService.SetSlow(player, multiplier, duration)
	local state = statesByPlayer[player]
	if not state or state.defeated then
		return
	end

	state.slowMultiplier = math.clamp(multiplier or 1, 0.2, 1)
	state.slowUntil = math.max(state.slowUntil or 0, os.clock() + (duration or 0))
	applyMovementStats(player)
	CharacterService.SendState(player)
end

function CharacterService.SetDamageReduction(player, multiplier, duration)
	local state = statesByPlayer[player]
	if not state or state.defeated then
		return
	end

	state.damageReductionMultiplier = math.clamp(multiplier or 0, 0, 0.8)
	state.damageReductionUntil = math.max(state.damageReductionUntil or 0, os.clock() + (duration or 0))
	CharacterService.SendState(player)
end

function CharacterService.MarkDefeated(player)
	local state = statesByPlayer[player]
	if not state then
		return
	end

	state.health = 0
	state.shield = 0
	state.tempShield = 0
	state.blocking = false
	state.defeated = true

	local humanoid = getHumanoid(player)
	if humanoid then
		humanoid.Health = 1
	end

	local root = getRoot(player)
	if root then
		root.AssemblyLinearVelocity = Vector3.zero
	end

	CharacterService.SendState(player)
end

function CharacterService.IsDefeated(player)
	local state = statesByPlayer[player]
	return not state or state.defeated or state.health <= 0
end

function CharacterService.SendState(player, extra)
	local state = statesByPlayer[player]
	if not state or not remotes.StateUpdate then
		return
	end

	state.lastStateSentAt = os.clock()
	remotes.StateUpdate:FireClient(player, serializeState(player, extra))
end

function CharacterService.SendAllStates(extra)
	for _, player in ipairs(Players:GetPlayers()) do
		CharacterService.SendState(player, extra)
	end
end

return CharacterService
