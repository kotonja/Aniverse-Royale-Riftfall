local GameConstants = require(script.Parent.GameConstants)

local InputBindings = {}

InputBindings.Keyboard = {
	Sprint = Enum.KeyCode.LeftShift,
	Dash = Enum.KeyCode.LeftAlt,
	Slide = Enum.KeyCode.C,
	Skill1 = Enum.KeyCode.Q,
	Skill2 = Enum.KeyCode.E,
	Skill3 = Enum.KeyCode.R,
	Block = Enum.KeyCode.F,
	Ultimate = Enum.KeyCode.X,
	DebugPanel = Enum.KeyCode.F9,
}

InputBindings.Actions = {
	Basic = {
		label = "Basic",
		keyText = "LMB",
		buttonName = "BasicButton",
		remote = GameConstants.Actions.Basic,
		channel = "combat",
	},
	Skill1 = {
		label = "Skill 1",
		keyText = "Q",
		buttonName = "Skill1Button",
		remote = GameConstants.Actions.Skill1,
		channel = "combat",
	},
	Skill2 = {
		label = "Skill 2",
		keyText = "E",
		buttonName = "Skill2Button",
		remote = GameConstants.Actions.Skill2,
		channel = "combat",
	},
	Skill3 = {
		label = "Skill 3",
		keyText = "R",
		buttonName = "Skill3Button",
		remote = GameConstants.Actions.Skill3,
		channel = "combat",
	},
	Block = {
		label = "Block",
		keyText = "F",
		buttonName = "BlockButton",
		remote = GameConstants.Actions.BlockBegin,
		channel = "combatToggle",
	},
	Ultimate = {
		label = "Ultimate",
		keyText = "X",
		buttonName = "UltimateButton",
		remote = GameConstants.Actions.Ultimate,
		channel = "combat",
	},
	Dash = {
		label = "Dash",
		keyText = "Alt",
		buttonName = "DashButton",
		remote = GameConstants.Actions.Dash,
		channel = "movement",
	},
	Slide = {
		label = "Slide",
		keyText = "C",
		buttonName = "SlideButton",
		remote = GameConstants.Actions.Slide,
		channel = "movement",
	},
}

function InputBindings.getAction(actionKey)
	return InputBindings.Actions[actionKey]
end

function InputBindings.listHotbarOrder()
	return {
		"Basic",
		"Skill1",
		"Skill2",
		"Skill3",
		"Block",
		"Ultimate",
		"Dash",
		"Slide",
	}
end

return InputBindings
