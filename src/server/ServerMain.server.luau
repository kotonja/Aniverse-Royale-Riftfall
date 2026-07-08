local RunService = game:GetService("RunService")

local Services = script.Parent:WaitForChild("Services")

local WorldBuilderService = require(Services:WaitForChild("WorldBuilderService"))
local CooldownService = require(Services:WaitForChild("CooldownService"))
local TeamService = require(Services:WaitForChild("TeamService"))
local CharacterService = require(Services:WaitForChild("CharacterService"))
local BotService = require(Services:WaitForChild("BotService"))
local ArenaRoundService = require(Services:WaitForChild("ArenaRoundService"))
local CombatService = require(Services:WaitForChild("CombatService"))
local AbilityService = require(Services:WaitForChild("AbilityService"))
local MovementValidationService = require(Services:WaitForChild("MovementValidationService"))
local MatchStateService = require(Services:WaitForChild("MatchStateService"))
local PlaceholderMatchmakingService = require(Services:WaitForChild("PlaceholderMatchmakingService"))
local PlaceholderLeaderboardService = require(Services:WaitForChild("PlaceholderLeaderboardService"))

WorldBuilderService.Start()
CooldownService.Start()
TeamService.Start()
CharacterService.Start({
	TeamService = TeamService,
})
BotService.Start()
ArenaRoundService.Start({
	TeamService = TeamService,
	CharacterService = CharacterService,
	CooldownService = CooldownService,
	BotService = BotService,
})
TeamService.SetArenaRoundService(ArenaRoundService)
CharacterService.SetArenaRoundService(ArenaRoundService)
AbilityService.Start()
CombatService.Start({
	CharacterService = CharacterService,
	CooldownService = CooldownService,
	TeamService = TeamService,
	BotService = BotService,
	ArenaRoundService = ArenaRoundService,
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
	ArenaRoundService.Step(deltaTime)
end)

print("[Aniverse Royale] AR-003 Four Character 3v3 Arena loaded.")
