# Galaxy Frontier — Godot 4 Rebuild

Original sci-fi 3D third-person action/adventure shooter for iPhone/iPad, rebuilt from scratch in **Godot 4.4.1 + GDScript** because the Unreal 5 version cannot build for iOS without a Mac with a 40–60 GB engine. Same game idea, same mission, rebuilt core — playable here on Linux, IPA later via GitHub Actions.

> **النسخة العربية:** لعبة أكشن/مغامرات خيال علمي بمنظور الشخص الثالث، أُعيد بناؤها من الصفر في Godot 4. القلب القابل للعب كامل هنا؛ نسخة الـ IPA تأتي لاحقًا عبر GitHub Actions.

## What is in this build (playable core)

- **Third-person character** — walk 5 / run 8 / sprint 11 m/s, jump, crouch, full 360° camera yaw (pitch limited −60°..+45°), SpringArm camera, virtual joystick + camera drag + keyboard/mouse, multi-touch (joystick + drag + fire at once).
- **7 weapons** — Pistol, SMG, Assault Rifle, Sniper Rifle, Shotgun, Energy Rifle, Launcher. Full table in `Docs/WEAPONS.md`. Two carried weapons, switch, reload, ADS (Aim) with per-weapon scope (iron / 4x / 8x), crosshair that tightens while aiming, fire while aiming.
- **4 playable characters** — Nova, Atlas, Vex, Luna (distinct look + starting weapon). Full list in `Docs/CHARACTERS.md`.
- **5 enemy types** — Grunt, Runner, Armored, Sniper (ranged), Guardian boss. Patrol / chase / attack / retreat, distance + line-of-sight perception. Stats in `Docs/CHARACTERS.md`.
- **World: planet ZERON, real scale (1 unit = 1 m)** — 240×240 m, 3 villages (Landing / Outpost / Extraction), 12 houses + a two-storey station, 7 m streets, mountains. Layout in `Docs/VILLAGES.md`. Doors open automatically on approach (PUBG-style), close after you pass.
- **Vehicles** — Rover RX-7 (4.5×1.9 m). RIDE button on approach, driving buttons (Accelerate/Brake/steer joystick/Exit), walk/combat buttons hidden while driving, exit refused while moving fast.
- **Pickups & loot** — health, shield, ammo, mission items on the ground and on crates; loot boxes drop where enemies die (contents per enemy type); what doesn't fit stays in the box.
- **Mission "The Lost Power Core"** — 8 strictly ordered stages, objective system, save/load (`user://savegame.json`).
- **Mobile UI (works for real)** — responsive HUD with Safe Areas, live minimap (top-right) + full map, inventory, loot panel, pause, settings (sensitivity/quality/invert-Y), game-over and mission-complete screens. PUBG-style main menu: Character / Weapons / Missions / Settings / Shop (spec only, no real purchases).
- **Realism (Godot ceiling, honestly documented)** — procedural PBR materials (concrete/asphalt/dirt/metal/fabric/glass with generated normal maps), soft-shadow sun, interior lights, emissive energy, dust / muzzle flash / recoil / smoke. Details in `Docs/REALISM.md`. This is **not** Unreal-level realism — Godot on iPhone has a lower ceiling; see the report for the exact limits.

## Performance

- Target 60 FPS. Budgets: ≤150 draw calls, ≤500k primitives, ≤512 MB video memory (see `Docs/PERFORMANCE.md`). Auto quality steps down/up automatically; no heavy per-frame polling (checks throttled to 0.1–0.5 s); manual LOD hides detail props beyond 60 m.

## How to run

```bash
# Linux (Godot 4.4.1)
godot --path . --import
godot --path .
```

iOS export: see `.github/workflows/build-ios-ipa-godot.yml` (GitHub Actions, macos-15, unsigned IPA for SideStore re-signing).

## Verification

See `Docs/PHASE-GODOT-01-REPORT.md` and `tests/verify_godot.gd`. What was verified live on Linux and what still awaits a real iOS device is stated explicitly there — nothing is claimed without a real test.

## NOT IMPLEMENTED (later phases)

Multiplayer / battle royale, extra planets (NEXUS, VELTRON, ASTRALIS), upper-floor interiors (no stairs yet), real-money shop, cloud saves. Full list in the report.
