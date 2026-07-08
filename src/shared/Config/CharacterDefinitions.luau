local GameConstants = require(script.Parent.GameConstants)

local CharacterDefinitions = {
	kairo_soljin = {
		id = "kairo_soljin",
		displayName = "Kairo Soljin",
		subtitle = "Solar Brawler",
		role = "Vanguard",
		aura = "Flame",
		passive = "Solar Tempo",
		baseStats = {
			health = 100,
			shield = 100,
			flow = 100,
			guard = 100,
			walkSpeed = GameConstants.Movement.BaseWalkSpeed,
			sprintSpeed = 22,
			knockbackMultiplier = 1,
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
		passive = "Slipstream",
		baseStats = {
			health = 90,
			shield = 100,
			flow = 110,
			guard = 90,
			walkSpeed = GameConstants.Movement.BaseWalkSpeed,
			sprintSpeed = 25,
			knockbackMultiplier = 1,
		},
		abilities = {
			basic = "Wind Combo",
			skill1 = "Razor Arc",
			skill2 = "Wind Step",
			skill3 = "Cyclone Lift",
			ultimate = "Tempest Waltz",
		},
	},

	sora_nym = {
		id = "sora_nym",
		displayName = "Sora Nym",
		subtitle = "Star Medic",
		role = "Support",
		aura = "Light",
		passive = "Guiding Star",
		baseStats = {
			health = 95,
			shield = 105,
			flow = 100,
			guard = 90,
			walkSpeed = GameConstants.Movement.BaseWalkSpeed,
			sprintSpeed = 23,
			knockbackMultiplier = 1,
		},
		abilities = {
			basic = "Starlight Bolt Chain",
			skill1 = "Starlight Bolt",
			skill2 = "Constellation Shield",
			skill3 = "Star Mend",
			ultimate = "Nova Sanctuary",
		},
	},

	atlas_null = {
		id = "atlas_null",
		displayName = "Atlas Null",
		subtitle = "Gravity Monk",
		role = "Tank / Controller",
		aura = "Gravity",
		passive = "Heavy Center",
		baseStats = {
			health = 115,
			shield = 110,
			flow = 90,
			guard = 120,
			walkSpeed = 15,
			sprintSpeed = 20,
			knockbackMultiplier = 0.45,
		},
		abilities = {
			basic = "Gravity Palm Chain",
			skill1 = "Pull Palm",
			skill2 = "Orbit Guard",
			skill3 = "Heavy Step",
			ultimate = "Blackstar Drop",
		},
	},
}

CharacterDefinitions.DefaultId = "kairo_soljin"

local rosterOrder = {
	"kairo_soljin",
	"mira_gale",
	"sora_nym",
	"atlas_null",
}

function CharacterDefinitions.get(characterId)
	return CharacterDefinitions[characterId]
end

function CharacterDefinitions.exists(characterId)
	return CharacterDefinitions[characterId] ~= nil
end

function CharacterDefinitions.list()
	local list = {}
	for _, characterId in ipairs(rosterOrder) do
		table.insert(list, CharacterDefinitions[characterId])
	end
	return list
end

return CharacterDefinitions
