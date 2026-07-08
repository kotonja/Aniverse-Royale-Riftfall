local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared.Config.GameConstants)

local player = Players.LocalPlayer
local combatAction = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild(GameConstants.Remotes.CombatAction)

local CombatController = {}

local blockHeld = false

local function send(actionName)
	combatAction:FireServer(actionName)
end

local function getRoot()
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	local hud = playerGui and playerGui:FindFirstChild("AniverseHUD")
	return hud and hud:FindFirstChild("Root")
end

local function findButton(buttonName)
	local root = getRoot()
	if not root then
		return nil
	end

	local abilities = root:FindFirstChild("Abilities")
	local mobile = root:FindFirstChild("MobileButtons")
	return (abilities and abilities:FindFirstChild(buttonName)) or (mobile and mobile:FindFirstChild(buttonName))
end

local function bindButton(buttonName, actionName)
	local button = findButton(buttonName)
	if button and button:IsA("TextButton") then
		button.Activated:Connect(function()
			if actionName == GameConstants.Actions.BlockBegin then
				blockHeld = not blockHeld
				send(blockHeld and GameConstants.Actions.BlockBegin or GameConstants.Actions.BlockEnd)
			else
				send(actionName)
			end
		end)
	end
end

local function bindUiButtons()
	bindButton("BasicButton", GameConstants.Actions.Basic)
	bindButton("Skill1Button", GameConstants.Actions.Skill1)
	bindButton("Skill2Button", GameConstants.Actions.Skill2)
	bindButton("Skill3Button", GameConstants.Actions.Skill3)
	bindButton("UltimateButton", GameConstants.Actions.Ultimate)
	bindButton("BlockButton", GameConstants.Actions.BlockBegin)
end

function CombatController.Start()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			send(GameConstants.Actions.Basic)
		elseif input.KeyCode == Enum.KeyCode.Q then
			send(GameConstants.Actions.Skill1)
		elseif input.KeyCode == Enum.KeyCode.E then
			send(GameConstants.Actions.Skill2)
		elseif input.KeyCode == Enum.KeyCode.R then
			send(GameConstants.Actions.Skill3)
		elseif input.KeyCode == Enum.KeyCode.X then
			send(GameConstants.Actions.Ultimate)
		elseif input.KeyCode == Enum.KeyCode.F then
			blockHeld = true
			send(GameConstants.Actions.BlockBegin)
		end
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.F and blockHeld then
			blockHeld = false
			send(GameConstants.Actions.BlockEnd)
		end
	end)

	task.spawn(function()
		local playerGui = player:WaitForChild("PlayerGui")
		playerGui:WaitForChild("AniverseHUD", 10)
		bindUiButtons()
	end)
end

return CombatController
