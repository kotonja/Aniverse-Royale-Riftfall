# Aniverse Royale: Riftfall

AR-001 Foundation + Combat Sandbox for an original anime-inspired Roblox squad battle royale.

This repo intentionally uses original terminology and characters only:

- Powers: Aura Arts
- Fighters: Riftborn
- Squad combo concept: Aura Link
- Storm: Riftstorm
- Main mode: Squad Royale

The current milestone is a playable training sandbox, not the full battle royale.

## Studio Build Rules

- UI must live as real `StarterGui` instances.
- World geometry must live as real `Workspace` instances.
- Runtime scripts can control behavior, state, combat, and HUD updates, but they should not generate the core HUD or training arena at runtime.

## Current Milestone

AR-001 creates the docs, source structure, shared config, server-authoritative combat foundation, client input/movement/HUD controllers, placeholder future systems, and a greybox Training Dojo with Kairo Soljin and Mira Gale prototypes.

## Controls

- WASD: move
- Shift: sprint
- Space: jump / double jump
- Left Alt: dash / air dash
- Left Mouse: basic attack
- Q/E/R: skills
- F: block
- X: ultimate placeholder
- C: slide placeholder

## Repo Layout

- `docs/`: game bible, Codex rules, roadmap
- `src/shared/`: configs, utility modules, network names/types
- `src/server/`: server entrypoint and services
- `src/client/`: client entrypoint and controllers
- `blueprints/ar001/`: live Studio blueprint that installs source plus real `StarterGui` and `Workspace` objects
