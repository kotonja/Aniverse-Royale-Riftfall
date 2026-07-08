local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared.Config.GameConstants)
local AbilityDefinitions = require(Shared.Config.AbilityDefinitions)
local TeamConstants = require(Shared.Config.TeamConstants)
local RateLimiter = require(Shared.Utility.RateLimiter)

local CombatService = {}

local CharacterService = nil
local CooldownService = nil
local TeamService = nil
local BotService = nil
local ArenaRoundService = nil
local remotes = {}
local dummyModels = {}
local limiter = RateLimiter.new({
	capacity = GameConstants.Combat.RemoteRateLimitCapacity,
	refillPerSecond = GameConstants.Combat.RemoteRateLimitRefill,
})

local allowedActions = {
	[GameConstants.Actions.Basic] = true,
	[GameConstants.Actions.BlockBegin] = true,
	[GameConstants.Actions.BlockEnd] = true,
	[GameConstants.Actions.Skill1] = true,
	[GameConstants.Actions.Skill2] = true,
	[GameConstants.Actions.Skill3] = true,
	[GameConstants.Actions.Ultimate] = true,
}

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

local function getRoot(player)
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function getDummyBody(dummy)
	return dummy:FindFirstChild("Body") or dummy:FindFirstChildWhichIsA("BasePart")
end

local function fireFeedback(player, payload)
	if remotes.CombatFeedback then
		remotes.CombatFeedback:FireClient(player, payload)
	end
end

local function fireAll(payload)
	if remotes.CombatFeedback then
		remotes.CombatFeedback:FireAllClients(payload)
	end
end

local function updateDummyBillboard(dummy)
	local body = getDummyBody(dummy)
	if not body then
		return
	end

	local billboard = body:FindFirstChild("HealthBillboard")
	local label = billboard and billboard:FindFirstChild("HealthText")
	if label and label:IsA("TextLabel") then
		local health = math.max(0, dummy:GetAttribute("CurrentHealth") or GameConstants.Combat.DummyMaxHealth)
		local maxHealth = dummy:GetAttribute("MaxHealth") or GameConstants.Combat.DummyMaxHealth
		local shield = math.max(0, dummy:GetAttribute("CurrentShield") or 0)
		local dummyType = tostring(dummy:GetAttribute("DummyType") or "Basic")
		local shieldText = shield > 0 and (" | Shield " .. tostring(math.floor(shield))) or ""
		label.Text = ("%s Dummy\n%d/%d%s"):format(dummyType, math.floor(health), math.floor(maxHealth), shieldText)
	end
end

local function refreshDummies()
	table.clear(dummyModels)

	local worldRoot = Workspace:FindFirstChild(GameConstants.World.RootName)
	local dojo = worldRoot and worldRoot:FindFirstChild(GameConstants.World.TrainingDojoName)
	local folder = dojo and dojo:FindFirstChild(GameConstants.World.DummyFolderName)
	if not folder then
		warn("[Aniverse Royale] DamageDummies folder missing. Apply blueprints/ar003/ar003_3v3_arena.blueprint.json.")
		return
	end

	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("Model") then
			CollectionService:AddTag(child, GameConstants.World.Tags.DamageDummy)
			child:SetAttribute("IsDamageDummy", true)
			child:SetAttribute("MaxHealth", child:GetAttribute("MaxHealth") or GameConstants.Combat.DummyMaxHealth)
			child:SetAttribute("CurrentHealth", child:GetAttribute("CurrentHealth") or child:GetAttribute("MaxHealth"))

			if child:GetAttribute("DummyType") == "Shield" then
				child:SetAttribute("MaxShield", child:GetAttribute("MaxShield") or 120)
				child:SetAttribute("CurrentShield", child:GetAttribute("CurrentShield") or child:GetAttribute("MaxShield"))
			end

			table.insert(dummyModels, child)
			updateDummyBillboard(child)
		end
	end
end

local function spawnHitVisual(position, color, radius, duration, name)
	local marker = Instance.new("Part")
	marker.Name = name or "AR003HitVisual"
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanQuery = false
	marker.Material = Enum.Material.Neon
	marker.Shape = Enum.PartType.Ball
	marker.Transparency = 0.45
	marker.Size = Vector3.new(radius, radius, radius)
	marker.Color = color
	marker.Position = position
	marker.Parent = Workspace
	Debris:AddItem(marker, duration or 0.25)
end

local function spawnDisk(position, color, radius, duration, name)
	local marker = Instance.new("Part")
	marker.Name = name or "AR003WarningDisk"
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanQuery = false
	marker.Material = Enum.Material.Neon
	marker.Transparency = 0.35
	marker.Size = Vector3.new(radius * 2, 0.2, radius * 2)
	marker.Color = color
	marker.Position = position
	marker.Parent = Workspace
	Debris:AddItem(marker, duration or 0.5)
end

local function setMarkedVisual(instance, adornee, duration)
	if not adornee then
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "AR003LightMark"
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromOffset(80, 30)
	billboard.StudsOffset = Vector3.new(0, 5, 0)
	billboard.Adornee = adornee
	billboard.Parent = instance

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Text = "MARK"
	label.TextColor3 = Color3.fromRGB(255, 244, 188)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Size = UDim2.fromScale(1, 1)
	label.Parent = billboard

	Debris:AddItem(billboard, duration)
end

local function applyDamageToDummy(attacker, dummy, amount)
	local maxHealth = dummy:GetAttribute("MaxHealth") or GameConstants.Combat.DummyMaxHealth
	local current = dummy:GetAttribute("CurrentHealth") or maxHealth
	local finalDamage = amount
	local absorbed = 0

	if dummy:GetAttribute("DummyType") == "Guard" then
		finalDamage = math.max(1, math.floor(finalDamage * 0.45))
	elseif dummy:GetAttribute("DummyType") == "Shield" then
		local shield = dummy:GetAttribute("CurrentShield") or 0
		absorbed = math.min(shield, finalDamage)
		shield -= absorbed
		dummy:SetAttribute("CurrentShield", shield)
		finalDamage -= absorbed
	end

	current = math.max(0, current - finalDamage)
	dummy:SetAttribute("CurrentHealth", current)
	updateDummyBillboard(dummy)

	if current <= 0 and not dummy:GetAttribute("ResetPending") then
		dummy:SetAttribute("ResetPending", true)
		task.delay(GameConstants.Combat.DummyResetDelay, function()
			if dummy.Parent then
				dummy:SetAttribute("CurrentHealth", maxHealth)
				if dummy:GetAttribute("MaxShield") then
					dummy:SetAttribute("CurrentShield", dummy:GetAttribute("MaxShield"))
				end
				dummy:SetAttribute("ResetPending", false)
				updateDummyBillboard(dummy)
			end
		end)
	end

	return finalDamage + absorbed
end

local function canDamageTeam(attacker, targetTeamId)
	if not TeamService then
		return false
	end

	local attackerTeamId = TeamService.GetPlayerTeam(attacker)
	return TeamService.AreTeamIdsEnemies(attackerTeamId, targetTeamId)
end

local function canDamagePlayer(attacker, targetPlayer)
	if attacker == targetPlayer then
		return false
	end

	if not TeamService then
		return true
	end

	local attackerTeamId = TeamService.GetPlayerTeam(attacker)
	local targetTeamId = TeamService.GetPlayerTeam(targetPlayer)
	if TeamConstants.isCombatTeam(attackerTeamId) or TeamConstants.isCombatTeam(targetTeamId) then
		return TeamService.AreEnemies(attacker, targetPlayer)
	end

	return false
end

local function isAllyPlayer(attacker, targetPlayer)
	return attacker == targetPlayer or (TeamService and TeamService.AreAllies(attacker, targetPlayer))
end

local function applyDamageReduction(targetPlayer, amount)
	local state = CharacterService.GetState(targetPlayer)
	if not state then
		return amount
	end

	local finalDamage = amount
	if state.sunburstGuardUntil and os.clock() < state.sunburstGuardUntil then
		finalDamage = math.floor(finalDamage * 0.55)
	end
	if state.damageReductionUntil and os.clock() < state.damageReductionUntil then
		finalDamage = math.floor(finalDamage * (1 - (state.damageReductionMultiplier or 0)))
	end

	return math.max(0, finalDamage)
end

local function applyDamageToPlayer(attacker, targetPlayer, amount, knockback)
	if not canDamagePlayer(attacker, targetPlayer) then
		return 0
	end

	local state = CharacterService.GetState(targetPlayer)
	if not state or state.health <= 0 or state.defeated then
		return 0
	end

	local finalDamage = applyDamageReduction(targetPlayer, amount)
	if state.blocking and os.clock() >= state.blockBrokenUntil then
		finalDamage = math.floor(finalDamage * GameConstants.Combat.BlockDamageMultiplier)
		state.guard = math.max(0, state.guard - amount * GameConstants.Combat.BlockGuardDamageMultiplier)

		if state.guard <= 0 then
			state.blocking = false
			state.blockBrokenUntil = os.clock() + GameConstants.Combat.BlockBreakLockout
			fireFeedback(targetPlayer, { kind = "blockBreak" })
		else
			fireFeedback(targetPlayer, { kind = "guarded", amount = finalDamage })
		end
	end

	local shieldDamage = math.min(state.shield, finalDamage)
	state.shield -= shieldDamage
	state.tempShield = math.max(0, state.shield - state.maxShield)
	state.health = math.max(0, state.health - (finalDamage - shieldDamage))

	local root = getRoot(targetPlayer)
	if root and knockback then
		local definition = CharacterService.GetDefinition(targetPlayer)
		local multiplier = definition and definition.baseStats.knockbackMultiplier or 1
		root.AssemblyLinearVelocity += knockback * multiplier
	end

	if state.health <= 0 then
		CharacterService.MarkDefeated(targetPlayer)
		if ArenaRoundService then
			ArenaRoundService.RecordPlayerDefeated(targetPlayer)
		end
	else
		CharacterService.SendState(targetPlayer)
	end

	fireFeedback(targetPlayer, { kind = "tookDamage", amount = finalDamage })
	return finalDamage
end

local function collectTargets(attacker, range, radius, useCone, includeBots)
	refreshDummies()

	local root = getRoot(attacker)
	if not root then
		return {}
	end

	local origin = root.Position
	local forward = root.CFrame.LookVector
	local targets = {}

	for _, dummy in ipairs(dummyModels) do
		local body = getDummyBody(dummy)
		if body then
			local offset = body.Position - origin
			local distance = offset.Magnitude
			local inFront = distance > 0 and offset.Unit:Dot(forward) >= 0.2
			if distance <= range and (not useCone or inFront or distance <= radius) then
				table.insert(targets, { kind = "dummy", dummy = dummy, position = body.Position })
			end
		end
	end

	if includeBots and BotService then
		for _, bot in ipairs(BotService.GetBots()) do
			local body = BotService.GetBody(bot)
			if body and bot.health > 0 and canDamageTeam(attacker, bot.teamId) then
				local offset = body.Position - origin
				local distance = offset.Magnitude
				local inFront = distance > 0 and offset.Unit:Dot(forward) >= 0.2
				if distance <= range and (not useCone or inFront or distance <= radius) then
					table.insert(targets, { kind = "bot", bot = bot, position = body.Position })
				end
			end
		end
	end

	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		if canDamagePlayer(attacker, targetPlayer) then
			local targetRoot = getRoot(targetPlayer)
			if targetRoot then
				local offset = targetRoot.Position - origin
				local distance = offset.Magnitude
				local inFront = distance > 0 and offset.Unit:Dot(forward) >= 0.2
				if distance <= range and (not useCone or inFront or distance <= radius) then
					table.insert(targets, { kind = "player", player = targetPlayer, position = targetRoot.Position })
				end
			end
		end
	end

	return targets
end

local function collectTargetsAroundPosition(attacker, position, radius, includeBots)
	refreshDummies()

	local targets = {}

	if BotService and includeBots then
		for _, bot in ipairs(BotService.GetBots()) do
			local body = BotService.GetBody(bot)
			if body and bot.health > 0 and canDamageTeam(attacker, bot.teamId) then
				if (body.Position - position).Magnitude <= radius then
					table.insert(targets, { kind = "bot", bot = bot, position = body.Position })
				end
			end
		end
	end

	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		if canDamagePlayer(attacker, targetPlayer) then
			local targetRoot = getRoot(targetPlayer)
			if targetRoot and (targetRoot.Position - position).Magnitude <= radius then
				table.insert(targets, { kind = "player", player = targetPlayer, position = targetRoot.Position })
			end
		end
	end

	for _, dummy in ipairs(dummyModels) do
		local body = getDummyBody(dummy)
		if body and (body.Position - position).Magnitude <= radius then
			table.insert(targets, { kind = "dummy", dummy = dummy, position = body.Position })
		end
	end

	return targets
end

local function damageTargets(attacker, targets, amount, knockbackScale)
	local root = getRoot(attacker)
	local forward = root and root.CFrame.LookVector or Vector3.new(0, 0, -1)
	local totalDamage = 0

	for _, target in ipairs(targets) do
		local dealt = 0
		if target.kind == "dummy" then
			dealt = applyDamageToDummy(attacker, target.dummy, amount)
		elseif target.kind == "bot" then
			dealt = BotService.ApplyDamage(target.bot, amount)
		elseif target.kind == "player" then
			dealt = applyDamageToPlayer(attacker, target.player, amount, forward * (knockbackScale or 20))
		end
		totalDamage += dealt

		if target.position then
			spawnHitVisual(target.position + Vector3.new(0, 2, 0), Color3.fromRGB(255, 215, 80), 3, 0.2)
			fireFeedback(attacker, {
				kind = "dealtDamage",
				amount = dealt,
				position = target.position,
			})
		end
	end

	return totalDamage
end

local function pullTargetToward(origin, target, strength)
	local body = nil
	if target.kind == "player" then
		body = getRoot(target.player)
	elseif target.kind == "bot" then
		body = BotService.GetBody(target.bot)
	elseif target.kind == "dummy" then
		body = getDummyBody(target.dummy)
	end

	if not body or body.Anchored then
		return
	end

	local direction = origin - body.Position
	if direction.Magnitude > 0.1 then
		body.AssemblyLinearVelocity += direction.Unit * strength
	end
end

local function markTarget(target, duration)
	if target.kind == "player" then
		local root = getRoot(target.player)
		target.player:SetAttribute("LightMarked", true)
		setMarkedVisual(target.player.Character or target.player, root, duration)
		task.delay(duration, function()
			if target.player.Parent then
				target.player:SetAttribute("LightMarked", false)
			end
		end)
	elseif target.kind == "bot" then
		local body = BotService.GetBody(target.bot)
		BotService.Mark(target.bot, duration)
		setMarkedVisual(target.bot.model, body, duration)
	elseif target.kind == "dummy" then
		local body = getDummyBody(target.dummy)
		target.dummy:SetAttribute("LightMarked", true)
		setMarkedVisual(target.dummy, body, duration)
		task.delay(duration, function()
			if target.dummy.Parent then
				target.dummy:SetAttribute("LightMarked", false)
			end
		end)
	end
end

local function slowTarget(target, multiplier, duration)
	if target.kind == "player" then
		CharacterService.SetSlow(target.player, multiplier, duration)
	elseif target.kind == "bot" then
		BotService.SetSlow(target.bot, multiplier, duration)
	elseif target.kind == "dummy" then
		target.dummy:SetAttribute("Slowed", true)
		task.delay(duration, function()
			if target.dummy.Parent then
				target.dummy:SetAttribute("Slowed", false)
			end
		end)
	end
end

local function collectAllies(attacker, radius)
	local root = getRoot(attacker)
	if not root then
		return {}
	end

	local teamId = TeamService and TeamService.GetPlayerTeam(attacker)
	local allies = {
		{
			kind = "player",
			player = attacker,
			position = root.Position,
			healthRatio = 1,
			distance = 0,
		},
	}

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= attacker and isAllyPlayer(attacker, player) then
			local targetRoot = getRoot(player)
			local state = CharacterService.GetState(player)
			if targetRoot and state and not state.defeated then
				local distance = (targetRoot.Position - root.Position).Magnitude
				if distance <= radius then
					table.insert(allies, {
						kind = "player",
						player = player,
						position = targetRoot.Position,
						healthRatio = state.health / math.max(1, state.maxHealth),
						distance = distance,
					})
				end
			end
		end
	end

	if BotService and TeamConstants.isCombatTeam(teamId) then
		for _, bot in ipairs(BotService.GetLivingBots(teamId)) do
			local body = BotService.GetBody(bot)
			if body then
				local distance = (body.Position - root.Position).Magnitude
				if distance <= radius then
					table.insert(allies, {
						kind = "bot",
						bot = bot,
						position = body.Position,
						healthRatio = bot.health / math.max(1, bot.maxHealth),
						distance = distance,
					})
				end
			end
		end
	end

	return allies
end

local function applyShieldToTarget(attacker, target, amount)
	local applied = 0
	if target.kind == "player" then
		applied = CharacterService.AddShield(target.player, amount)
		fireFeedback(target.player, { kind = "allyShielded", amount = applied })
	elseif target.kind == "bot" then
		applied = BotService.AddShield(target.bot, amount)
	end

	if applied > 0 then
		CharacterService.AddUltimateCharge(attacker, 4)
	end
	return applied
end

local function healTarget(attacker, target, amount)
	local applied = 0
	if target.kind == "player" then
		applied = CharacterService.Heal(target.player, amount)
		fireFeedback(target.player, { kind = "allyHealed", amount = applied })
	elseif target.kind == "bot" then
		applied = BotService.Heal(target.bot, amount)
	end

	if applied > 0 then
		CharacterService.AddUltimateCharge(attacker, 4)
	end
	return applied
end

local function runBasic(player, definition)
	local ability = AbilityDefinitions.get(definition.id, "basic")
	if not ability then
		return
	end

	local targets = collectTargets(player, ability.range, ability.radius, true, true)
	local totalDamage = damageTargets(player, targets, ability.damage, definition.id == "atlas_null" and 12 or 24)

	if definition.id == "atlas_null" then
		local root = getRoot(player)
		if root then
			for _, target in ipairs(targets) do
				pullTargetToward(root.Position, target, ability.pullStrength or 0)
			end
		end
	end

	fireFeedback(player, {
		kind = totalDamage > 0 and "hitConfirm" or "ability",
		action = ability.displayName,
		amount = totalDamage,
	})
end

local function runAreaAbility(player, ability, color)
	local root = getRoot(player)
	if not root then
		return 0
	end

	spawnHitVisual(root.Position, color, ability.radius or 12, 0.35)
	local targets = collectTargets(player, ability.radius or 16, ability.radius or 16, false, true)
	return damageTargets(player, targets, ability.damage or 0, 32)
end

local function runKairo(player, actionName, ability)
	local root = getRoot(player)
	if not root then
		return 0
	end

	if actionName == "skill1" then
		root.AssemblyLinearVelocity = root.CFrame.LookVector * 82 + Vector3.new(0, 10, 0)
		spawnHitVisual(root.Position + root.CFrame.LookVector * 8, ability.vfxColor, 5, 0.22)
		return damageTargets(player, collectTargets(player, ability.range, ability.radius, true, true), ability.damage, 50)
	elseif actionName == "skill2" then
		local state = CharacterService.GetState(player)
		if state then
			state.sunburstGuardUntil = os.clock() + (ability.duration or 4)
			state.guard = math.min(state.maxGuard, state.guard + 20)
			CharacterService.SendState(player)
		end
		spawnHitVisual(root.Position, ability.vfxColor, 9, 0.45)
		return 0
	elseif actionName == "skill3" then
		root.AssemblyLinearVelocity = root.CFrame.LookVector * 42 + Vector3.new(0, 64, 0)
		task.delay(0.28, function()
			if player.Parent then
				runAreaAbility(player, ability, ability.vfxColor)
			end
		end)
		return 0
	elseif actionName == "ultimate" then
		return runAreaAbility(player, ability, ability.vfxColor)
	end

	return 0
end

local function runMira(player, actionName, ability)
	local root = getRoot(player)
	if not root then
		return 0
	end

	if actionName == "skill1" then
		spawnHitVisual(root.Position + root.CFrame.LookVector * 15, ability.vfxColor, 4, 0.28)
		return damageTargets(player, collectTargets(player, ability.range, ability.radius, true, true), ability.damage, 30)
	elseif actionName == "skill2" then
		root.AssemblyLinearVelocity = root.CFrame.LookVector * 96 + Vector3.new(0, 18, 0)
		spawnHitVisual(root.Position, ability.vfxColor, 5, 0.2)
		return damageTargets(player, collectTargets(player, ability.range, ability.radius, true, true), ability.damage or 0, 26)
	elseif actionName == "skill3" then
		return runAreaAbility(player, ability, ability.vfxColor)
	elseif actionName == "ultimate" then
		root.AssemblyLinearVelocity = root.CFrame.LookVector * 70 + Vector3.new(0, 32, 0)
		return runAreaAbility(player, ability, ability.vfxColor)
	end

	return 0
end

local function runSora(player, actionName, ability)
	local root = getRoot(player)
	if not root then
		return 0
	end

	if actionName == "skill1" then
		local targets = collectTargets(player, ability.range, ability.radius, true, true)
		for _, target in ipairs(targets) do
			markTarget(target, ability.markDuration or 3)
		end
		fireFeedback(player, { kind = "enemyRevealed", action = ability.displayName })
		return damageTargets(player, targets, ability.damage, 18)
	elseif actionName == "skill2" then
		local allies = collectAllies(player, ability.radius)
		local nonSelfAllies = {}
		for _, ally in ipairs(allies) do
			if ally.player ~= player then
				table.insert(nonSelfAllies, ally)
			end
		end
		table.sort(nonSelfAllies, function(a, b)
			return a.distance < b.distance
		end)
		local target = nonSelfAllies[1] or allies[1]
		if target then
			local applied = applyShieldToTarget(player, target, ability.shield or 0)
			spawnHitVisual(target.position, ability.vfxColor, 8, 0.45, "AR003SoraShield")
			fireFeedback(player, { kind = "allyShielded", action = ability.displayName, amount = applied })
		end
		return 0
	elseif actionName == "skill3" then
		local allies = collectAllies(player, ability.radius)
		table.sort(allies, function(a, b)
			return a.healthRatio < b.healthRatio
		end)
		local target = allies[1]
		if target then
			local healAmount = target.player == player and (ability.selfHeal or 10) or (ability.heal or 18)
			local applied = healTarget(player, target, healAmount)
			spawnHitVisual(target.position, ability.vfxColor, 8, 0.45, "AR003SoraHeal")
			fireFeedback(player, { kind = "allyHealed", action = ability.displayName, amount = applied })
		end
		return 0
	elseif actionName == "ultimate" then
		spawnDisk(root.Position - Vector3.new(0, 2.7, 0), ability.vfxColor, ability.radius or 22, ability.duration or 8, "AR003NovaSanctuary")
		task.spawn(function()
			local finishAt = os.clock() + (ability.duration or 8)
			while player.Parent and os.clock() <= finishAt do
				local allies = collectAllies(player, ability.radius or 22)
				for _, ally in ipairs(allies) do
					healTarget(player, ally, ability.heal or 4)
					applyShieldToTarget(player, ally, ability.shield or 3)
				end
				for _, target in ipairs(collectTargets(player, ability.radius or 22, ability.radius or 22, false, true)) do
					markTarget(target, 1.2)
				end
				task.wait(ability.pulseInterval or 1)
			end
		end)
		return 0
	end

	return 0
end

local function runAtlas(player, actionName, ability)
	local root = getRoot(player)
	if not root then
		return 0
	end

	if actionName == "skill1" then
		local targets = collectTargets(player, ability.range, ability.radius, true, true)
		for _, target in ipairs(targets) do
			pullTargetToward(root.Position, target, ability.pullStrength or 54)
		end
		spawnHitVisual(root.Position + root.CFrame.LookVector * 10, ability.vfxColor, 8, 0.28, "AR003PullPalm")
		fireFeedback(player, { kind = "pulled", action = ability.displayName })
		return damageTargets(player, targets, ability.damage, 8)
	elseif actionName == "skill2" then
		CharacterService.SetDamageReduction(player, ability.damageReduction or 0.35, ability.duration or 5)
		for _, ally in ipairs(collectAllies(player, ability.allyRadius or 14)) do
			if ally.kind == "player" and ally.player ~= player then
				CharacterService.SetDamageReduction(ally.player, ability.allyDamageReduction or 0.15, ability.duration or 5)
			elseif ally.kind == "bot" then
				BotService.SetDamageReduction(ally.bot, ability.allyDamageReduction or 0.15, ability.duration or 5)
			end
		end
		spawnHitVisual(root.Position, ability.vfxColor, 12, 0.55, "AR003OrbitGuard")
		fireFeedback(player, { kind = "damageReduced", action = ability.displayName })
		return 0
	elseif actionName == "skill3" then
		local targets = collectTargets(player, ability.radius, ability.radius, false, true)
		for _, target in ipairs(targets) do
			slowTarget(target, ability.slowMultiplier or 0.55, ability.slowDuration or 3)
		end
		spawnDisk(root.Position - Vector3.new(0, 2.7, 0), ability.vfxColor, ability.radius or 18, 0.55, "AR003HeavyStep")
		fireFeedback(player, { kind = "slowed", action = ability.displayName })
		return damageTargets(player, targets, ability.damage, 12)
	elseif actionName == "ultimate" then
		local center = root.Position + root.CFrame.LookVector * 16
		spawnDisk(center - Vector3.new(0, 2.7, 0), ability.vfxColor, ability.radius or 24, ability.windup or 1.2, "AR003BlackstarWarning")
		task.delay(ability.windup or 1.2, function()
			if not player.Parent then
				return
			end
			local targets = collectTargetsAroundPosition(player, center, ability.radius or 24, true)
			for _, target in ipairs(targets) do
				pullTargetToward(center, target, ability.pullStrength or 24)
			end
			spawnHitVisual(center, ability.vfxColor, ability.radius or 24, 0.5, "AR003BlackstarDrop")
			damageTargets(player, targets, ability.damage or 40, 16)
		end)
		return 0
	end

	return 0
end

local function getCooldownRemaining(player, actionName)
	return CooldownService.GetRemaining(player, actionName)
end

local function reserveAbility(player, actionName, ability)
	local remaining = getCooldownRemaining(player, actionName)
	if remaining > 0.05 then
		fireFeedback(player, { kind = "cooldown", action = actionName, remaining = remaining })
		return false
	end

	if ability.flowCost and not CharacterService.TrySpendFlow(player, ability.flowCost) then
		fireFeedback(player, { kind = "noFlow", action = ability.displayName })
		return false
	end

	CooldownService.TryUse(player, actionName, ability.cooldown or 3)
	return true
end

local function runAbility(player, actionName)
	local state = CharacterService.GetState(player)
	if not state or state.defeated then
		fireFeedback(player, { kind = "defeated", action = actionName })
		return
	end

	local definition = CharacterService.GetDefinition(player)
	if not definition then
		return
	end

	local ability = AbilityDefinitions.get(definition.id, actionName)
	if not ability then
		return
	end

	if not reserveAbility(player, actionName, ability) then
		return
	end

	local totalDamage = 0
	if actionName == GameConstants.Actions.Basic then
		runBasic(player, definition)
		CharacterService.SendState(player, {
			cooldowns = CooldownService.GetSnapshot(player),
		})
		return
	elseif definition.id == "kairo_soljin" then
		totalDamage = runKairo(player, actionName, ability)
	elseif definition.id == "mira_gale" then
		totalDamage = runMira(player, actionName, ability)
	elseif definition.id == "sora_nym" then
		totalDamage = runSora(player, actionName, ability)
	elseif definition.id == "atlas_null" then
		totalDamage = runAtlas(player, actionName, ability)
	end

	CharacterService.SendState(player, {
		cooldowns = CooldownService.GetSnapshot(player),
	})
	fireFeedback(player, {
		kind = actionName == GameConstants.Actions.Ultimate and "ultimate" or "ability",
		action = ability.displayName,
		amount = totalDamage,
	})
end

local function validateCombatRemote(player, actionName)
	if not allowedActions[actionName] then
		return false
	end

	local allowed, _, deniedCount = limiter:Allow(player.UserId)
	if not allowed then
		if deniedCount == 1 or deniedCount % 10 == 0 then
			warn(("[Aniverse Royale] Combat remote spam blocked for %s (%s)."):format(player.Name, actionName))
		end
		fireFeedback(player, { kind = "rateLimited", action = actionName })
		return false
	end

	return true
end

function CombatService.Start(dependencies)
	CharacterService = dependencies.CharacterService
	CooldownService = dependencies.CooldownService
	TeamService = dependencies.TeamService
	BotService = dependencies.BotService
	ArenaRoundService = dependencies.ArenaRoundService

	remotes.CombatAction = ensureRemote(GameConstants.Remotes.CombatAction)
	remotes.CombatFeedback = ensureRemote(GameConstants.Remotes.CombatFeedback)

	remotes.CombatAction.OnServerEvent:Connect(function(player, actionName)
		actionName = tostring(actionName or "")
		if not validateCombatRemote(player, actionName) then
			return
		end

		if actionName == GameConstants.Actions.BlockBegin then
			if CharacterService.SetBlocking(player, true) then
				fireFeedback(player, { kind = "guarded", action = actionName })
			end
		elseif actionName == GameConstants.Actions.BlockEnd then
			CharacterService.SetBlocking(player, false)
		else
			runAbility(player, actionName)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		limiter:Clear(player.UserId)
	end)

	refreshDummies()
	fireAll({ kind = "combatReady", action = "AR-003 combat online" })
end

function CombatService.Step()
	return true
end

return CombatService
