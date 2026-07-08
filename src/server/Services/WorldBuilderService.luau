local CollectionService = game:GetService("CollectionService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared.Config.GameConstants)

local WorldBuilderService = {}

local requiredWorkspacePaths = {
	"AniverseRiftfall",
	"AniverseRiftfall.TrainingDojo",
	"AniverseRiftfall.TrainingDojo.SpawnArea",
	"AniverseRiftfall.TrainingDojo.CombatArena",
	"AniverseRiftfall.TrainingDojo.MovementCourse",
	"AniverseRiftfall.TrainingDojo.CharacterPads",
	"AniverseRiftfall.TrainingDojo.DamageDummies",
	"AniverseRiftfall.TrainingDojo.Signs",
	"AniverseRiftfall.TrainingDojo.LightingHelpers",
	"AniverseRiftfall.TrainingDojo.DebugMarkers",
	"AniverseRiftfall.Arena3v3",
	"AniverseRiftfall.Arena3v3.ArenaFloor",
	"AniverseRiftfall.Arena3v3.SunSpawnPoints",
	"AniverseRiftfall.Arena3v3.MoonSpawnPoints",
	"AniverseRiftfall.Arena3v3.TeamPads",
	"AniverseRiftfall.Arena3v3.StartRoundPad",
	"AniverseRiftfall.Arena3v3.SpectatorPlatform",
	"AniverseRiftfall.Arena3v3.ArenaBoundaries",
	"AniverseRiftfall.Arena3v3.Cover",
	"AniverseRiftfall.Arena3v3.VerticalPlatforms",
	"AniverseRiftfall.Arena3v3.BotSpawnPoints",
	"AniverseRiftfall.Arena3v3.ArenaBots",
	"AniverseRiftfall.Arena3v3.ArenaSigns",
	"AniverseRiftfall.Arena3v3.DebugMarkers",
}

local requiredStarterGuiPaths = {
	"AniverseHUD",
	"AniverseHUD.Root",
	"AniverseHUD.Root.TopBar",
	"AniverseHUD.Root.LeftSquadPanel",
	"AniverseHUD.Root.CenterReticle",
	"AniverseHUD.Root.BottomBars",
	"AniverseHUD.Root.AbilityHotbar",
	"AniverseHUD.Root.CharacterPanel",
	"AniverseHUD.Root.FeedbackLayer",
	"AniverseHUD.Root.MobileButtons",
	"AniverseHUD.Root.DebugPanel",
	"AniverseHUD.Root.TeamPanel",
	"AniverseHUD.Root.ArenaPanel",
}

local function findFrom(root, dottedPath)
	local current = root
	for segment in string.gmatch(dottedPath, "[^.]+") do
		current = current and current:FindFirstChild(segment)
	end
	return current
end

local function warnMissing(rootName, root, paths)
	for _, path in ipairs(paths) do
		if not findFrom(root, path) then
			warn(("[Aniverse Royale] Missing %s.%s. Apply blueprints/ar003/ar003_3v3_arena.blueprint.json."):format(rootName, path))
		end
	end
end

local function tagChildren(folder, tagName)
	if not folder then
		return
	end

	for _, child in ipairs(folder:GetChildren()) do
		CollectionService:AddTag(child, tagName)
	end
end

local function tagContractInstances()
	local worldRoot = Workspace:FindFirstChild(GameConstants.World.RootName)
	local dojo = worldRoot and worldRoot:FindFirstChild(GameConstants.World.TrainingDojoName)
	local arena = worldRoot and worldRoot:FindFirstChild(GameConstants.World.Arena3v3Name)
	if dojo then
		tagChildren(dojo:FindFirstChild(GameConstants.World.DummyFolderName), GameConstants.World.Tags.DamageDummy)
		tagChildren(dojo:FindFirstChild(GameConstants.World.CharacterPadFolderName), GameConstants.World.Tags.CharacterPad)
		tagChildren(dojo:FindFirstChild(GameConstants.World.MovementCourseName), GameConstants.World.Tags.MovementGate)
		tagChildren(dojo:FindFirstChild("Signs"), GameConstants.World.Tags.TrainingSign)
	end

	if arena then
		CollectionService:AddTag(arena, GameConstants.World.Tags.Arena3v3)
		tagChildren(arena:FindFirstChild("TeamPads"), GameConstants.World.Tags.TeamPad)
		tagChildren(arena:FindFirstChild("SunSpawnPoints"), GameConstants.World.Tags.ArenaSpawn)
		tagChildren(arena:FindFirstChild("MoonSpawnPoints"), GameConstants.World.Tags.ArenaSpawn)
		tagChildren(arena:FindFirstChild("BotSpawnPoints"), GameConstants.World.Tags.ArenaBotSpawn)
		tagChildren(arena:FindFirstChild("ArenaBoundaries"), GameConstants.World.Tags.ArenaBoundary)
		tagChildren(arena:FindFirstChild("ArenaBots"), GameConstants.World.Tags.ArenaBot)

		local startPad = arena:FindFirstChild("StartRoundPad")
		if startPad then
			CollectionService:AddTag(startPad, GameConstants.World.Tags.ArenaStartPad)
		end
	end
end

function WorldBuilderService.Start()
	warnMissing("Workspace", Workspace, requiredWorkspacePaths)
	warnMissing("StarterGui", StarterGui, requiredStarterGuiPaths)
	tagContractInstances()
end

return WorldBuilderService
