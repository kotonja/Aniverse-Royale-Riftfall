# AR-003 3v3 Arena Spec

## Purpose

AR-003 proves that Aniverse Royale has fun local team combat before building the full battle royale. It adds four playable Riftborn, server-owned team assignment, local arena round flow, simple arena bots, and real Studio instances for Arena3v3 and HUD panels.

This milestone is not global matchmaking, ranked, progression, monetization, or full Squad Royale.

## Roster

- Kairo Soljin: Solar Brawler, Vanguard, Flame.
- Mira Gale: Sky Duelist, Skirmisher, Gale.
- Sora Nym: Star Medic, Support, Light.
- Atlas Null: Gravity Monk, Tank / Controller, Gravity.

## Team Combat Goals

- Team Sun and Team Moon are server-owned custom teams.
- Team size target is 3.
- Friendly fire is disabled in normal arena mode.
- Unassigned players can damage training dummies, not other players.
- Player attributes mirror team assignment through `AR_TeamId` and `AR_TeamName`.

## Arena Flow

States:

- Idle
- Countdown
- Active
- RoundOver
- Resetting

Flow:

1. Select a Riftborn.
2. Choose Team Sun or Team Moon.
3. Start the arena round from the HUD or start pad.
4. Server resets stats, cooldowns, and bots.
5. Players teleport to team spawns.
6. Countdown runs for 5 seconds.
7. Active round begins.
8. Last team with active combatants wins.
9. Winner displays and the round resets after 8 seconds.

## Bot Rules

AR-003 uses team-tagged arena bots/dummies so one developer can test the loop solo. Bots can be damaged, healed, shielded, marked, slowed, and counted for round wins. They do not grant rewards and do not save progression.

## UI Changes

- `TeamPanel`: shows Team Sun, Team Moon, current team, and bot state.
- `ArenaPanel`: shows arena state, countdown, round, score, living combatants, winner, team buttons, and start button.
- `CharacterPanel`: includes Kairo, Mira, Sora, and Atlas cards.
- `AbilityHotbar`: dynamically reads the selected character ability names.
- `FeedbackLayer`: displays team selection, round state, support, reveal, pull, slow, and damage reduction feedback.

## Combat Changes

- CombatService uses TeamService ally/enemy checks.
- Sora adds ally shield, ally heal, and light mark support.
- Atlas adds pull, slow, damage reduction, and reduced knockback.
- Damage applies reduction, blocking, shield, then health.
- Defeated arena players are marked out and moved to spectator flow until reset.

## Test Checklist

1. Play solo with no output errors.
2. Confirm Training Dojo, Arena3v3, and AniverseHUD exist.
3. Select Kairo, Mira, Sora, and Atlas.
4. Confirm HUD ability labels update for every character.
5. Use sprint, dash, air dash, double jump, slide, and wall kick.
6. Damage training dummies with all four basics.
7. Use every Q/E/R/X ability for all four characters.
8. Choose Team Sun and Team Moon.
9. Start the arena round and confirm countdown.
10. Confirm enemies and bots take damage.
11. Confirm allies do not take friendly fire.
12. Confirm Sora shields/heals allies only.
13. Confirm Atlas pulls/slows enemies.
14. Confirm winner and reset flow.
15. Confirm no permanent duplicate world or HUD objects are created at runtime.

## Known Limits

- Arena bots are static team-tagged combat dummies, not full AI.
- Down/revive is deferred to AR-004.
- Aura Link is deferred to AR-004.
- Balance numbers are first-pass values for feel testing.
- No permanent rewards, ranked, matchmaking, or data save exist in AR-003.
