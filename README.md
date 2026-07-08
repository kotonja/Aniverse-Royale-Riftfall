# Aniverse Royale: Riftfall

Original anime-inspired Roblox squad battle royale foundation.

This repo intentionally uses original terminology and characters only:

- Powers: Aura Arts
- Fighters: Riftborn
- Squad combo concept: Aura Link
- Storm: Riftstorm
- Main mode: Squad Royale

The current milestone is AR-002 Studio Foundation + Movement / Camera / Game Feel Polish. It is still a training sandbox, not the full battle royale.

## Studio Build Rules

- UI must live as real `StarterGui` instances.
- World geometry must live as real `Workspace` instances.
- Runtime scripts can control behavior, state, combat, HUD updates, temporary VFX, hit markers, and floating damage numbers.
- Runtime scripts must not generate the core HUD or training arena.

## Current Milestone

AR-002 adds the real Studio instance contract for `Workspace.AniverseRiftfall.TrainingDojo` and `StarterGui.AniverseHUD`, movement validation, sprint/dash/air dash/double jump/slide/wall kick feel, camera pulses, mobile controls, combat feedback, and stronger remote rate limiting.

## Apply The Blueprint

From the bridge helper repo:

```powershell
cd "C:\Users\tommy\OneDrive\Documentos\New project 5"
tools\bridge.cmd blueprint validate "C:\Users\tommy\OneDrive\Documentos\Aniverse Royale 2\blueprints\ar002\ar002_studio_foundation.blueprint.json"
tools\bridge.cmd blueprint preview "C:\Users\tommy\OneDrive\Documentos\Aniverse Royale 2\blueprints\ar002\ar002_studio_foundation.blueprint.json"
tools\bridge.cmd blueprint apply "C:\Users\tommy\OneDrive\Documentos\Aniverse Royale 2\blueprints\ar002\ar002_studio_foundation.blueprint.json"
```

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

## Repo Layout

- `docs/`: game bible, Codex rules, roadmap, Studio contract, AR-002 game-feel spec
- `src/shared/`: configs, utility modules, network names/types
- `src/server/`: server entrypoint and services
- `src/client/`: client entrypoint and controllers
- `blueprints/ar001/`: AR-001 baseline blueprint
- `blueprints/ar002/`: AR-002 Studio foundation blueprint

## Known Limitations

- This is not full battle royale yet.
- Matchmaking, leaderboards, data, squads, Riftstorm, loot, revive, and public matchmaking remain stubs or future milestones.
- Damage dummies are static except for the marked moving-path placeholder.
- Wall kick is a functional placeholder tuned for the AR-002 movement course.
