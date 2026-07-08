local GameConstants = require(script.Parent.GameConstants)

local CharacterDefinitions = {
	kairo_soljin = {
		id = "kairo_soljin",
		displayName = "Kairo Soljin",
		subtitle = "Solar Brawler",
		role = "Vanguard",
		aura = "Flame",
		baseStats = {
			health = 100,
			shield = 100,
			flow = 100,
			guard = 100,
			walkSpeed = GameConstants.Movement.BaseWalkSpeed,
			sprintSpeed = 22,
		},
		abilities = {
			basic = "Flame Combo",
			skill1 = "Ember Rush",
			skill2 = "Sunburst Guard",
			skill3 = "Meteor Step",
			ultimate = "Dawn Breaker",
		},
	},

	mira_gale = {
		id = "mira_gale",
		displayName = "Mira Gale",
		subtitle = "Sky Duelist",
		role = "Skirmisher",
		aura = "Gale",
		baseStats = {
			health = 90,
			shield = 100,
			flow = 110,
			guard = 90,
			walkSpeed = GameConstants.Movement.BaseWalkSpeed,
			sprintSpeed = 25,
		},
		abilities = {
			basic = "Wind Combo",
			skill1 = "Razor Arc",
			skill2 = "Wind Step",
			skill3 = "Cyclone Lift",
			ultimate = "Tempest Waltz",
		},
	},
}

CharacterDefinitions.DefaultId = "kairo_soljin"

function CharacterDefinitions.get(characterId)
	return CharacterDefinitions[characterId]
end

function CharacterDefinitions.exists(characterId)
	return CharacterDefinitions[characterId] ~= nil
end

function CharacterDefinitions.list()
	return {
		CharacterDefinitions.kairo_soljin,
		CharacterDefinitions.mira_gale,
	}
end

return CharacterDefinitions
