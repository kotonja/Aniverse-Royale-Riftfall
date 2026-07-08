local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared.Config.GameConstants)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local stateUpdate = remotes:WaitForChild(GameConstants.Remotes.StateUpdate)
local combatFeedback = remotes:WaitForChild(GameConstants.Remotes.CombatFeedback)

local HUDController = {}

local latestPayload = nil
local cooldowns = {}
local feedbackExpiresAt = 0

local function getRoot()
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	local hud = playerGui and playerGui:FindFirstChild("AniverseHUD")
	return hud and hud:FindFirstChild("Root")
end

local function setText(root, path, text)
	local current = root
	for segment in string.gmatch(path, "[^.]+") do
		current = current and current:FindFirstChild(segment)
	end
	if current and current:IsA("TextLabel") or current and current:IsA("TextButton") then
		current.Text = text
	end
end

local function setBar(root, name, value, maxValue)
	local bars = root:FindFirstChild("Bars")
	local bar = bars and bars:FindFirstChild(name)
	if not bar then
		return
	end

	local fill = bar:FindFirstChild("Fill")
	local label = bar:FindFirstChild("Label")
	local ratio = 0
	if maxValue and maxValue > 0 then
		ratio = math.clamp(value / maxValue, 0, 1)
	end

	if fill and fill:IsA("Frame") then
		fill.Size = UDim2.fromScale(ratio, 1)
	end

	if label and label:IsA("TextLabel") then
		label.Text = name .. " " .. tostring(math.floor(value)) .. "/" .. tostring(math.floor(maxValue))
	end
end

local function setCooldown(root, buttonName, actionName)
	local abilities = root:FindFirstChild("Abilities")
	local button = abilities and abilities:FindFirstChild(buttonName)
	local cooldownLabel = button and button:FindFirstChild("Cooldown")
	if not cooldownLabel or not cooldownLabel:IsA("TextLabel") then
		return
	end

	local remaining = cooldowns[actionName] or 0
	if remaining > 0.05 then
		cooldownLabel.Text = string.format("%.1f", remaining)
	else
		cooldownLabel.Text = ""
	end
end

local function render()
	local root = getRoot()
	if not root or not latestPayload then
		return
	end

	local character = latestPayload.character
	local stats = latestPayload.stats
	if character then
		setText(root, "Top.CharacterName", character.displayName .. " - " .. character.subtitle)
		setText(root, "Top.RoleName", character.role .. " | Aura: " .. character.aura)
	end

	if stats then
		setBar(root, "Health", stats.health, stats.maxHealth)
		setBar(root, "Shield", stats.shield, stats.maxShield)
		setBar(root, "Flow", stats.flow, stats.maxFlow)
		setBar(root, "Guard", stats.guard, stats.maxGuard)
	end

	setCooldown(root, "Skill1Button", "skill1")
	setCooldown(root, "Skill2Button", "skill2")
	setCooldown(root, "Skill3Button", "skill3")
	setCooldown(root, "UltimateButton", "ultimate")
	setCooldown(root, "BasicButton", "basic")

	if os.clock() > feedbackExpiresAt then
		setText(root, "Feedback", "")
	end
end

function HUDController.Start()
	stateUpdate.OnClientEvent:Connect(function(payload)
		latestPayload = payload
		if payload and payload.cooldowns then
			for actionName, remaining in pairs(payload.cooldowns) do
				cooldowns[actionName] = remaining
			end
		end
		render()
	end)

	combatFeedback.OnClientEvent:Connect(function(payload)
		local root = getRoot()
		if not root or not payload then
			return
		end

		local message = payload.kind or "feedback"
		if payload.action then
			message ..= ": " .. tostring(payload.action)
		elseif payload.amount then
			message ..= ": " .. tostring(payload.amount)
		end

		setText(root, "Feedback", message)
		feedbackExpiresAt = os.clock() + 1.4
	end)

	RunService.RenderStepped:Connect(function(deltaTime)
		for actionName, remaining in pairs(cooldowns) do
			cooldowns[actionName] = math.max(0, remaining - deltaTime)
		end
		render()
	end)
end

return HUDController
