local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared.Config.GameConstants)

local player = Players.LocalPlayer
local movementAction = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild(GameConstants.Remotes.MovementAction)
local stateUpdate = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild(GameConstants.Remotes.StateUpdate)

local MovementController = {}

local latestStats = nil
local doubleJumpUsed = false
local lastDashAt = 0

local function getCharacterParts()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return character, humanoid, root
end

local function getDashDirection(humanoid)
	local camera = Workspace.CurrentCamera
	local direction = humanoid and humanoid.MoveDirection or Vector3.zero
	if direction.Magnitude < 0.1 and camera then
		direction = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
	end
	if direction.Magnitude < 0.1 then
		direction = Vector3.new(0, 0, -1)
	end
	return direction.Unit
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
	if latestStats and latestStats.flow and latestStats.flow < cost then
		return
	end

	local direction = getDashDirection(humanoid)
	root.AssemblyLinearVelocity = direction * GameConstants.Movement.DashSpeed + Vector3.new(0, isAirDash and 18 or 4, 0)
	movementAction:FireServer(isAirDash and GameConstants.Actions.AirDash or GameConstants.Actions.Dash)
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

local function getMobileButton(buttonName)
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	local hud = playerGui and playerGui:FindFirstChild("AniverseHUD")
	local root = hud and hud:FindFirstChild("Root")
	local mobile = root and root:FindFirstChild("MobileButtons")
	return mobile and mobile:FindFirstChild(buttonName)
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
		if input.KeyCode == Enum.KeyCode.LeftShift then
			if humanoid then
				humanoid.WalkSpeed = GameConstants.Movement.BaseSprintSpeed
			end
			movementAction:FireServer(GameConstants.Actions.SprintBegin)
		elseif input.KeyCode == Enum.KeyCode.LeftAlt then
			local isAirDash = humanoid and humanoid.FloorMaterial == Enum.Material.Air
			applyLocalDash(isAirDash)
		elseif input.KeyCode == Enum.KeyCode.C then
			local _, _, root = getCharacterParts()
			if root then
				root.AssemblyLinearVelocity = root.CFrame.LookVector * 58
			end
			movementAction:FireServer(GameConstants.Actions.Slide)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftShift then
			local _, humanoid = getCharacterParts()
			if humanoid then
				humanoid.WalkSpeed = GameConstants.Movement.BaseWalkSpeed
			end
			movementAction:FireServer(GameConstants.Actions.SprintEnd)
		end
	end)

	UserInputService.JumpRequest:Connect(function()
		local _, humanoid, root = getCharacterParts()
		if not humanoid or not root then
			return
		end

		if humanoid.FloorMaterial == Enum.Material.Air and not doubleJumpUsed then
			doubleJumpUsed = true
			root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, GameConstants.Movement.DoubleJumpPower, root.AssemblyLinearVelocity.Z)
		end
	end)

	player.CharacterAdded:Connect(bindCharacter)
	if player.Character then
		bindCharacter(player.Character)
	end

	task.spawn(function()
		local playerGui = player:WaitForChild("PlayerGui")
		playerGui:WaitForChild("AniverseHUD", 10)
		local dashButton = getMobileButton("DashButton")
		if dashButton and dashButton:IsA("TextButton") then
			dashButton.Activated:Connect(function()
				local _, humanoid = getCharacterParts()
				local isAirDash = humanoid and humanoid.FloorMaterial == Enum.Material.Air
				applyLocalDash(isAirDash)
			end)
		end
	end)
end

return MovementController
