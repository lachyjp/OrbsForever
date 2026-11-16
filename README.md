# OrbsForever development workspace

The installable addon is in `OrbsUI/`. See its [README](OrbsUI/README.md) and [CHANGELOG](OrbsUI/CHANGELOG.md).

- `dist/OrbsForever-<version>.zip`: generated package to upload to CurseForge.
- `preview.png`: texture proof sheet using the shipped TGA assets, not a game screenshot.
- `tools/gen_textures.py`: dependency-free original art generator.
- `tools/preview.py`: optional Pillow proof-sheet renderer.
- `tools/package.py`: build and verify the ZIP.
- `tests/run.py`: Lua 5.1 behavioural tests using Python's `lupa` package.

```powershell
python tools/gen_textures.py
python -m pip install --target .test-deps lupa==2.8
python tests/run.py
python tools/package.py
```

To release: bump `O.version` in `OrbsUI/Core.lua` and `## Version` in `OrbsUI/OrbsUI.toc` (the packager checks they match), add a CHANGELOG entry, run the tests, then run the packager.

On this machine, `_forever_\Interface\AddOns\OrbsUI` is a directory junction to `OrbsUI/`, so `/reload` in game picks up edits directly.

The buff, debuff, tooltip and loot-frame tweaks that used to be part of OrbsForever now live in the separate `wow-hud-tweaks` project (HUD Tweaks, `/hud`).
