local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

local WorldBuilderService = {}

function WorldBuilderService.Start()
	local world = Workspace:FindFirstChild("AniverseRiftfall")
	local hud = StarterGui:FindFirstChild("AniverseHUD")

	if not world then
		warn("[Aniverse Royale] Workspace.AniverseRiftfall is missing. Apply blueprints/ar001/ar001_foundation.blueprint.json.")
	end

	if not hud then
		warn("[Aniverse Royale] StarterGui.AniverseHUD is missing. Apply blueprints/ar001/ar001_foundation.blueprint.json.")
	end
end

return WorldBuilderService
