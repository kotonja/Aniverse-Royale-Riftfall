# AR-003 Studio Instance Contract

AR-003 treats Studio instances as source-of-truth build artifacts. Scripts may validate and update these objects, but they must not generate the persistent world, HUD, or arena map at runtime.

## Workspace

Required root:

- `Workspace.AniverseRiftfall`
- `Workspace.AniverseRiftfall.TrainingDojo`
- `Workspace.AniverseRiftfall.Arena3v3`

Required Training Dojo children:

- `SpawnArea`: three spawn locations, spawn deck, title approach.
- `CombatArena`: floor, boundaries, center aura ring, cover blocks, raised platforms.
- `MovementCourse`: sprint lane, dash gates, double-jump platforms, air-dash gap, slide ramp/tunnel, wall-kick boards, vertical climb, rooftop route.
- `CharacterPads`: real Kairo, Mira, Sora, and Atlas selection pads with `CharacterId` attributes.
- `DamageDummies`: basic, shield, guard, moving-path placeholder, and clustered AOE dummies.
- `Signs`: real in-world guide signs.
- `LightingHelpers`: simple neon anchors for the current dojo look.
- `DebugMarkers`: non-gameplay markers for placeholder paths and validation.

Required Arena3v3 children:

- `ArenaFloor`
- `SunSpawnPoints`
- `MoonSpawnPoints`
- `TeamPads`
- `StartRoundPad`
- `SpectatorPlatform`
- `ArenaBoundaries`
- `Cover`
- `VerticalPlatforms`
- `BotSpawnPoints`
- `ArenaBots`
- `ArenaSigns`
- `DebugMarkers`

Expected tags or tag attributes:

- `AR_DamageDummy`
- `AR_CharacterPad`
- `AR_MovementGate`
- `AR_TrainingSign`
- `AR_Arena3v3`
- `AR_TeamPad`
- `AR_ArenaStartPad`
- `AR_ArenaSpawn`
- `AR_ArenaBotSpawn`
- `AR_ArenaBoundary`
- `AR_ArenaBot`

## StarterGui

Required root:

- `StarterGui.AniverseHUD`
- `StarterGui.AniverseHUD.Root`

Required HUD children:

- `TopBar`
- `LeftSquadPanel`
- `CenterReticle`
- `BottomBars`
- `AbilityHotbar`
- `CharacterPanel`
- `TeamPanel`
- `ArenaPanel`
- `FeedbackLayer`
- `MobileButtons`
- `DebugPanel`

The `BottomBars` panel must contain Health, Shield, Flow, and Guard bars with `Fill` and `Label` children. The `AbilityHotbar` must contain Basic, Skill1, Skill2, Skill3, Block, Ultimate, Dash, and Slide buttons with cooldown/no-flow visual children. The `CharacterPanel` must contain Kairo, Mira, Sora, and Atlas cards or buttons with `CharacterId` attributes.

## ReplicatedStorage

Required folders:

- `ReplicatedStorage.Shared`
- `ReplicatedStorage.Remotes`
- `ReplicatedStorage.Assets.VFX`
- `ReplicatedStorage.Assets.UI`
- `ReplicatedStorage.Assets.Audio`
- `ReplicatedStorage.Assets.Animations`

Required remotes:

- `RequestCharacterChange`
- `RequestTeamChange`
- `RequestArenaStart`
- `CombatAction`
- `MovementAction`
- `StateUpdate`
- `CombatFeedback`
- `ArenaStateUpdate`
- `TeamStateUpdate`
- `BotStateUpdate`

## Script Paths

The current Rojo/blueprint layout nests entrypoints under folders:

- Spec equivalent `ServerScriptService.ServerMain`: `ServerScriptService.Server.ServerMain`
- Spec equivalent `StarterPlayerScripts.ClientMain`: `StarterPlayer.StarterPlayerScripts.Client.ClientMain`

This foldered layout is intentional so services/controllers stay grouped.
