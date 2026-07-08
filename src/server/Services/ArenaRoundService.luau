local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared.Config.GameConstants)
local ArenaConstants = require(Shared.Config.ArenaConstants)
local TeamConstants = require(Shared.Config.TeamConstants)

local ArenaRoundService = {}

local TeamService = nil
local CharacterService = nil
local CooldownService = nil
local BotService = nil
local remotes = {}
local startPadConnection = nil
local startPadDebounce = {}

local roundState = ArenaConstants.States.Idle
local roundNumber = 0
local countdownEndsAt = 0
local resetAt = 0
local winnerTeamId = nil
local scores = {
	sun = 0,
	moon = 0,
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

local function findArena()
	local worldRoot = Workspace:FindFirstChild(GameConstants.World.RootName)
	return worldRoot and worldRoot:FindFirstChild(GameConstants.World.Arena3v3Name)
end

local function findFolder(name)
	local arena = findArena()
	return arena and arena:FindFirstChild(name)
end

local function getSpawnFolder(teamId)
	if teamId == TeamConstants.Ids.Sun then
		return findFolder(ArenaConstants.World.SunSpawnPoints)
	elseif teamId == TeamConstants.Ids.Moon then
		return findFolder(ArenaConstants.World.MoonSpawnPoints)
	end
	return nil
end

local function sortedParts(folder)
	local parts = {}
	if not folder then
		return parts
	end

	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("BasePart") then
			table.insert(parts, child)
		end
	end

	table.sort(parts, function(a, b)
		return a.Name < b.Name
	end)
	return parts
end

local function teleportPlayer(player, targetPart)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and targetPart then
		root.CFrame = targetPart.CFrame + Vector3.new(0, 4, 0)
		root.AssemblyLinearVelocity = Vector3.zero
	end
end

local function teleportTeam(teamId)
	local players = TeamService.GetTeamPlayers(teamId)
	local spawns = sortedParts(getSpawnFolder(teamId))
	for index, player in ipairs(players) do
		teleportPlayer(player, spawns[((index - 1) % math.max(#spawns, 1)) + 1])
	end
end

local function teleportToSpectator(player)
	local spectator = findFolder(ArenaConstants.World.SpectatorPlatform)
	local target = spectator and (spectator:IsA("BasePart") and spectator or spectator:FindFirstChildWhichIsA("BasePart"))
	teleportPlayer(player, target)
end

local function countLivingPlayers(teamId)
	local count = 0
	for _, player in ipairs(TeamService.GetTeamPlayers(teamId)) do
		if not CharacterService.IsDefeated(player) then
			count += 1
		end
	end
	return count
end

local function countLivingCombatants(teamId)
	local count = countLivingPlayers(teamId)
	if BotService then
		count += #BotService.GetLivingBots(teamId)
	end
	return count
end

local function hasEnoughCombatants()
	return countLivingCombatants(TeamConstants.Ids.Sun) >= GameConstants.Arena.MinimumCombatantsPerTeam
		and countLivingCombatants(TeamConstants.Ids.Moon) >= GameConstants.Arena.MinimumCombatantsPerTeam
end

local function fireFeedback(player, payload)
	if remotes.CombatFeedback then
		remotes.CombatFeedback:FireClient(player, payload)
	end
end

local function broadcast()
	if remotes.ArenaStateUpdate then
		remotes.ArenaStateUpdate:FireAllClients(ArenaRoundService.GetClientState())
	end
	if CharacterService then
		CharacterService.SendAllStates()
	end
end

local function resetRoundCombatants()
	if BotService then
		BotService.ResetBots()
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if TeamConstants.isCombatTeam(TeamService.GetPlayerTeam(player)) then
			CharacterService.ResetPlayerState(player)
			if CooldownService then
				CooldownService.ResetPlayer(player)
			end
		end
	end
end

local function beginCountdown(requestingPlayer)
	if roundState ~= ArenaConstants.States.Idle and roundState ~= ArenaConstants.States.Resetting then
		fireFeedback(requestingPlayer, {
			kind = "arenaBusy",
			action = roundState,
		})
		return false
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if TeamConstants.isCombatTeam(TeamService.GetPlayerTeam(player)) then
			continue
		end
		TeamService.AutoAssignPlayer(player)
	end

	resetRoundCombatants()
	if not hasEnoughCombatants() then
		fireFeedback(requestingPlayer, {
			kind = "arenaNeedsTeams",
			action = "Need Sun and Moon combatants",
		})
		return false
	end

	roundNumber += 1
	winnerTeamId = nil
	roundState = ArenaConstants.States.Countdown
	countdownEndsAt = os.clock() + ArenaConstants.CountdownSeconds
	teleportTeam(TeamConstants.Ids.Sun)
	teleportTeam(TeamConstants.Ids.Moon)
	broadcast()
	return true
end

local function activateRound()
	roundState = ArenaConstants.States.Active
	broadcast()
end

local function endRound(teamId)
	if roundState ~= ArenaConstants.States.Active then
		return
	end

	winnerTeamId = teamId
	if scores[teamId] then
		scores[teamId] += 1
	end
	roundState = ArenaConstants.States.RoundOver
	resetAt = os.clock() + ArenaConstants.ResetSeconds
	broadcast()
end

local function resetToIdle()
	roundState = ArenaConstants.States.Resetting
	broadcast()
	task.delay(0.8, function()
		if roundState == ArenaConstants.States.Resetting then
			resetRoundCombatants()
			roundState = ArenaConstants.States.Idle
			winnerTeamId = nil
			broadcast()
		end
	end)
end

local function bindStartPad()
	local arena = findArena()
	local pad = arena and arena:FindFirstChild(ArenaConstants.World.StartRoundPad)
	if startPadConnection or not pad or not pad:IsA("BasePart") then
		if not pad then
			warn("[Aniverse Royale] Arena StartRoundPad missing. Apply the AR-003 blueprint.")
		end
		return
	end

	CollectionService:AddTag(pad, GameConstants.World.Tags.ArenaStartPad)
	startPadConnection = pad.Touched:Connect(function(hit)
		local character = hit and hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end

		local now = os.clock()
		if startPadDebounce[player] and now - startPadDebounce[player] < 1.5 then
			return
		end
		startPadDebounce[player] = now
		ArenaRoundService.RequestStart(player)
	end)
end

function ArenaRoundService.Start(dependencies)
	TeamService = dependencies.TeamService
	CharacterService = dependencies.CharacterService
	CooldownService = dependencies.CooldownService
	BotService = dependencies.BotService

	remotes.RequestArenaStart = ensureRemote(GameConstants.Remotes.RequestArenaStart)
	remotes.ArenaStateUpdate = ensureRemote(GameConstants.Remotes.ArenaStateUpdate)
	remotes.CombatFeedback = ensureRemote(GameConstants.Remotes.CombatFeedback)

	remotes.RequestArenaStart.OnServerEvent:Connect(function(player)
		ArenaRoundService.RequestStart(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		startPadDebounce[player] = nil
	end)

	task.defer(bindStartPad)
	task.defer(broadcast)
end

function ArenaRoundService.RequestStart(player)
	return beginCountdown(player)
end

function ArenaRoundService.Step()
	local now = os.clock()
	if roundState == ArenaConstants.States.Countdown and now >= countdownEndsAt then
		activateRound()
	elseif roundState == ArenaConstants.States.Active then
		local sunAlive = countLivingCombatants(TeamConstants.Ids.Sun)
		local moonAlive = countLivingCombatants(TeamConstants.Ids.Moon)
		if sunAlive <= 0 and moonAlive > 0 then
			endRound(TeamConstants.Ids.Moon)
		elseif moonAlive <= 0 and sunAlive > 0 then
			endRound(TeamConstants.Ids.Sun)
		end
	elseif roundState == ArenaConstants.States.RoundOver and now >= resetAt then
		resetToIdle()
	end
end

function ArenaRoundService.RecordPlayerDefeated(player)
	if roundState == ArenaConstants.States.Active then
		teleportToSpectator(player)
		broadcast()
	end
end

function ArenaRoundService.CanChangeCharacter()
	return roundState ~= ArenaConstants.States.Countdown and roundState ~= ArenaConstants.States.Active
end

function ArenaRoundService.CanChangeTeam()
	return roundState ~= ArenaConstants.States.Countdown and roundState ~= ArenaConstants.States.Active
end

function ArenaRoundService.IsActive()
	return roundState == ArenaConstants.States.Active
end

function ArenaRoundService.GetState()
	return roundState
end

function ArenaRoundService.GetClientState()
	local remaining = 0
	if roundState == ArenaConstants.States.Countdown then
		remaining = math.max(0, countdownEndsAt - os.clock())
	elseif roundState == ArenaConstants.States.RoundOver then
		remaining = math.max(0, resetAt - os.clock())
	end

	local winnerInfo = winnerTeamId and TeamConstants.get(winnerTeamId)
	return {
		mode = GameConstants.Match.ArenaModeName,
		state = roundState,
		roundNumber = roundNumber,
		countdown = remaining,
		winnerTeamId = winnerTeamId,
		winnerName = winnerInfo and winnerInfo.displayName or "",
		scores = {
			sun = scores.sun,
			moon = scores.moon,
		},
		living = {
			sun = countLivingCombatants(TeamConstants.Ids.Sun),
			moon = countLivingCombatants(TeamConstants.Ids.Moon),
		},
	}
end

return ArenaRoundService
