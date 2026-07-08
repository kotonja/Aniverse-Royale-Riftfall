# AR-002 Game Feel Spec

AR-002 focuses on the playable foundation, not more characters or the full battle royale loop.

## Movement

- Sprint uses Shift and server-confirmed `sprintBegin` / `sprintEnd`.
- Dash uses Left Alt, spends Flow, has a server cooldown, and gives a short FOV pulse.
- Air dash reuses dash feel with lift and a separate cooldown.
- Double jump fires a server validation event and gives a small air pulse.
- Slide uses C, spends Flow, requires ground contact on the server, and gets slide dust feedback.
- Wall kick is a placeholder near collidable walls after double jump.

## Camera

The camera stays Roblox third-person custom by default. `CameraController` exposes:

- `PulseDash()`
- `PulseSprint(active)`
- `ShakeSmall()`
- `ShakeMedium()`
- `HitConfirm()`
- `UltimatePulse()`
- `SoftLockPlaceholder()`

## HUD

The HUD is a real `StarterGui.AniverseHUD` tree. Controllers only update:

- health, shield, Flow, and guard bar fill/text
- selected Riftborn labels
- ability button labels
- cooldown overlay numbers
- no-Flow overlays
- feedback text
- debug panel visibility

## Combat Feedback

`FeedbackController` listens to `CombatFeedback` and creates temporary effects only:

- floating damage numbers
- hit marker pulses
- guard shield flash
- dash/air-dash pulse
- double-jump ring
- slide dust pulse
- ultimate camera pulse

## Server Validation

The server owns damage, cooldowns, character selection, health, shield, guard, Flow spending, and movement cooldown/rate-limit checks. Client movement is only local prediction.

## Known Limits

- No new Riftborn in AR-002.
- No full battle royale loop.
- No monetization.
- Matchmaking, data, and leaderboard services remain placeholders.
