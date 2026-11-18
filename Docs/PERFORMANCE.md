# Performance — Galaxy Frontier (Godot)

## Budgets (documented caps)

| Metric | Target | Cap |
|---|---|---|
| Frame rate | 60 FPS | ≥50 FPS before auto step-down |
| Draw calls | ≤120 typical | ≤150 |
| Primitives | ≤300k typical | ≤500k |
| Video memory | ≤256 MB typical | ≤512 MB |

## How the budgets are held

- **Auto quality** (`scripts/performance_manager.gd`): samples FPS / draw calls / primitives / video memory every 0.5 s. Steps quality down if FPS < 50 for 5 s; steps back up if FPS > 58 for 15 s; 10 s cooldown; never above the user's saved quality; never writes to disk.
- **No heavy per-frame polling:** interactable scan every 0.15 s, enemy line-of-sight every 0.25 s (staggered), zone checks every 0.5 s, door proximity every 0.1 s, HUD refresh every 0.25 s, minimap redraw every 0.25 s.
- **Manual LOD:** detail props (roof vents, station pipes, antenna) hide beyond 60 m from the player (checked twice a second). The world is primitives + a handful of 128×128 procedural textures — no heavy meshes to LOD.
- **Lights:** 1 directional sun (shadows per quality setting) + 3 interior OmniLights + 1 core light + 1 muzzle flash light (only while firing). No real-time bloom (not supported in the GL Compatibility renderer) — glow is emissive material + lights.

## Quality levels

| Level | MSAA | Sun shadows |
|---|---|---|
| Low (0) | off | off |
| Medium (1) | 2x | on |
| High (2) | 4x | on |

## What was measured here

See `Docs/PHASE-GODOT-01-REPORT.md` — headless Linux numbers only. Real iOS frame rates (iPhone SE / Pro Max / iPad) are **NOT TESTED** and are left blank in `Docs/DEVICE_TEST_MATRIX.md` until a real device runs the game.
