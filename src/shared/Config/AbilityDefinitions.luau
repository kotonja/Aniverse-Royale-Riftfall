local AbilityDefinitions = {
	kairo_soljin = {
		basic = {
			displayName = "Flame Combo",
			damage = 12,
			range = 8,
			radius = 5,
			cooldown = 0.42,
		},
		skill1 = {
			displayName = "Ember Rush",
			damage = 22,
			range = 18,
			radius = 6,
			cooldown = 5,
			flowCost = 10,
		},
		skill2 = {
			displayName = "Sunburst Guard",
			damage = 0,
			duration = 4,
			cooldown = 8,
		},
		skill3 = {
			displayName = "Meteor Step",
			damage = 28,
			range = 18,
			radius = 14,
			cooldown = 10,
			flowCost = 20,
		},
		ultimate = {
			displayName = "Dawn Breaker",
			damage = 42,
			radius = 24,
			cooldown = 28,
		},
	},

	mira_gale = {
		basic = {
			displayName = "Wind Combo",
			damage = 10,
			range = 9,
			radius = 5,
			cooldown = 0.36,
		},
		skill1 = {
			displayName = "Razor Arc",
			damage = 18,
			range = 36,
			radius = 5,
			cooldown = 5,
		},
		skill2 = {
			displayName = "Wind Step",
			damage = 6,
			range = 22,
			radius = 5,
			cooldown = 7,
			flowCost = 18,
		},
		skill3 = {
			displayName = "Cyclone Lift",
			damage = 20,
			radius = 16,
			cooldown = 10,
		},
		ultimate = {
			displayName = "Tempest Waltz",
			damage = 36,
			radius = 22,
			cooldown = 28,
		},
	},
}

function AbilityDefinitions.get(characterId, actionName)
	local characterAbilities = AbilityDefinitions[characterId]
	if not characterAbilities then
		return nil
	end
	return characterAbilities[actionName]
end

return AbilityDefinitions
