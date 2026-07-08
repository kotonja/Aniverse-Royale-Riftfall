local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityDefinitions = require(Shared.Config.AbilityDefinitions)

local AbilityService = {}

function AbilityService.Start()
	return true
end

function AbilityService.GetAbility(characterId, actionName)
	return AbilityDefinitions.get(characterId, actionName)
end

return AbilityService
