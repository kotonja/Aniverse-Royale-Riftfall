local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared.Config.GameConstants)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local combatAction = remotes:WaitForChild(GameConstants.Remotes.CombatAction)
local movementAction = remotes:WaitForChild(GameConstants.Remotes.MovementAction)

local MobileControlsController = {}

local blockToggled = false

local function getMobileButtons()
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	local hud = playerGui and playerGui:FindFirstChild(GameConstants.UI.HudName)
	local root = hud and hud:FindFirstChild(GameConstants.UI.RootName)
	return root and root:FindFirstChild(GameConstants.UI.MobileButtonsName)
end

local function isAirborne()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid and humanoid.FloorMaterial == Enum.Material.Air
end

local function bind(buttons, buttonName, callback)
	local button = buttons and buttons:FindFirstChild(buttonName)
	if button and button:IsA("TextButton") then
		button.Activated:Connect(callback)
	end
end

local function bindButtons()
	local buttons = getMobileButtons()
	if not buttons then
		return
	end

	buttons.Visible = UserInputService.TouchEnabled
	bind(buttons, "BasicButton", function()
		combatAction:FireServer(GameConstants.Actions.Basic)
	end)
	bind(buttons, "Skill1Button", function()
		combatAction:FireServer(GameConstants.Actions.Skill1)
	end)
	bind(buttons, "Skill2Button", function()
		combatAction:FireServer(GameConstants.Actions.Skill2)
	end)
	bind(buttons, "Skill3Button", function()
		combatAction:FireServer(GameConstants.Actions.Skill3)
	end)
	bind(buttons, "UltimateButton", function()
		combatAction:FireServer(GameConstants.Actions.Ultimate)
	end)
	bind(buttons, "BlockButton", function()
		blockToggled = not blockToggled
		combatAction:FireServer(blockToggled and GameConstants.Actions.BlockBegin or GameConstants.Actions.BlockEnd)
	end)
	bind(buttons, "DashButton", function()
		movementAction:FireServer(isAirborne() and GameConstants.Actions.AirDash or GameConstants.Actions.Dash)
	end)
	bind(buttons, "SlideButton", function()
		movementAction:FireServer(GameConstants.Actions.Slide)
	end)
end

function MobileControlsController.Start()
	task.spawn(function()
		local playerGui = player:WaitForChild("PlayerGui")
		playerGui:WaitForChild(GameConstants.UI.HudName, 10)
		bindButtons()
	end)
end

return MobileControlsController
