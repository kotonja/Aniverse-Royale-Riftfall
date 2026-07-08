local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared.Config.GameConstants)
local AbilityDefinitions = require(Shared.Config.AbilityDefinitions)

local CombatService = {}

local CharacterService = nil
local CooldownService = nil
local remotes = {}
local dummyModels = {}

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
		label.Text = "Damage Dummy\n" .. tostring(math.floor(health)) .. "/" .. tostring(math.floor(maxHealth))
	end
end

local function refreshDummies()
	table.clear(dummyModels)

	local worldRoot = Workspace:FindFirstChild(GameConstants.World.RootName)
	local dojo = worldRoot and worldRoot:FindFirstChild(GameConstants.World.TrainingDojoName)
	local folder = dojo and dojo:FindFirstChild(GameConstants.World.DummyFolderName)
	if not folder then
		warn("[Aniverse Royale] DamageDummies folder missing. Run the AR-001 blueprint.")
		return
	end

	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("Model") then
			child:SetAttribute("IsDamageDummy", true)
			child:SetAttribute("MaxHealth", child:GetAttribute("MaxHealth") or GameConstants.Combat.DummyMaxHealth)
			child:SetAttribute("CurrentHealth", child:GetAttribute("CurrentHealth") or child:GetAttribute("MaxHealth"))
			table.insert(dummyModels, child)
			updateDummyBillboard(child)
		end
	end
end

local function fireFeedback(player, payload)
	if remotes.CombatFeedback then
		remotes.CombatFeedback:FireClient(player, payload)
	end
end

local function spawnHitVisual(position, color, radius, duration)
	local marker = Instance.new("Part")
	marker.Name = "AR001HitVisual"
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
	local current = dummy:GetAttribute("CurrentHealth") or GameConstants.Combat.DummyMaxHealth
	local maxHealth = dummy:GetAttribute("MaxHealth") or GameConstants.Combat.DummyMaxHealth
	current = math.max(0, current - amount)
	dummy:SetAttribute("CurrentHealth", current)
	updateDummyBillboard(dummy)

	print(("[Aniverse Royale] %s dealt %d to %s (%d/%d)"):format(attacker.Name, amount, dummy.Name, current, maxHealth))

	if current <= 0 and not dummy:GetAttribute("ResetPending") then
		dummy:SetAttribute("ResetPending", true)
		task.delay(GameConstants.Combat.DummyResetDelay, function()
			if dummy.Parent then
				dummy:SetAttribute("CurrentHealth", maxHealth)
				dummy:SetAttribute("ResetPending", false)
				updateDummyBillboard(dummy)
			end
		end)
	end
end

local function applyDamageToPlayer(attacker, targetPlayer, amount, knockback)
	if attacker == targetPlayer then
		return
	end

	local state = CharacterService.GetState(targetPlayer)
	if not state or state.health <= 0 then
		return
	end

	local finalDamage = amount
	if state.blocking and os.clock() >= state.blockBrokenUntil then
		finalDamage = math.floor(amount * GameConstants.Combat.BlockDamageMultiplier)
		state.guard = math.max(0, state.guard - amount * GameConstants.Combat.BlockGuardDamageMultiplier)

		if state.guard <= 0 then
			state.blocking = false
			state.blockBrokenUntil = os.clock() + GameConstants.Combat.BlockBreakLockout
			fireFeedback(targetPlayer, { kind = "blockBreak" })
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
	fireFeedback(attacker, { kind = "dealtDamage", amount = finalDamage, target = targetPlayer.Name })
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

	for _, target in ipairs(targets) do
		if target.kind == "dummy" then
			applyDamageToDummy(attacker, target.dummy, amount)
		elseif target.kind == "player" then
			applyDamageToPlayer(attacker, target.player, amount, forward * (knockbackScale or 20))
		end

		if target.position then
			spawnHitVisual(target.position + Vector3.new(0, 2, 0), Color3.fromRGB(255, 215, 80), 3, 0.2)
		end
	end
end

local function runBasic(player, definition)
	local ability = AbilityDefinitions.get(definition.id, "basic")
	if not ability then
		return
	end

	local ok, remaining = CooldownService.TryUse(player, "basic", ability.cooldown)
	if not ok then
		fireFeedback(player, { kind = "cooldown", action = "basic", remaining = remaining })
		return
	end

	local targets = collectTargets(player, ability.range, ability.radius, true)
	damageTargets(player, targets, ability.damage, 24)
	fireFeedback(player, { kind = "ability", action = ability.displayName })
end

local function runAreaAbility(player, ability, color)
	local root = getRoot(player)
	if not root then
		return
	end

	spawnHitVisual(root.Position, color, ability.radius or 12, 0.35)
	local targets = collectTargets(player, ability.radius or 16, ability.radius or 16, false)
	damageTargets(player, targets, ability.damage or 0, 32)
end

local function runKairo(player, actionName, ability)
	local root = getRoot(player)
	if not root then
		return
	end

	if actionName == "skill1" then
		if ability.flowCost and not CharacterService.TrySpendFlow(player, ability.flowCost) then
			fireFeedback(player, { kind = "noFlow", action = ability.displayName })
			return
		end
		root.AssemblyLinearVelocity = root.CFrame.LookVector * 82 + Vector3.new(0, 10, 0)
		spawnHitVisual(root.Position + root.CFrame.LookVector * 8, Color3.fromRGB(255, 112, 44), 5, 0.22)
		damageTargets(player, collectTargets(player, ability.range, ability.radius, true), ability.damage, 50)
	elseif actionName == "skill2" then
		local state = CharacterService.GetState(player)
		if state then
			state.sunburstGuardUntil = os.clock() + (ability.duration or 4)
			state.guard = math.min(state.maxGuard, state.guard + 20)
			CharacterService.SendState(player)
		end
		spawnHitVisual(root.Position, Color3.fromRGB(255, 205, 74), 9, 0.45)
	elseif actionName == "skill3" then
		if ability.flowCost and not CharacterService.TrySpendFlow(player, ability.flowCost) then
			fireFeedback(player, { kind = "noFlow", action = ability.displayName })
			return
		end
		root.AssemblyLinearVelocity = root.CFrame.LookVector * 42 + Vector3.new(0, 64, 0)
		task.delay(0.28, function()
			if player.Parent then
				runAreaAbility(player, ability, Color3.fromRGB(255, 98, 52))
			end
		end)
	elseif actionName == "ultimate" then
		runAreaAbility(player, ability, Color3.fromRGB(255, 238, 128))
	end
end

local function runMira(player, actionName, ability)
	local root = getRoot(player)
	if not root then
		return
	end

	if actionName == "skill1" then
		spawnHitVisual(root.Position + root.CFrame.LookVector * 15, Color3.fromRGB(155, 235, 255), 4, 0.28)
		damageTargets(player, collectTargets(player, ability.range, ability.radius, true), ability.damage, 30)
	elseif actionName == "skill2" then
		if ability.flowCost and not CharacterService.TrySpendFlow(player, ability.flowCost) then
			fireFeedback(player, { kind = "noFlow", action = ability.displayName })
			return
		end
		root.AssemblyLinearVelocity = root.CFrame.LookVector * 96 + Vector3.new(0, 18, 0)
		spawnHitVisual(root.Position, Color3.fromRGB(184, 255, 232), 5, 0.2)
		damageTargets(player, collectTargets(player, ability.range, ability.radius, true), ability.damage or 0, 26)
	elseif actionName == "skill3" then
		runAreaAbility(player, ability, Color3.fromRGB(124, 216, 255))
	elseif actionName == "ultimate" then
		root.AssemblyLinearVelocity = root.CFrame.LookVector * 70 + Vector3.new(0, 32, 0)
		runAreaAbility(player, ability, Color3.fromRGB(210, 250, 255))
	end
end

local function runAbility(player, actionName)
	local definition = CharacterService.GetDefinition(player)
	if not definition then
		return
	end

	if actionName == GameConstants.Actions.Basic then
		runBasic(player, definition)
		return
	end

	local ability = AbilityDefinitions.get(definition.id, actionName)
	if not ability then
		return
	end

	local ok, remaining = CooldownService.TryUse(player, actionName, ability.cooldown or 3)
	if not ok then
		fireFeedback(player, { kind = "cooldown", action = actionName, remaining = remaining })
		return
	end

	if definition.id == "kairo_soljin" then
		runKairo(player, actionName, ability)
	elseif definition.id == "mira_gale" then
		runMira(player, actionName, ability)
	end

	CharacterService.SendState(player, {
		cooldowns = CooldownService.GetSnapshot(player),
	})
	fireFeedback(player, { kind = "ability", action = ability.displayName })
end

local function handleMovement(player, actionName)
	local root = getRoot(player)
	if not root then
		return
	end

	if actionName == GameConstants.Actions.Dash or actionName == GameConstants.Actions.AirDash then
		local isAirDash = actionName == GameConstants.Actions.AirDash
		local flowCost = isAirDash and GameConstants.Movement.AirDashFlowCost or GameConstants.Movement.DashFlowCost
		local cooldown = isAirDash and GameConstants.Movement.AirDashCooldown or GameConstants.Movement.DashCooldown
		local ok, remaining = CooldownService.TryUse(player, actionName, cooldown)

		if not ok then
			fireFeedback(player, { kind = "cooldown", action = actionName, remaining = remaining })
			return
		end

		if not CharacterService.TrySpendFlow(player, flowCost) then
			fireFeedback(player, { kind = "noFlow", action = actionName })
			return
		end

		root.AssemblyLinearVelocity = root.CFrame.LookVector * GameConstants.Movement.DashSpeed + Vector3.new(0, isAirDash and 18 or 4, 0)
		fireFeedback(player, { kind = "movement", action = actionName })
	elseif actionName == GameConstants.Actions.Slide then
		local ok = CooldownService.TryUse(player, actionName, GameConstants.Movement.SlideCooldown)
		if ok then
			root.AssemblyLinearVelocity = root.CFrame.LookVector * 58
			fireFeedback(player, { kind = "movement", action = actionName })
		end
	end
end

function CombatService.Start(dependencies)
	CharacterService = dependencies.CharacterService
	CooldownService = dependencies.CooldownService

	remotes.CombatAction = ensureRemote(GameConstants.Remotes.CombatAction)
	remotes.MovementAction = ensureRemote(GameConstants.Remotes.MovementAction)
	remotes.CombatFeedback = ensureRemote(GameConstants.Remotes.CombatFeedback)

	remotes.CombatAction.OnServerEvent:Connect(function(player, actionName)
		actionName = tostring(actionName or "")
		if actionName == GameConstants.Actions.BlockBegin then
			CharacterService.SetBlocking(player, true)
		elseif actionName == GameConstants.Actions.BlockEnd then
			CharacterService.SetBlocking(player, false)
		else
			runAbility(player, actionName)
		end
	end)

	remotes.MovementAction.OnServerEvent:Connect(function(player, actionName)
		handleMovement(player, tostring(actionName or ""))
	end)

	refreshDummies()
end

function CombatService.Step()
	return true
end

return CombatService
