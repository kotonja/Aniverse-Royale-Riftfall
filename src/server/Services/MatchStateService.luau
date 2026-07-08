local MatchStateService = {}

MatchStateService.States = {
	Lobby = "Lobby",
	Queueing = "Queueing",
	LoadingMatch = "LoadingMatch",
	DropDeck = "DropDeck",
	Dropping = "Dropping",
	Active = "Active",
	RespawnDisabled = "RespawnDisabled",
	Endgame = "Endgame",
	Results = "Results",
}

local currentState = "AR003ArenaTest"

function MatchStateService.Start()
	currentState = "AR003ArenaTest"
	print("[Aniverse Royale] MatchStateService running in AR-003 arena test mode.")
end

function MatchStateService.GetState()
	return currentState
end

return MatchStateService
