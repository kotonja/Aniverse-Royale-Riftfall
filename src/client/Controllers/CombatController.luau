local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared.Config.GameConstants)
local InputBindings = require(Shared.Config.InputBindings)

local player = Players.LocalPlayer
local combatAction = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild(GameConstants.Remotes.CombatAction)

local CombatController = {}

local blockHeld = false

local function send(actionName)
	combatAction:FireServer(actionName)
end

local function getRoot()
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	local hud = playerGui and playerGui:FindFirstChild(GameConstants.UI.HudName)
	return hud and hud:FindFirstChild(GameConstants.UI.RootName)
end

local function findHotbarButton(buttonName)
	local root = getRoot()
	if not root then
		return nil
	end

	local hotbar = root:FindFirstChild(GameConstants.UI.AbilityHotbarName) or root:FindFirstChild("Abilities")
	return hotbar and hotbar:FindFirstChild(buttonName)
end

local function bindButton(buttonName, actionName)
	local button = findHotbarButton(buttonName)
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
		elseif input.KeyCode == InputBindings.Keyboard.Skill1 then
			send(GameConstants.Actions.Skill1)
		elseif input.KeyCode == InputBindings.Keyboard.Skill2 then
			send(GameConstants.Actions.Skill2)
		elseif input.KeyCode == InputBindings.Keyboard.Skill3 then
			send(GameConstants.Actions.Skill3)
		elseif input.KeyCode == InputBindings.Keyboard.Ultimate then
			send(GameConstants.Actions.Ultimate)
		elseif input.KeyCode == InputBindings.Keyboard.Block then
			blockHeld = true
			send(GameConstants.Actions.BlockBegin)
		end
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == InputBindings.Keyboard.Block and blockHeld then
			blockHeld = false
			send(GameConstants.Actions.BlockEnd)
		end
	end)

	task.spawn(function()
		local playerGui = player:WaitForChild("PlayerGui")
		playerGui:WaitForChild(GameConstants.UI.HudName, 10)
		bindUiButtons()
	end)
end

return CombatController
