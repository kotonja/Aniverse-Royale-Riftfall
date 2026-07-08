local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared.Config.GameConstants)
local TeamConstants = require(Shared.Config.TeamConstants)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local requestTeamChange = remotes:WaitForChild(GameConstants.Remotes.RequestTeamChange)
local requestArenaStart = remotes:WaitForChild(GameConstants.Remotes.RequestArenaStart)
local arenaStateUpdate = remotes:WaitForChild(GameConstants.Remotes.ArenaStateUpdate)

local ArenaHUDController = {}

local latestArenaState = nil
local latestAt = 0
local bound = false

local function getPanel()
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	local hud = playerGui and playerGui:FindFirstChild(GameConstants.UI.HudName)
	local root = hud and hud:FindFirstChild(GameConstants.UI.RootName)
	return root and root:FindFirstChild(GameConstants.UI.ArenaPanelName)
end

local function setText(panel, name, text)
	local label = panel and panel:FindFirstChild(name, true)
	if label and (label:IsA("TextLabel") or label:IsA("TextButton")) then
		label.Text = text
	end
end

local function bindButton(panel, name, callback)
	local button = panel and panel:FindFirstChild(name, true)
	if button and button:IsA("TextButton") then
		button.Activated:Connect(callback)
	end
end

local function countdownText()
	if not latestArenaState then
		return ""
	end

	local remaining = latestArenaState.countdown or 0
	if remaining > 0 then
		remaining = math.max(0, remaining - (os.clock() - latestAt))
		return string.format("%.1f", remaining)
	end
	return ""
end

local function render()
	local panel = getPanel()
	if not panel or not latestArenaState then
		return
	end

	local scores = latestArenaState.scores or {}
	local living = latestArenaState.living or {}
	setText(panel, "StateText", latestArenaState.state or "Idle")
	setText(panel, "CountdownText", countdownText())
	setText(panel, "RoundText", "Round " .. tostring(latestArenaState.roundNumber or 0))
	setText(panel, "ScoreText", ("Sun %d - Moon %d"):format(scores.sun or 0, scores.moon or 0))
	setText(panel, "LivingText", ("Alive Sun %d | Moon %d"):format(living.sun or 0, living.moon or 0))
	setText(panel, "WinnerText", latestArenaState.winnerName or "")
end

local function bind()
	if bound then
		return
	end

	local panel = getPanel()
	if not panel then
		return
	end

	bound = true
	bindButton(panel, "SunButton", function()
		requestTeamChange:FireServer(TeamConstants.Ids.Sun)
	end)
	bindButton(panel, "MoonButton", function()
		requestTeamChange:FireServer(TeamConstants.Ids.Moon)
	end)
	bindButton(panel, "SpectatorButton", function()
		requestTeamChange:FireServer(TeamConstants.Ids.Spectator)
	end)
	bindButton(panel, "StartButton", function()
		requestArenaStart:FireServer()
	end)
end

function ArenaHUDController.Start()
	task.spawn(function()
		local playerGui = player:WaitForChild("PlayerGui")
		playerGui:WaitForChild(GameConstants.UI.HudName, 10)
		bind()
	end)

	arenaStateUpdate.OnClientEvent:Connect(function(payload)
		latestArenaState = payload
		latestAt = os.clock()
		render()
	end)

	RunService.RenderStepped:Connect(render)
end

return ArenaHUDController
