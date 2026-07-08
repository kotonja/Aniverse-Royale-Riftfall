-- Lightweight network contract notes for AR-002.
-- Client requests are intents only. The server owns stats, damage, cooldowns,
-- selected character state, and Flow/Guard spending.

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

	ServerOwned = {
		"health",
		"shield",
		"flow",
		"guard",
		"cooldowns",
		"damage",
		"characterSelection",
	},
}
