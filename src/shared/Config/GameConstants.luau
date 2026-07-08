local GameConstants = {}

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
	FlowRegenPerSecond = 12,
	GuardRegenPerSecond = 15,
	DashCooldown = 1.1,
	AirDashCooldown = 1.35,
	DoubleJumpPower = 48,
	DashSpeed = 86,
	DashDuration = 0.16,
	SlideCooldown = 1.25,
}

GameConstants.Combat = {
	BasicCooldown = 0.42,
	BlockDamageMultiplier = 0.35,
	BlockGuardDamageMultiplier = 0.75,
	BlockBreakLockout = 1.6,
	DummyMaxHealth = 250,
	DummyResetDelay = 1.6,
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
}

GameConstants.Remotes = {
	RequestCharacterChange = "RequestCharacterChange",
	CombatAction = "CombatAction",
	MovementAction = "MovementAction",
	StateUpdate = "StateUpdate",
	CombatFeedback = "CombatFeedback",
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
}

GameConstants.World = {
	RootName = "AniverseRiftfall",
	TrainingDojoName = "TrainingDojo",
	DummyFolderName = "DamageDummies",
}

return GameConstants
