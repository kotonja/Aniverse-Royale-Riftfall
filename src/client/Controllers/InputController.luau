local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local InputBindings = require(Shared.Config.InputBindings)

local InputController = {}

InputController.Keybinds = InputBindings.Keyboard

function InputController.GetAction(actionKey)
	return InputBindings.getAction(actionKey)
end

function InputController.HotbarOrder()
	return InputBindings.listHotbarOrder()
end

function InputController.Start()
	return true
end

return InputController
