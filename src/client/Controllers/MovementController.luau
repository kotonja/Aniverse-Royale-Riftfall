local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared.Config.GameConstants)
local InputBindings = require(Shared.Config.InputBindings)
local MathUtil = require(Shared.Utility.MathUtil)

local CameraController = require(script.Parent.CameraController)

local player = Players.LocalPlayer
local movementAction = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild(GameConstants.Remotes.MovementAction)
local stateUpdate = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild(GameConstants.Remotes.StateUpdate)

local MovementController = {}

local latestStats = nil
local doubleJumpUsed = false
local lastDashAt = 0
local lastSlideAt = 0

local function getCharacterParts()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return character, humanoid, root
end

local function canSpend(amount)
	return not latestStats or not latestStats.flow or latestStats.flow >= amount
end

local function getDashDirection(humanoid, root)
	local camera = Workspace.CurrentCamera
	local direction = humanoid and humanoid.MoveDirection or Vector3.zero
	if direction.Magnitude < 0.1 and camera then
		direction = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
	end
	if direction.Magnitude < 0.1 and root then
		direction = root.CFrame.LookVector
	end
	return MathUtil.flatUnit(direction, Vector3.new(0, 0, -1))
end

local function applyLocalDash(isAirDash)
	local _, humanoid, root = getCharacterParts()
	if not humanoid or not root then
		return
	end

	local now = os.clock()
	if now - lastDashAt < 0.18 then
		return
	end
	lastDashAt = now

	local cost = isAirDash and GameConstants.Movement.AirDashFlowCost or GameConstants.Movement.DashFlowCost
	if not canSpend(cost) then
		movementAction:FireServer(isAirDash and GameConstants.Actions.AirDash or GameConstants.Actions.Dash)
		return
	end

	local direction = getDashDirection(humanoid, root)
	root.AssemblyLinearVelocity = direction * GameConstants.Movement.DashSpeed + Vector3.new(0, isAirDash and GameConstants.Movement.AirDashLift or 4, 0)
	movementAction:FireServer(isAirDash and GameConstants.Actions.AirDash or GameConstants.Actions.Dash)
	CameraController.PulseDash()
end

local function applyLocalSlide()
	local _, humanoid, root = getCharacterParts()
	if not humanoid or not root then
		return
	end

	local now = os.clock()
	if now - lastSlideAt < 0.25 then
		return
	end
	lastSlideAt = now

	if humanoid.FloorMaterial ~= Enum.Material.Air and canSpend(GameConstants.Movement.SlideFlowCost) then
		root.AssemblyLinearVelocity = getDashDirection(humanoid, root) * GameConstants.Movement.SlideSpeed + Vector3.new(0, 1, 0)
	end

	movementAction:FireServer(GameConstants.Actions.Slide)
end

local function raycastWall(root)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character }

	local directions = {
		root.CFrame.RightVector,
		-root.CFrame.RightVector,
		root.CFrame.LookVector,
		-root.CFrame.LookVector,
	}

	for _, direction in ipairs(directions) do
		local result = Workspace:Raycast(root.Position, direction * 4.25, params)
		if result and result.Instance and result.Instance.CanCollide then
			return result
		end
	end

	return nil
end

local function tryWallKick(humanoid, root)
	local result = raycastWall(root)
	if not result then
		return false
	end

	local normal = result.Normal
	local kick = MathUtil.flatUnit(normal, -root.CFrame.LookVector)
	root.AssemblyLinearVelocity = kick * GameConstants.Movement.WallKickHorizontalPower + Vector3.new(0, GameConstants.Movement.WallKickVerticalPower, 0)
	movementAction:FireServer(GameConstants.Actions.WallKick, {
		normal = normal,
	})
	CameraController.ShakeSmall()
	return true
end

local function bindCharacter(character)
	doubleJumpUsed = false
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then
		return
	end

	humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.Running then
			doubleJumpUsed = false
		end
	end)
end

local function getRootGui()
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	local hud = playerGui and playerGui:FindFirstChild(GameConstants.UI.HudName)
	return hud and hud:FindFirstChild(GameConstants.UI.RootName)
end

local function getHotbarButton(buttonName)
	local root = getRootGui()
	local hotbar = root and root:FindFirstChild(GameConstants.UI.AbilityHotbarName)
	return hotbar and hotbar:FindFirstChild(buttonName)
end

local function bindHotbarMovementButton(buttonName, callback)
	local button = getHotbarButton(buttonName)
	if button and button:IsA("TextButton") then
		button.Activated:Connect(callback)
	end
end

function MovementController.Start()
	stateUpdate.OnClientEvent:Connect(function(payload)
		latestStats = payload and payload.stats or latestStats
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		local _, humanoid = getCharacterParts()
		if input.KeyCode == InputBindings.Keyboard.Sprint then
			if humanoid then
				humanoid.WalkSpeed = GameConstants.Movement.BaseSprintSpeed
			end
			movementAction:FireServer(GameConstants.Actions.SprintBegin)
			CameraController.PulseSprint(true)
		elseif input.KeyCode == InputBindings.Keyboard.Dash then
			local isAirDash = humanoid and humanoid.FloorMaterial == Enum.Material.Air
			applyLocalDash(isAirDash)
		elseif input.KeyCode == InputBindings.Keyboard.Slide then
			applyLocalSlide()
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == InputBindings.Keyboard.Sprint then
			local _, humanoid = getCharacterParts()
			if humanoid then
				humanoid.WalkSpeed = GameConstants.Movement.BaseWalkSpeed
			end
			movementAction:FireServer(GameConstants.Actions.SprintEnd)
			CameraController.PulseSprint(false)
		end
	end)

	UserInputService.JumpRequest:Connect(function()
		local _, humanoid, root = getCharacterParts()
		if not humanoid or not root then
			return
		end

		if humanoid.FloorMaterial == Enum.Material.Air then
			if not doubleJumpUsed then
				doubleJumpUsed = true
				root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, GameConstants.Movement.DoubleJumpPower, root.AssemblyLinearVelocity.Z)
				movementAction:FireServer(GameConstants.Actions.DoubleJump)
				CameraController.ShakeSmall()
			else
				tryWallKick(humanoid, root)
			end
		end
	end)

	player.CharacterAdded:Connect(bindCharacter)
	if player.Character then
		bindCharacter(player.Character)
	end

	task.spawn(function()
		local playerGui = player:WaitForChild("PlayerGui")
		playerGui:WaitForChild(GameConstants.UI.HudName, 10)
		bindHotbarMovementButton("DashButton", function()
			local _, humanoid = getCharacterParts()
			local isAirDash = humanoid and humanoid.FloorMaterial == Enum.Material.Air
			applyLocalDash(isAirDash)
		end)
		bindHotbarMovementButton("SlideButton", applyLocalSlide)
	end)
end

return MovementController
