local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared.Config.GameConstants)
local UIConstants = require(Shared.Config.UIConstants)

local CameraController = require(script.Parent.CameraController)

local player = Players.LocalPlayer
local combatFeedback = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild(GameConstants.Remotes.CombatFeedback)

local FeedbackController = {}

local function getRootPart()
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function getFeedbackLayer()
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	local hud = playerGui and playerGui:FindFirstChild(GameConstants.UI.HudName)
	local root = hud and hud:FindFirstChild(GameConstants.UI.RootName)
	return root and root:FindFirstChild(GameConstants.UI.FeedbackLayerName)
end

local function colorForPayload(payload)
	local action = tostring(payload.action or "")
	if string.find(action, "Wind") or string.find(action, "Gale") or string.find(action, "Tempest") then
		return UIConstants.Colors.Mira
	end
	if string.find(action, "Flame") or string.find(action, "Ember") or string.find(action, "Dawn") or string.find(action, "Meteor") then
		return UIConstants.Colors.Kairo
	end
	if payload.kind == "noFlow" then
		return UIConstants.Colors.NoFlow
	end
	return UIConstants.Colors.Cooldown
end

local function spawnDamageNumber(payload)
	local layer = getFeedbackLayer()
	if not layer then
		return
	end

	local label = Instance.new("TextLabel")
	label.Name = "FloatingDamage"
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = colorForPayload(payload)
	label.TextStrokeTransparency = 0.25
	label.Text = tostring(math.floor(payload.amount or 0))
	label.Size = UDim2.fromScale(0.08, 0.045)
	label.Position = UDim2.fromScale(0.5 + (math.random() - 0.5) * 0.08, 0.45 + (math.random() - 0.5) * 0.06)
	label.Parent = layer

	local targetPosition = UDim2.fromScale(label.Position.X.Scale, label.Position.Y.Scale - 0.08)
	TweenService:Create(label, TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = targetPosition,
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()
	Debris:AddItem(label, 0.75)
end

local function pulseHitMarker()
	local layer = getFeedbackLayer()
	local marker = layer and layer:FindFirstChild("HitMarker")
	if not marker or not marker:IsA("GuiObject") then
		return
	end

	marker.Visible = true
	marker.Size = UDim2.fromScale(0.035, 0.035)
	if marker:IsA("Frame") then
		marker.BackgroundTransparency = 0.1
	end

	local tween = TweenService:Create(marker, TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(0.052, 0.052),
	})
	tween:Play()
	task.delay(0.2, function()
		if marker.Parent then
			marker.Visible = false
		end
	end)
end

local function spawnWorldPulse(position, color, size, duration)
	local part = Instance.new("Part")
	part.Name = "AR002ClientPulse"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Shape = Enum.PartType.Ball
	part.Material = Enum.Material.Neon
	part.Transparency = 0.35
	part.Size = Vector3.new(1, 1, 1)
	part.Color = color
	part.Position = position
	part.Parent = Workspace

	TweenService:Create(part, TweenInfo.new(duration or 0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(size, size, size),
		Transparency = 1,
	}):Play()
	Debris:AddItem(part, (duration or 0.28) + 0.08)
end

local function spawnGuardShield()
	local root = getRootPart()
	if not root then
		return
	end

	local shield = Instance.new("Part")
	shield.Name = "AR002GuardShield"
	shield.Anchored = false
	shield.CanCollide = false
	shield.CanQuery = false
	shield.Shape = Enum.PartType.Ball
	shield.Material = Enum.Material.ForceField
	shield.Transparency = 0.45
	shield.Size = Vector3.new(7, 7, 7)
	shield.Color = UIConstants.Colors.Guard
	shield.CFrame = root.CFrame
	shield.Parent = Workspace

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = shield
	weld.Parent = shield

	TweenService:Create(shield, TweenInfo.new(0.28, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Transparency = 1,
		Size = Vector3.new(9, 9, 9),
	}):Play()
	Debris:AddItem(shield, 0.35)
end

local function movementFeedback(actionName, position)
	local root = getRootPart()
	local origin = position or (root and root.Position)
	if not origin then
		return
	end

	if actionName == GameConstants.Actions.Dash or actionName == GameConstants.Actions.AirDash then
		spawnWorldPulse(origin, Color3.fromRGB(255, 160, 70), 7, 0.24)
		CameraController.PulseDash()
	elseif actionName == GameConstants.Actions.DoubleJump then
		spawnWorldPulse(origin - Vector3.new(0, 2.5, 0), Color3.fromRGB(190, 245, 255), 6, 0.25)
		CameraController.ShakeSmall()
	elseif actionName == GameConstants.Actions.Slide then
		spawnWorldPulse(origin - Vector3.new(0, 2.8, 0), Color3.fromRGB(210, 210, 210), 5, 0.2)
	elseif actionName == GameConstants.Actions.WallKick then
		spawnWorldPulse(origin, Color3.fromRGB(180, 240, 255), 5, 0.22)
		CameraController.ShakeSmall()
	elseif actionName == GameConstants.Actions.SprintBegin then
		CameraController.PulseSprint(true)
	elseif actionName == GameConstants.Actions.SprintEnd then
		CameraController.PulseSprint(false)
	end
end

local function handleFeedback(payload)
	if not payload then
		return
	end

	if payload.kind == "dealtDamage" and payload.amount and payload.amount > 0 then
		spawnDamageNumber(payload)
		pulseHitMarker()
		CameraController.HitConfirm()
	elseif payload.kind == "hitConfirm" then
		pulseHitMarker()
		CameraController.HitConfirm()
	elseif payload.kind == "ultimate" then
		CameraController.UltimatePulse()
		local root = getRootPart()
		if root then
			spawnWorldPulse(root.Position, colorForPayload(payload), 18, 0.45)
		end
	elseif payload.kind == "movement" then
		movementFeedback(payload.action, payload.position)
	elseif payload.kind == "guarded" then
		spawnGuardShield()
	elseif payload.kind == "blockBreak" then
		CameraController.ShakeMedium()
	end
end

function FeedbackController.Start()
	combatFeedback.OnClientEvent:Connect(handleFeedback)
end

return FeedbackController
