-- Lightweight network contract notes for AR-003.
-- Client requests are intents only. The server owns teams, round state, stats,
-- damage, cooldowns, selected character state, bot health, and Flow/Guard.

return {
	CombatActions = {
		"basic",
		"blockBegin",
		"blockEnd",
		"skill1",
		"skill2",
		"skill3",
		"ultimate",
	},

	MovementActions = {
		"sprintBegin",
		"sprintEnd",
		"dash",
		"airDash",
		"slide",
		"doubleJump",
		"wallKick",
	},

	TeamActions = {
		"sun",
		"moon",
		"spectator",
	},

	ArenaStates = {
		"Idle",
		"Countdown",
		"Active",
		"RoundOver",
		"Resetting",
	},

	ServerOwned = {
		"arenaState",
		"botHealth",
		"characterSelection",
		"cooldowns",
		"damage",
		"flow",
		"guard",
		"health",
		"roundWinner",
		"shield",
		"teamAssignment",
	},
}
