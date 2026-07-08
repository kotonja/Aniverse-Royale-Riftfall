local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared.Config.GameConstants)
local InputBindings = require(Shared.Config.InputBindings)
local UIConstants = require(Shared.Config.UIConstants)
local AbilityDefinitions = require(Shared.Config.AbilityDefinitions)
local MathUtil = require(Shared.Utility.MathUtil)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local stateUpdate = remotes:WaitForChild(GameConstants.Remotes.StateUpdate)
local combatFeedback = remotes:WaitForChild(GameConstants.Remotes.CombatFeedback)

local HUDController = {}

local latestPayload = nil
local cooldowns = {}
local feedbackExpiresAt = 0
local debugVisible = false

local function getRoot()
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	local hud = playerGui and playerGui:FindFirstChild(GameConstants.UI.HudName)
	return hud and hud:FindFirstChild(GameConstants.UI.RootName)
end

local function findChild(root, path)
	local current = root
	for segment in string.gmatch(path, "[^.]+") do
		current = current and current:FindFirstChild(segment)
	end
	return current
end

local function setText(root, path, text)
	local current = findChild(root, path)
	if current and (current:IsA("TextLabel") or current:IsA("TextButton")) then
		current.Text = text
	end
end

local function setVisible(root, path, visible)
	local current = findChild(root, path)
	if current and current:IsA("GuiObject") then
		current.Visible = visible
	end
end

local function panel(root, primary, fallback)
	return root:FindFirstChild(primary) or (fallback and root:FindFirstChild(fallback))
end

local function setBar(root, name, value, maxValue)
	local bars = panel(root, GameConstants.UI.BottomBarsName, "Bars")
	local bar = bars and bars:FindFirstChild(name)
	if not bar then
		return
	end

	local fill = bar:FindFirstChild("Fill")
	local label = bar:FindFirstChild("Label")
	local ratio = MathUtil.ratio(value, maxValue)

	if fill and fill:IsA("Frame") then
		fill.Size = UDim2.fromScale(ratio, 1)
	end

	if label and label:IsA("TextLabel") then
		label.Text = name .. " " .. tostring(math.floor(value or 0)) .. "/" .. tostring(math.floor(maxValue or 0))
	end
end

local function setButtonText(button, mainText, keyText)
	local label = button:FindFirstChild("Label")
	local keyLabel = button:FindFirstChild("KeyLabel")
	if label and label:IsA("TextLabel") then
		label.Text = mainText
	elseif button:IsA("TextButton") then
		button.Text = mainText .. (keyText and ("\n" .. keyText) or "")
	end

	if keyLabel and keyLabel:IsA("TextLabel") then
		keyLabel.Text = keyText or ""
	end
end

local function getHotbarButton(root, buttonName)
	local hotbar = panel(root, GameConstants.UI.AbilityHotbarName, "Abilities")
	return hotbar and hotbar:FindFirstChild(buttonName)
end

local function setCooldownVisual(button, remaining)
	local cooldownText = button:FindFirstChild("CooldownText") or button:FindFirstChild("Cooldown")
	local overlay = button:FindFirstChild("CooldownOverlay")
	if remaining > 0.05 then
		if cooldownText and cooldownText:IsA("TextLabel") then
			cooldownText.Text = string.format("%.1f", remaining)
		end
		if overlay and overlay:IsA("GuiObject") then
			overlay.Visible = true
		end
	else
		if cooldownText and cooldownText:IsA("TextLabel") then
			cooldownText.Text = ""
		end
		if overlay and overlay:IsA("GuiObject") then
			overlay.Visible = false
		end
	end
end

local function setNoFlowVisual(button, visible)
	local overlay = button:FindFirstChild("NoFlowOverlay")
	if overlay and overlay:IsA("GuiObject") then
		overlay.Visible = visible
	end
end

local function setAbilityButton(root, actionKey)
	local binding = InputBindings.getAction(actionKey)
	if not binding then
		return
	end

	local button = getHotbarButton(root, binding.buttonName)
	if not button or not button:IsA("TextButton") then
		return
	end

	local character = latestPayload and latestPayload.character
	local stats = latestPayload and latestPayload.stats
	local actionName = binding.remote
	local abilityName = binding.label
	local noFlow = false

	if character and character.abilities and character.abilities[actionName] then
		abilityName = character.abilities[actionName]
	end

	local ability = character and AbilityDefinitions.get(character.id, actionName)
	if ability and ability.flowCost and stats then
		noFlow = (stats.flow or 0) < ability.flowCost
	end

	setButtonText(button, abilityName, binding.keyText)
	setCooldownVisual(button, cooldowns[actionName] or 0)
	setNoFlowVisual(button, noFlow)

	if button.BackgroundColor3 and (cooldowns[actionName] or 0) <= 0.05 and not noFlow then
		local readyStroke = button:FindFirstChild("ReadyStroke")
		if readyStroke and readyStroke:IsA("UIStroke") then
			readyStroke.Color = UIConstants.Colors.Ready
			readyStroke.Transparency = 0.2
		end
	elseif button.BackgroundColor3 then
		local readyStroke = button:FindFirstChild("ReadyStroke")
		if readyStroke and readyStroke:IsA("UIStroke") then
			readyStroke.Transparency = 0.75
		end
	end
end

local function setFeedback(root, message)
	setText(root, GameConstants.UI.FeedbackLayerName .. ".StatusText", message)
	setText(root, "Feedback", message)
end

local function renderDebug(root)
	local debugPanel = root:FindFirstChild(GameConstants.UI.DebugPanelName)
	if not debugPanel or not debugPanel:IsA("GuiObject") then
		return
	end

	debugPanel.Visible = debugVisible
	if not debugVisible then
		return
	end

	local stats = latestPayload and latestPayload.stats
	local movement = latestPayload and latestPayload.movement
	local text = debugPanel:FindFirstChild("Text")
	if text and text:IsA("TextLabel") then
		text.Text = string.format(
			"AR-003 DEBUG\nFlow %d | Guard %d\nSprint %s | Dash %s | Slide %s",
			math.floor(stats and stats.flow or 0),
			math.floor(stats and stats.guard or 0),
			tostring(movement and movement.sprinting or false),
			tostring(movement and movement.dashing or false),
			tostring(movement and movement.sliding or false)
		)
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
		setText(root, GameConstants.UI.TopBarName .. ".CharacterName", character.displayName .. " - " .. character.subtitle)
		setText(root, GameConstants.UI.TopBarName .. ".RoleName", character.role .. " | Aura: " .. character.aura)
		setText(root, "Top.CharacterName", character.displayName .. " - " .. character.subtitle)
		setText(root, "Top.RoleName", character.role .. " | Aura: " .. character.aura)
		setText(root, GameConstants.UI.CharacterPanelName .. ".SelectedName", character.displayName)
		setText(root, GameConstants.UI.CharacterPanelName .. ".SelectedRole", character.role .. " | Aura: " .. character.aura)
	end

	if stats then
		setBar(root, "Health", stats.health, stats.maxHealth)
		setBar(root, "Shield", stats.shield, stats.maxShield)
		setBar(root, "Flow", stats.flow, stats.maxFlow)
		setBar(root, "Guard", stats.guard, stats.maxGuard)
	end

	for _, actionKey in ipairs(InputBindings.listHotbarOrder()) do
		setAbilityButton(root, actionKey)
	end

	if latestPayload.error then
		setFeedback(root, tostring(latestPayload.error))
		feedbackExpiresAt = os.clock() + 1.4
	elseif os.clock() > feedbackExpiresAt then
		setFeedback(root, "")
	end

	renderDebug(root)
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
		if payload.kind == "selected" and payload.action then
			message = "Selected " .. tostring(payload.action)
		elseif payload.kind == "noFlow" then
			message = UIConstants.Messages.NoFlow
		elseif payload.kind == "cooldown" then
			message = UIConstants.Messages.Cooldown
			if payload.remaining then
				message ..= " " .. string.format("%.1f", payload.remaining)
			end
		elseif payload.kind == "dealtDamage" and payload.amount then
			message = tostring(math.floor(payload.amount)) .. " damage"
		elseif payload.kind == "teamSelected" and payload.action then
			message = "Selected " .. tostring(payload.action)
		elseif payload.kind == "arenaNeedsTeams" then
			message = "Need Sun and Moon combatants"
		elseif payload.kind == "arenaBusy" and payload.action then
			message = "Arena " .. tostring(payload.action)
		elseif payload.kind == "allyShielded" then
			message = "Ally shielded"
		elseif payload.kind == "allyHealed" then
			message = "Ally healed"
		elseif payload.kind == "enemyRevealed" then
			message = "Enemy revealed"
		elseif payload.kind == "pulled" then
			message = "Pulled"
		elseif payload.kind == "slowed" then
			message = "Slowed"
		elseif payload.kind == "damageReduced" then
			message = "Damage reduced"
		elseif payload.action then
			message = tostring(payload.action)
		elseif payload.amount then
			message ..= ": " .. tostring(payload.amount)
		end

		setFeedback(root, message)
		feedbackExpiresAt = os.clock() + 1.4
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.KeyCode == InputBindings.Keyboard.DebugPanel then
			debugVisible = not debugVisible
			render()
		end
	end)

	RunService.RenderStepped:Connect(function(deltaTime)
		for actionName, remaining in pairs(cooldowns) do
			cooldowns[actionName] = math.max(0, remaining - deltaTime)
		end
		render()
	end)
end

return HUDController
