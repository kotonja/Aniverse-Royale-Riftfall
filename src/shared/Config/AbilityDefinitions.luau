local AbilityDefinitions = {
	kairo_soljin = {
		basic = {
			id = "kairo_basic",
			displayName = "Flame Combo",
			action = "basic",
			damage = 12,
			guardDamage = 12,
			range = 8,
			radius = 5,
			cooldown = 0.42,
			vfxColor = Color3.fromRGB(255, 132, 56),
			description = "Short solar brawler chain.",
		},
		skill1 = {
			id = "kairo_ember_rush",
			displayName = "Ember Rush",
			action = "skill1",
			damage = 22,
			guardDamage = 18,
			range = 18,
			radius = 6,
			cooldown = 5,
			flowCost = 10,
			vfxColor = Color3.fromRGB(255, 112, 44),
			description = "Forward Aura Art rush with a bright hit confirm.",
		},
		skill2 = {
			id = "kairo_sunburst_guard",
			displayName = "Sunburst Guard",
			action = "skill2",
			damage = 0,
			duration = 4,
			cooldown = 8,
			damageReduction = 0.45,
			vfxColor = Color3.fromRGB(255, 205, 74),
			description = "Temporary guard enhancer for brawler trades.",
		},
		skill3 = {
			id = "kairo_meteor_step",
			displayName = "Meteor Step",
			action = "skill3",
			damage = 28,
			guardDamage = 22,
			range = 18,
			radius = 14,
			cooldown = 10,
			flowCost = 20,
			vfxColor = Color3.fromRGB(255, 98, 52),
			description = "Leap and slam into a readable area hit.",
		},
		ultimate = {
			id = "kairo_dawn_breaker",
			displayName = "Dawn Breaker",
			action = "ultimate",
			damage = 42,
			guardDamage = 30,
			radius = 24,
			cooldown = 28,
			vfxColor = Color3.fromRGB(255, 238, 128),
			description = "Large solar area burst.",
		},
	},

	mira_gale = {
		basic = {
			id = "mira_basic",
			displayName = "Wind Combo",
			action = "basic",
			damage = 10,
			guardDamage = 8,
			range = 9,
			radius = 5,
			cooldown = 0.36,
			vfxColor = Color3.fromRGB(155, 235, 255),
			description = "Fast light melee chain.",
		},
		skill1 = {
			id = "mira_razor_arc",
			displayName = "Razor Arc",
			action = "skill1",
			damage = 18,
			guardDamage = 13,
			range = 36,
			radius = 5,
			cooldown = 5,
			vfxColor = Color3.fromRGB(155, 235, 255),
			description = "Mid-range wind slash.",
		},
		skill2 = {
			id = "mira_wind_step",
			displayName = "Wind Step",
			action = "skill2",
			damage = 6,
			guardDamage = 6,
			range = 22,
			radius = 5,
			cooldown = 7,
			flowCost = 18,
			vfxColor = Color3.fromRGB(184, 255, 232),
			description = "Mobility dash that can clip enemies.",
		},
		skill3 = {
			id = "mira_cyclone_lift",
			displayName = "Cyclone Lift",
			action = "skill3",
			damage = 20,
			guardDamage = 16,
			radius = 16,
			cooldown = 10,
			vfxColor = Color3.fromRGB(124, 216, 255),
			description = "Small area lift and damage pulse.",
		},
		ultimate = {
			id = "mira_tempest_waltz",
			displayName = "Tempest Waltz",
			action = "ultimate",
			damage = 36,
			guardDamage = 24,
			radius = 22,
			cooldown = 28,
			vfxColor = Color3.fromRGB(210, 250, 255),
			description = "Fast storm burst with a movement pop.",
		},
	},

	sora_nym = {
		basic = {
			id = "sora_basic",
			displayName = "Starlight Bolt Chain",
			action = "basic",
			damage = 9,
			guardDamage = 7,
			range = 32,
			radius = 5,
			cooldown = 0.5,
			vfxColor = Color3.fromRGB(255, 232, 154),
			description = "Reliable light poke for a support Riftborn.",
		},
		skill1 = {
			id = "sora_starlight_bolt",
			displayName = "Starlight Bolt",
			action = "skill1",
			damage = 16,
			guardDamage = 10,
			range = 45,
			radius = 6,
			cooldown = 5,
			markDuration = 3,
			status = "LightMarked",
			vfxColor = Color3.fromRGB(255, 244, 188),
			description = "Fast light bolt that briefly marks enemies.",
		},
		skill2 = {
			id = "sora_constellation_shield",
			displayName = "Constellation Shield",
			action = "skill2",
			shield = 25,
			radius = 28,
			cooldown = 9,
			flowCost = 8,
			status = "TemporaryShield",
			vfxColor = Color3.fromRGB(255, 226, 128),
			description = "Shields the closest ally nearby, or self if no ally is valid.",
		},
		skill3 = {
			id = "sora_star_mend",
			displayName = "Star Mend",
			action = "skill3",
			heal = 18,
			selfHeal = 10,
			radius = 25,
			cooldown = 11,
			flowCost = 10,
			vfxColor = Color3.fromRGB(192, 255, 188),
			description = "Heals the lowest-health nearby ally. Future AR-004 revive beam hook.",
		},
		ultimate = {
			id = "sora_nova_sanctuary",
			displayName = "Nova Sanctuary",
			action = "ultimate",
			duration = 8,
			pulseInterval = 1,
			heal = 4,
			shield = 3,
			radius = 22,
			cooldown = 30,
			status = "Revealed",
			vfxColor = Color3.fromRGB(255, 244, 188),
			description = "Short star field that pulses healing and shield to allies.",
		},
	},

	atlas_null = {
		basic = {
			id = "atlas_basic",
			displayName = "Gravity Palm Chain",
			action = "basic",
			damage = 13,
			guardDamage = 18,
			range = 8,
			radius = 6,
			cooldown = 0.58,
			pullStrength = 14,
			vfxColor = Color3.fromRGB(114, 78, 196),
			description = "Heavy palm chain with strong guard pressure.",
		},
		skill1 = {
			id = "atlas_pull_palm",
			displayName = "Pull Palm",
			action = "skill1",
			damage = 14,
			guardDamage = 12,
			range = 32,
			radius = 9,
			cooldown = 7,
			pullStrength = 54,
			vfxColor = Color3.fromRGB(120, 82, 220),
			description = "Gravity pulse that pulls enemies toward Atlas.",
		},
		skill2 = {
			id = "atlas_orbit_guard",
			displayName = "Orbit Guard",
			action = "skill2",
			duration = 5,
			cooldown = 12,
			damageReduction = 0.35,
			allyDamageReduction = 0.15,
			allyRadius = 14,
			vfxColor = Color3.fromRGB(92, 76, 144),
			description = "Gravity guard for Atlas, with weaker nearby ally protection.",
		},
		skill3 = {
			id = "atlas_heavy_step",
			displayName = "Heavy Step",
			action = "skill3",
			damage = 18,
			guardDamage = 18,
			radius = 18,
			cooldown = 11,
			slowDuration = 3,
			slowMultiplier = 0.55,
			status = "Slowed",
			vfxColor = Color3.fromRGB(80, 74, 160),
			description = "Stomp field that slows enemies and deals small area damage.",
		},
		ultimate = {
			id = "atlas_blackstar_drop",
			displayName = "Blackstar Drop",
			action = "ultimate",
			damage = 40,
			guardDamage = 30,
			radius = 24,
			cooldown = 32,
			windup = 1.2,
			pullStrength = 24,
			vfxColor = Color3.fromRGB(44, 36, 96),
			description = "Telegraphed gravity drop that is strong but dodgeable.",
		},
	},
}

local abilityOrder = {
	"basic",
	"skill1",
	"skill2",
	"skill3",
	"ultimate",
}

function AbilityDefinitions.get(characterId, actionName)
	local characterAbilities = AbilityDefinitions[characterId]
	if not characterAbilities then
		return nil
	end
	return characterAbilities[actionName]
end

function AbilityDefinitions.getCharacterAbilities(characterId)
	return AbilityDefinitions[characterId]
end

function AbilityDefinitions.listForCharacter(characterId)
	local list = {}
	local characterAbilities = AbilityDefinitions[characterId]
	if not characterAbilities then
		return list
	end

	for _, actionName in ipairs(abilityOrder) do
		local ability = characterAbilities[actionName]
		if ability then
			table.insert(list, ability)
		end
	end

	return list
end

return AbilityDefinitions
