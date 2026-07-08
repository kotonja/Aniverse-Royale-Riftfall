local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared.Config.GameConstants)
local AbilityDefinitions = require(Shared.Config.AbilityDefinitions)
local RateLimiter = require(Shared.Utility.RateLimiter)

local CombatService = {}

local CharacterService = nil
local CooldownService = nil
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
		warn("[Aniverse Royale] DamageDummies folder missing. Apply blueprints/ar002/ar002_studio_foundation.blueprint.json.")
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

local function spawnHitVisual(position, color, radius, duration)
	local marker = Instance.new("Part")
	marker.Name = "AR002HitVisual"
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

	print(("[Aniverse Royale] %s dealt %d to %s (%d/%d)."):format(attacker.Name, finalDamage + absorbed, dummy.Name, current, maxHealth))

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

local function applyDamageToPlayer(attacker, targetPlayer, amount, knockback)
	if attacker == targetPlayer then
		return 0
	end

	local state = CharacterService.GetState(targetPlayer)
	if not state or state.health <= 0 then
		return 0
	end

	local finalDamage = amount
	if state.blocking and os.clock() >= state.blockBrokenUntil then
		finalDamage = math.floor(amount * GameConstants.Combat.BlockDamageMultiplier)
		state.guard = math.max(0, state.guard - amount * GameConstants.Combat.BlockGuardDamageMultiplier)

		if state.guard <= 0 then
			state.blocking = false
			state.blockBrokenUntil = os.clock() + GameConstants.Combat.BlockBreakLockout
			fireFeedback(targetPlayer, { kind = "blockBreak" })
		else
			fireFeedback(targetPlayer, { kind = "guarded", amount = finalDamage })
		end
	end

	if state.sunburstGuardUntil and os.clock() < state.sunburstGuardUntil then
		finalDamage = math.floor(finalDamage * 0.55)
	end

	local shieldDamage = math.min(state.shield, finalDamage)
	state.shield -= shieldDamage
	state.health = math.max(0, state.health - (finalDamage - shieldDamage))

	local root = getRoot(targetPlayer)
	if root and knockback then
		root.AssemblyLinearVelocity += knockback
	end

	CharacterService.SendState(targetPlayer)
	fireFeedback(targetPlayer, { kind = "tookDamage", amount = finalDamage })
	return finalDamage
end

local function collectTargets(attacker, range, radius, useCone)
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

	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		if targetPlayer ~= attacker then
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

local function damageTargets(attacker, targets, amount, knockbackScale)
	local root = getRoot(attacker)
	local forward = root and root.CFrame.LookVector or Vector3.new(0, 0, -1)
	local totalDamage = 0

	for _, target in ipairs(targets) do
		local dealt = 0
		if target.kind == "dummy" then
			dealt = applyDamageToDummy(attacker, target.dummy, amount)
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

local function runBasic(player, definition)
	local ability = AbilityDefinitions.get(definition.id, "basic")
	if not ability then
		return
	end

	local targets = collectTargets(player, ability.range, ability.radius, true)
	local totalDamage = damageTargets(player, targets, ability.damage, 24)
	fireFeedback(player, {
		kind = totalDamage > 0 and "hitConfirm" or "ability",
		action = ability.displayName,
		amount = totalDamage,
	})
end

local function runAreaAbility(player, ability, color)
	local root = getRoot(player)
	if not root then
		return
	end

	spawnHitVisual(root.Position, color, ability.radius or 12, 0.35)
	local targets = collectTargets(player, ability.radius or 16, ability.radius or 16, false)
	return damageTargets(player, targets, ability.damage or 0, 32)
end

local function runKairo(player, actionName, ability)
	local root = getRoot(player)
	if not root then
		return
	end

	if actionName == "skill1" then
		root.AssemblyLinearVelocity = root.CFrame.LookVector * 82 + Vector3.new(0, 10, 0)
		spawnHitVisual(root.Position + root.CFrame.LookVector * 8, Color3.fromRGB(255, 112, 44), 5, 0.22)
		return damageTargets(player, collectTargets(player, ability.range, ability.radius, true), ability.damage, 50)
	elseif actionName == "skill2" then
		local state = CharacterService.GetState(player)
		if state then
			state.sunburstGuardUntil = os.clock() + (ability.duration or 4)
			state.guard = math.min(state.maxGuard, state.guard + 20)
			CharacterService.SendState(player)
		end
		spawnHitVisual(root.Position, Color3.fromRGB(255, 205, 74), 9, 0.45)
		return 0
	elseif actionName == "skill3" then
		root.AssemblyLinearVelocity = root.CFrame.LookVector * 42 + Vector3.new(0, 64, 0)
		task.delay(0.28, function()
			if player.Parent then
				runAreaAbility(player, ability, Color3.fromRGB(255, 98, 52))
			end
		end)
		return 0
	elseif actionName == "ultimate" then
		return runAreaAbility(player, ability, Color3.fromRGB(255, 238, 128))
	end

	return 0
end

local function runMira(player, actionName, ability)
	local root = getRoot(player)
	if not root then
		return
	end

	if actionName == "skill1" then
		spawnHitVisual(root.Position + root.CFrame.LookVector * 15, Color3.fromRGB(155, 235, 255), 4, 0.28)
		return damageTargets(player, collectTargets(player, ability.range, ability.radius, true), ability.damage, 30)
	elseif actionName == "skill2" then
		root.AssemblyLinearVelocity = root.CFrame.LookVector * 96 + Vector3.new(0, 18, 0)
		spawnHitVisual(root.Position, Color3.fromRGB(184, 255, 232), 5, 0.2)
		return damageTargets(player, collectTargets(player, ability.range, ability.radius, true), ability.damage or 0, 26)
	elseif actionName == "skill3" then
		return runAreaAbility(player, ability, Color3.fromRGB(124, 216, 255))
	elseif actionName == "ultimate" then
		root.AssemblyLinearVelocity = root.CFrame.LookVector * 70 + Vector3.new(0, 32, 0)
		return runAreaAbility(player, ability, Color3.fromRGB(210, 250, 255))
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
end

function CombatService.Step()
	return true
end

return CombatService
