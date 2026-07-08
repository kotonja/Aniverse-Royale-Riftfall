local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared.Config.GameConstants)
local CharacterDefinitions = require(Shared.Config.CharacterDefinitions)

local player = Players.LocalPlayer
local requestCharacterChange = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild(GameConstants.Remotes.RequestCharacterChange)

local CharacterSelectController = {}

local boundButtons = {}

local function getPanel()
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	local hud = playerGui and playerGui:FindFirstChild(GameConstants.UI.HudName)
	local root = hud and hud:FindFirstChild(GameConstants.UI.RootName)
	return root and (root:FindFirstChild(GameConstants.UI.CharacterPanelName) or root:FindFirstChild("CharacterSelect"))
end

local function bindButton(button, characterId)
	if not button or not button:IsA("TextButton") or boundButtons[button] then
		return
	end

	if not CharacterDefinitions.exists(characterId) then
		return
	end

	boundButtons[button] = true
	button.Activated:Connect(function()
		requestCharacterChange:FireServer(characterId)
	end)
end

local function bindNamedButton(panel, buttonName, characterId)
	bindButton(panel and panel:FindFirstChild(buttonName, true), characterId)
end

local function bindPanel()
	local panel = getPanel()
	if not panel then
		return
	end

	for _, descendant in ipairs(panel:GetDescendants()) do
		if descendant:IsA("TextButton") then
			local characterId = descendant:GetAttribute("CharacterId")
			if characterId then
				bindButton(descendant, tostring(characterId))
			end
		end
	end

	bindNamedButton(panel, "KairoButton", "kairo_soljin")
	bindNamedButton(panel, "MiraButton", "mira_gale")
	bindNamedButton(panel, "SoraButton", "sora_nym")
	bindNamedButton(panel, "AtlasButton", "atlas_null")
	bindNamedButton(panel, "KairoCard", "kairo_soljin")
	bindNamedButton(panel, "MiraCard", "mira_gale")
	bindNamedButton(panel, "SoraCard", "sora_nym")
	bindNamedButton(panel, "AtlasCard", "atlas_null")
end

function CharacterSelectController.Start()
	task.spawn(function()
		local playerGui = player:WaitForChild("PlayerGui")
		playerGui:WaitForChild(GameConstants.UI.HudName, 10)
		bindPanel()

		local panel = getPanel()
		if panel then
			panel.DescendantAdded:Connect(function(descendant)
				if descendant:IsA("TextButton") then
					local characterId = descendant:GetAttribute("CharacterId")
					if characterId then
						bindButton(descendant, tostring(characterId))
					end
				end
			end)
		end
	end)
end

return CharacterSelectController
