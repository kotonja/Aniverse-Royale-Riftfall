local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared.Config.GameConstants)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local teamStateUpdate = remotes:WaitForChild(GameConstants.Remotes.TeamStateUpdate)
local botStateUpdate = remotes:WaitForChild(GameConstants.Remotes.BotStateUpdate)
local stateUpdate = remotes:WaitForChild(GameConstants.Remotes.StateUpdate)

local TeamPanelController = {}

local latestTeams = nil
local latestBots = nil
local latestPlayerState = nil

local function getPanel()
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	local hud = playerGui and playerGui:FindFirstChild(GameConstants.UI.HudName)
	local root = hud and hud:FindFirstChild(GameConstants.UI.RootName)
	return root and root:FindFirstChild(GameConstants.UI.TeamPanelName)
end

local function setText(panel, name, text)
	local label = panel and panel:FindFirstChild(name, true)
	if label and (label:IsA("TextLabel") or label:IsA("TextButton")) then
		label.Text = text
	end
end

local function teamLine(team)
	if not team then
		return "No players"
	end

	local lines = {}
	for _, item in ipairs(team.players or {}) do
		table.insert(lines, item.displayName or item.name)
	end

	if #lines == 0 then
		table.insert(lines, "No players")
	end

	return table.concat(lines, "\n")
end

local function botLine(teamId)
	if not latestBots or not latestBots.teams or not latestBots.teams[teamId] then
		return "Bots: none"
	end

	local lines = {}
	for _, bot in ipairs(latestBots.teams[teamId]) do
		local state = bot.alive and "alive" or "defeated"
		table.insert(lines, ("%s %d/%d %s"):format(bot.name, math.floor(bot.health), math.floor(bot.maxHealth), state))
	end

	if #lines == 0 then
		table.insert(lines, "Bots: none")
	end

	return table.concat(lines, "\n")
end

local function render()
	local panel = getPanel()
	if not panel then
		return
	end

	local teams = latestTeams and latestTeams.teams or {}
	local currentTeam = latestPlayerState and latestPlayerState.team
	setText(panel, "CurrentTeamText", currentTeam and currentTeam.name or "Spectator")
	setText(panel, "SunList", teamLine(teams.sun) .. "\n" .. botLine("sun"))
	setText(panel, "MoonList", teamLine(teams.moon) .. "\n" .. botLine("moon"))
end

function TeamPanelController.Start()
	teamStateUpdate.OnClientEvent:Connect(function(payload)
		latestTeams = payload
		render()
	end)

	botStateUpdate.OnClientEvent:Connect(function(payload)
		latestBots = payload
		render()
	end)

	stateUpdate.OnClientEvent:Connect(function(payload)
		latestPlayerState = payload
		render()
	end)
end

return TeamPanelController
