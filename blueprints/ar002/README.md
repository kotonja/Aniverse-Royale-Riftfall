# AR-002 Studio Foundation Blueprint

`ar002_studio_foundation.blueprint.json` installs the AR-002 source scripts plus the real Studio instances required for the playable training foundation.

Use it from the bridge helper repo:

```powershell
tools\bridge.cmd blueprint validate "C:\Users\tommy\OneDrive\Documentos\Aniverse Royale 2\blueprints\ar002\ar002_studio_foundation.blueprint.json"
tools\bridge.cmd blueprint preview "C:\Users\tommy\OneDrive\Documentos\Aniverse Royale 2\blueprints\ar002\ar002_studio_foundation.blueprint.json"
tools\bridge.cmd blueprint apply "C:\Users\tommy\OneDrive\Documentos\Aniverse Royale 2\blueprints\ar002\ar002_studio_foundation.blueprint.json"
```

The blueprint owns persistent world and HUD instances. Runtime scripts may update values and spawn temporary VFX, hit markers, and damage numbers only.
