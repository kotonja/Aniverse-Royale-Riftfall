local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared.Config.GameConstants)

local player = Players.LocalPlayer
local requestCharacterChange = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild(GameConstants.Remotes.RequestCharacterChange)

local CharacterSelectController = {}

local function getPanel()
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	local hud = playerGui and playerGui:FindFirstChild(GameConstants.UI.HudName)
	local root = hud and hud:FindFirstChild(GameConstants.UI.RootName)
	return root and (root:FindFirstChild(GameConstants.UI.CharacterPanelName) or root:FindFirstChild("CharacterSelect"))
end

local function getButton(buttonName)
	local panel = getPanel()
	return panel and panel:FindFirstChild(buttonName)
end

local function bindButton(buttonName, characterId)
	local button = getButton(buttonName)
	if button and button:IsA("TextButton") then
		button.Activated:Connect(function()
			requestCharacterChange:FireServer(characterId)
		end)
	end
end

function CharacterSelectController.Start()
	task.spawn(function()
		local playerGui = player:WaitForChild("PlayerGui")
		playerGui:WaitForChild(GameConstants.UI.HudName, 10)
		bindButton("KairoButton", "kairo_soljin")
		bindButton("MiraButton", "mira_gale")
		bindButton("KairoCard", "kairo_soljin")
		bindButton("MiraCard", "mira_gale")
	end)
end

return CharacterSelectController
