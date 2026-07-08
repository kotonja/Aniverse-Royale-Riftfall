local InputController = {}

InputController.Keybinds = {
	Sprint = Enum.KeyCode.LeftShift,
	Dash = Enum.KeyCode.LeftAlt,
	Slide = Enum.KeyCode.C,
	Skill1 = Enum.KeyCode.Q,
	Skill2 = Enum.KeyCode.E,
	Skill3 = Enum.KeyCode.R,
	Block = Enum.KeyCode.F,
	Ultimate = Enum.KeyCode.X,
}

function InputController.Start()
	return true
end

return InputController
