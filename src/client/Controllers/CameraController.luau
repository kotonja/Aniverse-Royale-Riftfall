local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local CameraController = {}

local defaultFov = 70
local sprinting = false
local pulseOffset = 0
local shakeUntil = 0
local shakeIntensity = 0
local activeTween = nil

local function currentCamera()
	return Workspace.CurrentCamera
end

local function tweenFov(targetFov, duration)
	local camera = currentCamera()
	if not camera then
		return
	end

	if activeTween then
		activeTween:Cancel()
	end

	activeTween = TweenService:Create(camera, TweenInfo.new(duration or 0.16, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		FieldOfView = targetFov,
	})
	activeTween:Play()
end

local function settleFov()
	tweenFov(defaultFov + (sprinting and 4 or 0), 0.22)
end

local function shake(duration, intensity)
	shakeUntil = math.max(shakeUntil, os.clock() + duration)
	shakeIntensity = math.max(shakeIntensity, intensity)
end

local function setupCamera()
	local camera = currentCamera()
	if not camera then
		return
	end

	camera.CameraType = Enum.CameraType.Custom
	defaultFov = camera.FieldOfView
	settleFov()
end

function CameraController.Start()
	setupCamera()

	player.CharacterAdded:Connect(function()
		task.wait(0.2)
		setupCamera()
	end)

	RunService.RenderStepped:Connect(function()
		local camera = currentCamera()
		if not camera then
			return
		end

		if pulseOffset > 0 then
			pulseOffset = math.max(0, pulseOffset - 0.08)
			camera.FieldOfView = math.max(camera.FieldOfView, defaultFov + pulseOffset)
		end

		if os.clock() < shakeUntil then
			local intensity = shakeIntensity
			local offset = Vector3.new(
				(math.random() - 0.5) * intensity,
				(math.random() - 0.5) * intensity,
				0
			)
			camera.CFrame = camera.CFrame * CFrame.new(offset)
			shakeIntensity = math.max(0, shakeIntensity * 0.92)
		else
			shakeIntensity = 0
		end
	end)
end

function CameraController.PulseDash()
	pulseOffset = 5
	tweenFov(defaultFov + 7, 0.1)
	task.delay(0.12, settleFov)
	CameraController.ShakeSmall()
end

function CameraController.PulseSprint(active)
	sprinting = active == true
	settleFov()
end

function CameraController.ShakeSmall()
	shake(0.12, 0.12)
end

function CameraController.ShakeMedium()
	shake(0.2, 0.24)
end

function CameraController.HitConfirm()
	pulseOffset = 3
	CameraController.ShakeSmall()
end

function CameraController.UltimatePulse()
	pulseOffset = 10
	tweenFov(defaultFov + 11, 0.12)
	task.delay(0.2, settleFov)
	CameraController.ShakeMedium()
end

function CameraController.SoftLockPlaceholder()
	return nil
end

return CameraController
