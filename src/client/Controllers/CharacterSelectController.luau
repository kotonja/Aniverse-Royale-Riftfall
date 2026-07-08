local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared.Config.GameConstants)

local player = Players.LocalPlayer
local requestCharacterChange = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild(GameConstants.Remotes.RequestCharacterChange)

local CharacterSelectController = {}

local function getButton(buttonName)
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	local hud = playerGui and playerGui:FindFirstChild("AniverseHUD")
	local root = hud and hud:FindFirstChild("Root")
	local panel = root and root:FindFirstChild("CharacterSelect")
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
		playerGui:WaitForChild("AniverseHUD", 10)
		bindButton("KairoButton", "kairo_soljin")
		bindButton("MiraButton", "mira_gale")
	end)
end

return CharacterSelectController
