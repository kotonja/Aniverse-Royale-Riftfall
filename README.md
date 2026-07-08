# Aniverse Royale: Riftfall

Original anime-inspired Roblox squad battle royale foundation.

This repo intentionally uses original terminology and characters only:

- Powers: Aura Arts
- Fighters: Riftborn
- Squad combo concept: Aura Link
- Storm: Riftstorm
- Main mode: Squad Royale

The current milestone is AR-003 Four Character 3v3 Arena. It is a local team-combat proving ground, not the full battle royale, global matchmaking, ranked, data progression, or monetization.

## Studio Build Rules

- UI must live as real `StarterGui` instances.
- World geometry must live as real `Workspace` instances.
- Runtime scripts can control behavior, state, combat, HUD updates, temporary VFX, hit markers, and floating damage numbers.
- Runtime scripts must not generate the core HUD, training arena, or Arena3v3 map.

## Current Milestone

AR-003 adds four playable original Riftborn, server-owned team assignment, local arena round flow, team-tagged arena bots, Sora support mechanics, Atlas tank/controller mechanics, real `Workspace.AniverseRiftfall.Arena3v3` instances, and real `StarterGui.AniverseHUD.Root.TeamPanel` / `ArenaPanel` UI.

Playable roster:

- Kairo Soljin - Solar Brawler
- Mira Gale - Sky Duelist
- Sora Nym - Star Medic
- Atlas Null - Gravity Monk

## Apply The Blueprint

From the bridge helper repo:

```powershell
cd "C:\Users\tommy\OneDrive\Documentos\New project 5"
tools\bridge.cmd blueprint validate "C:\Users\tommy\OneDrive\Documentos\Aniverse Royale 2\blueprints\ar003\ar003_3v3_arena.blueprint.json"
tools\bridge.cmd blueprint preview "C:\Users\tommy\OneDrive\Documentos\Aniverse Royale 2\blueprints\ar003\ar003_3v3_arena.blueprint.json"
tools\bridge.cmd blueprint apply "C:\Users\tommy\OneDrive\Documentos\Aniverse Royale 2\blueprints\ar003\ar003_3v3_arena.blueprint.json"
```

Apply AR-002 first only if the Training Dojo or base HUD is missing.

## Controls

- WASD: move
- Shift: sprint
- Space: jump / double jump / wall kick near a wall
- Left Alt: dash / air dash
- C: slide
- Left Mouse: basic attack
- Q/E/R: skills
- F: block
- X: ultimate placeholder
- F9: debug panel toggle

## Arena3v3 Test

1. Select Kairo, Mira, Sora, or Atlas from the real character cards or pads.
2. Choose Team Sun or Team Moon from the real ArenaPanel buttons or team pads.
3. Press Start Round or touch the Start 3v3 Arena Test pad.
4. Fight the enemy team and team-tagged bots.
5. Win by being the last team with active combatants.

## Repo Layout

- `docs/`: game bible, Codex rules, roadmap, Studio contract, AR-002 and AR-003 specs
- `src/shared/`: configs, utility modules, network names/types
- `src/server/`: server entrypoint and services
- `src/client/`: client entrypoint and controllers
- `blueprints/ar001/`: AR-001 baseline blueprint
- `blueprints/ar002/`: AR-002 Studio foundation blueprint
- `blueprints/ar003/`: AR-003 arena blueprint

## Known Limitations

- This is still a local test mode, not the public battle royale.
- Arena bots are team-tagged combat dummies for solo testing, not full AI opponents.
- Down/revive and Aura Link are AR-004.
- Matchmaking, leaderboards, data, Riftstorm, loot, ranked, cosmetics, and monetization remain future milestones.
