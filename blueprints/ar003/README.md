# AR-003 Four Character 3v3 Arena Blueprint

`ar003_3v3_arena.blueprint.json` installs the AR-003 source scripts plus the real Studio instances required for the local 3v3 arena vertical slice.

Use it from the bridge helper repo:

```powershell
cd "C:\Users\tommy\OneDrive\Documentos\New project 5"
tools\bridge.cmd blueprint validate "C:\Users\tommy\OneDrive\Documentos\Aniverse Royale 2\blueprints\ar003\ar003_3v3_arena.blueprint.json"
tools\bridge.cmd blueprint preview "C:\Users\tommy\OneDrive\Documentos\Aniverse Royale 2\blueprints\ar003\ar003_3v3_arena.blueprint.json"
tools\bridge.cmd blueprint apply "C:\Users\tommy\OneDrive\Documentos\Aniverse Royale 2\blueprints\ar003\ar003_3v3_arena.blueprint.json"
```

The blueprint owns persistent Arena3v3 world objects and HUD additions. Runtime scripts may update values and spawn temporary VFX, hit markers, support pulses, reveal marks, and damage numbers only.
