local ArenaConstants = {}

ArenaConstants.States = {
	Idle = "Idle",
	Countdown = "Countdown",
	Active = "Active",
	RoundOver = "RoundOver",
	Resetting = "Resetting",
}

ArenaConstants.CountdownSeconds = 5
ArenaConstants.ResetSeconds = 8

ArenaConstants.World = {
	ArenaFloor = "ArenaFloor",
	SunSpawnPoints = "SunSpawnPoints",
	MoonSpawnPoints = "MoonSpawnPoints",
	TeamPads = "TeamPads",
	StartRoundPad = "StartRoundPad",
	SpectatorPlatform = "SpectatorPlatform",
	ArenaBoundaries = "ArenaBoundaries",
	Cover = "Cover",
	VerticalPlatforms = "VerticalPlatforms",
	BotSpawnPoints = "BotSpawnPoints",
	ArenaBots = "ArenaBots",
	ArenaSigns = "ArenaSigns",
	DebugMarkers = "DebugMarkers",
}

ArenaConstants.BotHealth = 120
ArenaConstants.BotShield = 50
ArenaConstants.BotRespawnYOffset = 5

return ArenaConstants
