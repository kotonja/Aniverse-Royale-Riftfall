local RunService = game:GetService("RunService")

local Services = script.Parent:WaitForChild("Services")

local WorldBuilderService = require(Services:WaitForChild("WorldBuilderService"))
local CooldownService = require(Services:WaitForChild("CooldownService"))
local CharacterService = require(Services:WaitForChild("CharacterService"))
local CombatService = require(Services:WaitForChild("CombatService"))
local AbilityService = require(Services:WaitForChild("AbilityService"))
local MovementValidationService = require(Services:WaitForChild("MovementValidationService"))
local MatchStateService = require(Services:WaitForChild("MatchStateService"))
local PlaceholderMatchmakingService = require(Services:WaitForChild("PlaceholderMatchmakingService"))
local PlaceholderLeaderboardService = require(Services:WaitForChild("PlaceholderLeaderboardService"))

WorldBuilderService.Start()
CooldownService.Start()
CharacterService.Start()
AbilityService.Start()
CombatService.Start({
	CharacterService = CharacterService,
	CooldownService = CooldownService,
})
MovementValidationService.Start({
	CharacterService = CharacterService,
	CooldownService = CooldownService,
})
MatchStateService.Start()
PlaceholderMatchmakingService.Start()
PlaceholderLeaderboardService.Start()

RunService.Heartbeat:Connect(function(deltaTime)
	CharacterService.Step(deltaTime)
	CombatService.Step(deltaTime)
end)

print("[Aniverse Royale] AR-002 Studio Foundation + Game Feel Polish loaded.")
