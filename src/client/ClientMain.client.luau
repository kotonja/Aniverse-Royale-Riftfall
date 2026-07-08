local Controllers = script.Parent:WaitForChild("Controllers")

local InputController = require(Controllers:WaitForChild("InputController"))
local MovementController = require(Controllers:WaitForChild("MovementController"))
local CameraController = require(Controllers:WaitForChild("CameraController"))
local HUDController = require(Controllers:WaitForChild("HUDController"))
local CharacterSelectController = require(Controllers:WaitForChild("CharacterSelectController"))
local CombatController = require(Controllers:WaitForChild("CombatController"))

HUDController.Start()
InputController.Start()
MovementController.Start()
CameraController.Start()
CharacterSelectController.Start()
CombatController.Start()

print("[Aniverse Royale] Client controllers loaded.")
