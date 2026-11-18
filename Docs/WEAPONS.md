# Weapons — Galaxy Frontier (Godot)

All 7 weapons. Damage is per hit (shotgun: per pellet × 6 pellets). Rate is shots per second. Zoom is the ADS field-of-view factor (1.0 = no zoom). Scope is what the Aim overlay shows.

| Weapon | Damage | Rate | Mag | Reserve | Range | Reload | Spread | Zoom | Scope | Pellets | Splash |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Pistol | 20 | 3.0/s | 12 | 120 | 80 m | 1.1 s | 1.5° | 0.85 | iron | 1 | — |
| SMG | 14 | 12.0/s | 32 | 192 | 60 m | 1.4 s | 3.0° | 0.80 | iron | 1 | — |
| Assault Rifle | 18 | 10.0/s | 30 | 240 | 100 m | 1.8 s | 2.0° | 0.80 | iron | 1 | — |
| Sniper Rifle | 85 | 0.8/s | 5 | 30 | 200 m | 2.5 s | 0.3° | 0.45 | scope_8x | 1 | — |
| Shotgun | 12/pellet | 1.2/s | 6 | 36 | 30 m | 2.8 s | 6.0° | 0.85 | iron | 6 | — |
| Energy Rifle | 24 | 5.0/s | 24 | 144 | 120 m | 1.6 s | 1.0° | 0.75 | scope_4x | 1 | — |
| Launcher | 90 | 0.7/s | 4 | 16 | 150 m | 3.0 s | 1.0° | 0.85 | iron | 1 | 3.0 m |

## Aim / ADS behavior per weapon

- **Aim button (hold) or right mouse:** camera FOV × zoom (see table), camera arm shortens 4.2 → 2.4 m, movement speed × 0.6, spread × 0.35. Firing while aiming is fully allowed.
- **Iron sights** (pistol, SMG, rifle, shotgun, launcher): plain crosshair, tighter while aiming.
- **Scope 4x** (energy rifle): darkened-edge scope overlay, circle radius ~42% of screen height.
- **Scope 8x** (sniper): darkened-edge scope overlay, circle radius ~32% of screen height (strongest zoom, FOV × 0.45).
- **Crosshair:** gap widens with spread and movement speed, tightens while aiming (× 0.5); color shifts while aiming.

## Loadout

The player carries **two** weapons (slots). Switch toggles between them. New weapons are picked up in the world (SMG / Sniper / Energy pickups) — a pickup replaces the secondary slot when both slots are full, with a full magazine and reserve. Held weapon meshes are real-size: pistol 0.25 m, SMG 0.6 m, rifle 0.9 m, sniper 1.2 m, shotgun 1.0 m, energy 0.95 m, launcher 1.1 m.
