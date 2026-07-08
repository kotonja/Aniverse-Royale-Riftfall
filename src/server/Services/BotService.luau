local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared.Config.GameConstants)
local ArenaConstants = require(Shared.Config.ArenaConstants)
local TeamConstants = require(Shared.Config.TeamConstants)

local BotService = {}

local remotes = {}
local bots = {}

local function ensureRemote(remoteName)
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end

	local remote = folder:FindFirstChild(remoteName)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = remoteName
		remote.Parent = folder
	end

	return remote
end

local function findArena()
	local worldRoot = Workspace:FindFirstChild(GameConstants.World.RootName)
	return worldRoot and worldRoot:FindFirstChild(GameConstants.World.Arena3v3Name)
end

local function getBody(model)
	return model:FindFirstChild("Body") or model:FindFirstChildWhichIsA("BasePart")
end

local function updateBillboard(bot)
	local body = getBody(bot.model)
	if not body then
		return
	end

	local billboard = body:FindFirstChild("HealthBillboard")
	local label = billboard and billboard:FindFirstChild("HealthText")
	if label and label:IsA("TextLabel") then
		label.Text = ("%s\n%s %d/%d | Shield %d"):format(
			bot.name,
			TeamConstants.get(bot.teamId).shortName,
			math.floor(bot.health),
			math.floor(bot.maxHealth),
			math.floor(bot.shield)
		)
	end
end

local function payloadBot(bot)
	return {
		id = bot.id,
		name = bot.name,
		teamId = bot.teamId,
		characterId = bot.characterId,
		health = bot.health,
		maxHealth = bot.maxHealth,
		shield = bot.shield,
		maxShield = bot.maxShield,
		alive = bot.health > 0,
	}
end

local function buildPayload()
	local payload = {
		bots = {},
		teams = {
			sun = {},
			moon = {},
		},
	}

	for _, bot in pairs(bots) do
		local item = payloadBot(bot)
		table.insert(payload.bots, item)
		if payload.teams[bot.teamId] then
			table.insert(payload.teams[bot.teamId], item)
		end
	end

	return payload
end

local function registerBot(model)
	local teamId = tostring(model:GetAttribute("TeamId") or "")
	if not TeamConstants.isCombatTeam(teamId) then
		return
	end

	local bot = {
		id = model.Name,
		name = tostring(model:GetAttribute("DisplayName") or model.Name),
		model = model,
		teamId = teamId,
		characterId = tostring(model:GetAttribute("CharacterId") or "kairo_soljin"),
		maxHealth = model:GetAttribute("MaxHealth") or ArenaConstants.BotHealth,
		maxShield = model:GetAttribute("MaxShield") or ArenaConstants.BotShield,
		health = model:GetAttribute("CurrentHealth") or model:GetAttribute("MaxHealth") or ArenaConstants.BotHealth,
		shield = model:GetAttribute("CurrentShield") or model:GetAttribute("MaxShield") or ArenaConstants.BotShield,
	}

	model:SetAttribute("AR_TeamId", bot.teamId)
	model:SetAttribute("AR_TeamName", TeamConstants.get(bot.teamId).displayName)
	model:SetAttribute("CurrentHealth", bot.health)
	model:SetAttribute("CurrentShield", bot.shield)
	model:SetAttribute("IsArenaBot", true)
	CollectionService:AddTag(model, GameConstants.World.Tags.ArenaBot)

	bots[model] = bot
	updateBillboard(bot)
end

local function refreshBots()
	table.clear(bots)

	local arena = findArena()
	local folder = arena and arena:FindFirstChild(ArenaConstants.World.ArenaBots)
	if not folder then
		warn("[Aniverse Royale] ArenaBots folder missing. Apply the AR-003 blueprint.")
		return
	end

	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("Model") then
			registerBot(child)
		end
	end

	folder.ChildAdded:Connect(function(child)
		if child:IsA("Model") then
			registerBot(child)
			BotService.Broadcast()
		end
	end)
end

function BotService.Start()
	remotes.BotStateUpdate = ensureRemote(GameConstants.Remotes.BotStateUpdate)
	task.defer(function()
		refreshBots()
		BotService.Broadcast()
	end)
end

function BotService.Broadcast()
	if remotes.BotStateUpdate then
		remotes.BotStateUpdate:FireAllClients(buildPayload())
	end
end

function BotService.GetBots()
	local list = {}
	for _, bot in pairs(bots) do
		table.insert(list, bot)
	end
	return list
end

function BotService.GetLivingBots(teamId)
	local list = {}
	for _, bot in pairs(bots) do
		if bot.health > 0 and (not teamId or bot.teamId == teamId) then
			table.insert(list, bot)
		end
	end
	return list
end

function BotService.GetBody(bot)
	return bot and getBody(bot.model)
end

function BotService.ApplyDamage(bot, amount)
	if not bot or bot.health <= 0 then
		return 0
	end

	local finalDamage = amount
	local reductionUntil = bot.model:GetAttribute("DamageReductionUntil") or 0
	if os.clock() < reductionUntil then
		finalDamage = math.floor(finalDamage * (1 - (bot.model:GetAttribute("DamageReduction") or 0)))
	end

	local shieldDamage = math.min(bot.shield, finalDamage)
	bot.shield -= shieldDamage
	bot.health = math.max(0, bot.health - (finalDamage - shieldDamage))
	bot.model:SetAttribute("CurrentHealth", bot.health)
	bot.model:SetAttribute("CurrentShield", bot.shield)
	bot.model:SetAttribute("Defeated", bot.health <= 0)
	updateBillboard(bot)
	BotService.Broadcast()
	return finalDamage
end

function BotService.Heal(bot, amount)
	if not bot or bot.health <= 0 then
		return 0
	end

	local before = bot.health
	bot.health = math.min(bot.maxHealth, bot.health + amount)
	bot.model:SetAttribute("CurrentHealth", bot.health)
	updateBillboard(bot)
	BotService.Broadcast()
	return bot.health - before
end

function BotService.AddShield(bot, amount)
	if not bot or bot.health <= 0 then
		return 0
	end

	local before = bot.shield
	bot.shield = math.min(bot.maxShield + GameConstants.Combat.TemporaryShieldCap, bot.shield + amount)
	bot.model:SetAttribute("CurrentShield", bot.shield)
	updateBillboard(bot)
	BotService.Broadcast()
	return bot.shield - before
end

function BotService.SetDamageReduction(bot, amount, duration)
	if not bot or bot.health <= 0 then
		return
	end

	bot.model:SetAttribute("DamageReduction", amount)
	bot.model:SetAttribute("DamageReductionUntil", os.clock() + duration)
	BotService.Broadcast()
end

function BotService.SetSlow(bot, multiplier, duration)
	if not bot or bot.health <= 0 then
		return
	end

	bot.model:SetAttribute("Slowed", true)
	bot.model:SetAttribute("SlowMultiplier", multiplier)
	task.delay(duration, function()
		if bot.model.Parent then
			bot.model:SetAttribute("Slowed", false)
		end
	end)
	BotService.Broadcast()
end

function BotService.Mark(bot, duration)
	if not bot or bot.health <= 0 then
		return
	end

	bot.model:SetAttribute("LightMarked", true)
	task.delay(duration, function()
		if bot.model.Parent then
			bot.model:SetAttribute("LightMarked", false)
		end
	end)
	BotService.Broadcast()
end

function BotService.ResetBots()
	refreshBots()
	for _, bot in pairs(bots) do
		bot.health = bot.maxHealth
		bot.shield = bot.maxShield
		bot.model:SetAttribute("CurrentHealth", bot.health)
		bot.model:SetAttribute("CurrentShield", bot.shield)
		bot.model:SetAttribute("Defeated", false)
		bot.model:SetAttribute("LightMarked", false)
		bot.model:SetAttribute("Slowed", false)
		updateBillboard(bot)
	end
	BotService.Broadcast()
end

return BotService
