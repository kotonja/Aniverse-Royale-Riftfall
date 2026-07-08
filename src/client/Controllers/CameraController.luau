local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared.Config.GameConstants)

local player = Players.LocalPlayer
local movementAction = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild(GameConstants.Remotes.MovementAction)

local CameraController = {}

local defaultFov = 70

function CameraController.Start()
	local camera = Workspace.CurrentCamera
	if camera then
		defaultFov = camera.FieldOfView
	end

	movementAction.OnClientEvent:Connect(function()
		return true
	end)

	player.CharacterAdded:Connect(function()
		task.wait(0.2)
		local currentCamera = Workspace.CurrentCamera
		if currentCamera then
			currentCamera.FieldOfView = defaultFov
		end
	end)
end

function CameraController.PulseDash()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end

	local tween = TweenService:Create(camera, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		FieldOfView = defaultFov + 5,
	})
	tween:Play()
	tween.Completed:Once(function()
		TweenService:Create(camera, TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			FieldOfView = defaultFov,
		}):Play()
	end)
end

return CameraController
