local GameConstants = {}

GameConstants.Milestone = "AR-003"

GameConstants.Stats = {
	MaxHealth = 100,
	MaxShield = 100,
	MaxFlow = 100,
	MaxGuard = 100,
}

GameConstants.Movement = {
	BaseWalkSpeed = 16,
	BaseSprintSpeed = 23,
	DashFlowCost = 25,
	AirDashFlowCost = 30,
	SlideFlowCost = 12,
	FlowRegenPerSecond = 12,
	GuardRegenPerSecond = 15,
	DashCooldown = 1.1,
	AirDashCooldown = 1.35,
	DoubleJumpCooldown = 0.25,
	WallKickCooldown = 0.7,
	DoubleJumpPower = 48,
	DashSpeed = 86,
	DashDuration = 0.16,
	AirDashLift = 18,
	SlideCooldown = 1.25,
	SlideSpeed = 58,
	WallKickHorizontalPower = 54,
	WallKickVerticalPower = 44,
	MaxRemoteDistanceFromDojo = 360,
	RemoteRateLimitCapacity = 18,
	RemoteRateLimitRefill = 9,
}

GameConstants.Combat = {
	BasicCooldown = 0.42,
	BlockDamageMultiplier = 0.35,
	BlockGuardDamageMultiplier = 0.75,
	BlockBreakLockout = 1.6,
	DummyMaxHealth = 250,
	DummyResetDelay = 1.6,
	TemporaryShieldCap = 45,
	RemoteRateLimitCapacity = 18,
	RemoteRateLimitRefill = 8,
}

GameConstants.SkillCooldownDefaults = {
	Skill1 = 5,
	Skill2 = 8,
	Skill3 = 10,
	Ultimate = 28,
}

GameConstants.Match = {
	TeamSizeTarget = 3,
	FutureTargetPlayers = 30,
	ModeName = "Squad Royale",
	SandboxState = "TrainingDojo",
	ArenaModeName = "AR-003 Arena Test",
}

GameConstants.Arena = {
	CountdownSeconds = 5,
	ResetSeconds = 8,
	MinimumCombatantsPerTeam = 1,
	BotFillEnabled = true,
}

GameConstants.Remotes = {
	RequestCharacterChange = "RequestCharacterChange",
	RequestTeamChange = "RequestTeamChange",
	RequestArenaStart = "RequestArenaStart",
	CombatAction = "CombatAction",
	MovementAction = "MovementAction",
	StateUpdate = "StateUpdate",
	CombatFeedback = "CombatFeedback",
	ArenaStateUpdate = "ArenaStateUpdate",
	TeamStateUpdate = "TeamStateUpdate",
	BotStateUpdate = "BotStateUpdate",
}

GameConstants.Actions = {
	Basic = "basic",
	BlockBegin = "blockBegin",
	BlockEnd = "blockEnd",
	Skill1 = "skill1",
	Skill2 = "skill2",
	Skill3 = "skill3",
	Ultimate = "ultimate",
	Dash = "dash",
	AirDash = "airDash",
	SprintBegin = "sprintBegin",
	SprintEnd = "sprintEnd",
	Slide = "slide",
	DoubleJump = "doubleJump",
	WallKick = "wallKick",
}

GameConstants.World = {
	RootName = "AniverseRiftfall",
	TrainingDojoName = "TrainingDojo",
	Arena3v3Name = "Arena3v3",
	SpawnAreaName = "SpawnArea",
	CombatArenaName = "CombatArena",
	MovementCourseName = "MovementCourse",
	CharacterPadFolderName = "CharacterPads",
	DummyFolderName = "DamageDummies",
	Tags = {
		DamageDummy = "AR_DamageDummy",
		CharacterPad = "AR_CharacterPad",
		MovementGate = "AR_MovementGate",
		TrainingSign = "AR_TrainingSign",
		Arena3v3 = "AR_Arena3v3",
		TeamPad = "AR_TeamPad",
		ArenaStartPad = "AR_ArenaStartPad",
		ArenaSpawn = "AR_ArenaSpawn",
		ArenaBotSpawn = "AR_ArenaBotSpawn",
		ArenaBoundary = "AR_ArenaBoundary",
		ArenaBot = "AR_ArenaBot",
	},
}

GameConstants.UI = {
	HudName = "AniverseHUD",
	RootName = "Root",
	TopBarName = "TopBar",
	BottomBarsName = "BottomBars",
	AbilityHotbarName = "AbilityHotbar",
	CharacterPanelName = "CharacterPanel",
	FeedbackLayerName = "FeedbackLayer",
	MobileButtonsName = "MobileButtons",
	DebugPanelName = "DebugPanel",
	TeamPanelName = "TeamPanel",
	ArenaPanelName = "ArenaPanel",
}

return GameConstants
