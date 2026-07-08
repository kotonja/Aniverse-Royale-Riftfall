local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared.Config.GameConstants)
local TeamConstants = require(Shared.Config.TeamConstants)

local TeamService = {}

local playerTeams = {}
local remotes = {}
local padConnections = {}
local padDebounce = {}
local ArenaRoundService = nil

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

local function teamInfo(teamId)
	return TeamConstants.get(teamId) or TeamConstants.Teams.spectator
end

local function fireFeedback(player, payload)
	if remotes.CombatFeedback then
		remotes.CombatFeedback:FireClient(player, payload)
	end
end

local function countTeam(teamId)
	local count = 0
	for _, assignedTeamId in pairs(playerTeams) do
		if assignedTeamId == teamId then
			count += 1
		end
	end
	return count
end

local function applyPlayerAttributes(player, teamId)
	local info = teamInfo(teamId)
	player:SetAttribute("AR_TeamId", info.id)
	player:SetAttribute("AR_TeamName", info.displayName)
end

local function buildTeamPayload()
	local payload = {
		teamSizeTarget = TeamConstants.TeamSizeTarget,
		teams = {},
	}

	for _, info in ipairs(TeamConstants.listCombatTeams()) do
		local players = {}
		for player, teamId in pairs(playerTeams) do
			if player.Parent and teamId == info.id then
				table.insert(players, {
					userId = player.UserId,
					name = player.Name,
					displayName = player.DisplayName,
					teamId = teamId,
				})
			end
		end

		payload.teams[info.id] = {
			id = info.id,
			displayName = info.displayName,
			shortName = info.shortName,
			count = #players,
			players = players,
		}
	end

	payload.teams.spectator = {
		id = "spectator",
		displayName = "Spectator",
		shortName = "Spec",
		count = countTeam("spectator"),
		players = {},
	}

	return payload
end

local function findArena()
	local worldRoot = Workspace:FindFirstChild(GameConstants.World.RootName)
	return worldRoot and worldRoot:FindFirstChild(GameConstants.World.Arena3v3Name)
end

local function bindTeamPad(pad)
	if padConnections[pad] or not pad:IsA("BasePart") then
		return
	end

	CollectionService:AddTag(pad, GameConstants.World.Tags.TeamPad)
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

		TeamService.SetPlayerTeam(player, tostring(pad:GetAttribute("TeamId") or ""))
	end)
end

local function bindTeamPads()
	local arena = findArena()
	local folder = arena and arena:FindFirstChild("TeamPads")
	if not folder then
		warn("[Aniverse Royale] Arena TeamPads missing. Apply the AR-003 blueprint.")
		return
	end

	for _, child in ipairs(folder:GetChildren()) do
		bindTeamPad(child)
	end

	folder.ChildAdded:Connect(bindTeamPad)
end

function TeamService.Start()
	remotes.RequestTeamChange = ensureRemote(GameConstants.Remotes.RequestTeamChange)
	remotes.TeamStateUpdate = ensureRemote(GameConstants.Remotes.TeamStateUpdate)
	remotes.CombatFeedback = ensureRemote(GameConstants.Remotes.CombatFeedback)

	remotes.RequestTeamChange.OnServerEvent:Connect(function(player, requestedTeamId)
		TeamService.SetPlayerTeam(player, tostring(requestedTeamId or ""))
	end)

	Players.PlayerAdded:Connect(function(player)
		TeamService.SetPlayerTeam(player, TeamConstants.Ids.Spectator, true)
	end)

	Players.PlayerRemoving:Connect(function(player)
		playerTeams[player] = nil
		padDebounce[player] = nil
		TeamService.Broadcast()
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		TeamService.SetPlayerTeam(player, TeamConstants.Ids.Spectator, true)
	end

	task.defer(bindTeamPads)
end

function TeamService.SetArenaRoundService(service)
	ArenaRoundService = service
end

function TeamService.GetTeamInfo(teamId)
	return teamInfo(teamId)
end

function TeamService.GetPlayerTeam(player)
	return playerTeams[player] or player:GetAttribute("AR_TeamId") or TeamConstants.Ids.Spectator
end

function TeamService.SetPlayerTeam(player, teamId, silent)
	if not TeamConstants.isValid(teamId) then
		teamId = TeamConstants.Ids.Spectator
	end

	if ArenaRoundService and not ArenaRoundService.CanChangeTeam(player) then
		fireFeedback(player, {
			kind = "teamLocked",
			action = "Arena active",
		})
		return false
	end

	playerTeams[player] = teamId
	applyPlayerAttributes(player, teamId)

	if not silent then
		fireFeedback(player, {
			kind = "teamSelected",
			action = teamInfo(teamId).displayName,
		})
	end

	TeamService.Broadcast()
	return true
end

function TeamService.AutoAssignPlayer(player)
	local currentTeamId = TeamService.GetPlayerTeam(player)
	if TeamConstants.isCombatTeam(currentTeamId) then
		return currentTeamId
	end

	local sunCount = countTeam(TeamConstants.Ids.Sun)
	local moonCount = countTeam(TeamConstants.Ids.Moon)
	local teamId = sunCount <= moonCount and TeamConstants.Ids.Sun or TeamConstants.Ids.Moon
	TeamService.SetPlayerTeam(player, teamId, true)
	return teamId
end

function TeamService.GetTeamPlayers(teamId)
	local players = {}
	for player, assignedTeamId in pairs(playerTeams) do
		if player.Parent and assignedTeamId == teamId then
			table.insert(players, player)
		end
	end
	return players
end

function TeamService.AreAllies(playerA, playerB)
	local teamA = TeamService.GetPlayerTeam(playerA)
	local teamB = TeamService.GetPlayerTeam(playerB)
	return TeamConstants.isCombatTeam(teamA) and teamA == teamB
end

function TeamService.AreEnemies(playerA, playerB)
	local teamA = TeamService.GetPlayerTeam(playerA)
	local teamB = TeamService.GetPlayerTeam(playerB)
	return TeamConstants.isCombatTeam(teamA) and TeamConstants.isCombatTeam(teamB) and teamA ~= teamB
end

function TeamService.AreTeamIdsEnemies(teamA, teamB)
	return TeamConstants.isCombatTeam(teamA) and TeamConstants.isCombatTeam(teamB) and teamA ~= teamB
end

function TeamService.ClearTeams()
	for _, player in ipairs(Players:GetPlayers()) do
		TeamService.SetPlayerTeam(player, TeamConstants.Ids.Spectator, true)
	end
	TeamService.Broadcast()
end

function TeamService.Broadcast()
	if remotes.TeamStateUpdate then
		remotes.TeamStateUpdate:FireAllClients(buildTeamPayload())
	end
end

return TeamService
