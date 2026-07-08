local TeamConstants = {}

TeamConstants.TeamSizeTarget = 3

TeamConstants.Ids = {
	Sun = "sun",
	Moon = "moon",
	Spectator = "spectator",
}

TeamConstants.Teams = {
	sun = {
		id = "sun",
		displayName = "Team Sun",
		shortName = "Sun",
		color = Color3.fromRGB(255, 188, 82),
	},
	moon = {
		id = "moon",
		displayName = "Team Moon",
		shortName = "Moon",
		color = Color3.fromRGB(122, 160, 255),
	},
	spectator = {
		id = "spectator",
		displayName = "Spectator",
		shortName = "Spec",
		color = Color3.fromRGB(180, 188, 205),
	},
}

TeamConstants.CombatTeams = {
	sun = true,
	moon = true,
}

function TeamConstants.get(teamId)
	return TeamConstants.Teams[teamId]
end

function TeamConstants.isValid(teamId)
	return TeamConstants.Teams[teamId] ~= nil
end

function TeamConstants.isCombatTeam(teamId)
	return TeamConstants.CombatTeams[teamId] == true
end

function TeamConstants.listCombatTeams()
	return {
		TeamConstants.Teams.sun,
		TeamConstants.Teams.moon,
	}
end

return TeamConstants
