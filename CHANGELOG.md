# CHANGELOG — Galaxy Frontier (Godot rebuild)

## 1.0.0 — 2026-11-18 (Godot 4.4.1, playable core)

- New project from scratch in Godot 4.4.1 + GDScript (`project.godot`: Galaxy Frontier, `com.iosai2035.GalaxyFrontier`, landscape, touch, GL Compatibility).
- Third-person character: walk 5 / run 8 / sprint 11 m/s, jump, crouch, 360° yaw camera, SpringArm, virtual joystick + camera drag + keyboard/mouse, multi-touch.
- Combat: 7 weapons (pistol, SMG, rifle, sniper, shotgun, energy, launcher) with documented stats; 2-weapon loadout, switch, reload; ADS with per-weapon scope (iron / 4x / 8x) and dynamic crosshair; hitscan + shotgun pellets + launcher splash.
- Enemies: 5 types (grunt, runner, armored, sniper, boss) with distinct stats/behavior; patrol/chase/attack/retreat; distance + line-of-sight perception.
- Characters: 4 playable (Nova, Atlas, Vex, Luna) with distinct look + starting weapon.
- World ZERON (real scale, 1 u = 1 m): 240×240 m, 3 villages, 12 houses + two-storey station (3.2 m floors), 7 m streets, mountains; auto doors (PUBG-style); Rover RX-7 vehicle (4.5×1.9 m) with driving controls.
- Pickups (health/shield/ammo/mission items) on ground and crates; loot boxes on enemy death with inventory caps.
- Mission "The Lost Power Core": 8 ordered stages, objectives, save/load.
- Full working mobile UI: responsive HUD + Safe Areas, live minimap + full map, inventory, loot panel, pause/settings, game-over/mission-complete, PUBG-style main menu (Character/Weapons/Missions/Settings/Shop-spec-only).
- Realism pass: procedural PBR materials with generated normal maps, soft-shadow sun, interior lights, dust/muzzle flash/recoil/smoke, manual LOD, auto quality.
- Verification: headless import + `tests/verify_godot.gd` + Linux export smoke test (see report). IPA workflow file included locally (not run, not pushed).
