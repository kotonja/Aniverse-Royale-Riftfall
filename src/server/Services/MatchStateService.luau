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

local currentState = "TrainingSandbox"

function MatchStateService.Start()
	currentState = "TrainingSandbox"
	print("[Aniverse Royale] MatchStateService running in sandbox mode.")
end

function MatchStateService.GetState()
	return currentState
end

return MatchStateService
