# Realism — Galaxy Frontier (Godot)

The user asked for maximum realism in Godot, at real-world scale (1 unit = 1 m), without breaking 60 FPS. This file says exactly what was done per category — and where the ceiling is. **This is not Unreal-level realism, and it does not claim to be.**

## Scale (real world, PUBG-size)

| Asset | Size |
|---|---|
| Player / enemies | 1.8 m tall, head 0.26 m, shoulders ~0.5 m |
| Doors | 1.2 m wide × 2.1 m high |
| House | 6–8 m × 6–7 m, 3.0 m per floor |
| Station | 24×16 m, two floors × 3.2 m = 6.4 m |
| Streets | 7 m wide |
| Rover RX-7 | 4.5 m long × 1.9 m wide, wheels 0.8 m diameter |
| Weapons (held) | pistol 0.25 m … sniper 1.2 m |
| Pickups | ~0.45 m boxes (visible, slightly oversized for gameplay) |

Movement is tuned to this scale: walk 5 / run 8 / sprint 11 m/s, jump velocity 7 m/s, gravity 20 m/s² (2× real gravity, tuned for game feel — documented, not hidden).

## What was done per category

### Characters
- Real human proportions: 1.8 m height, 0.26 m head (was 0.42 m cartoon box), torso capsule radius 0.26, separate legs (0.17×0.8 m), arms, chest armor plate, belt, helmet, visor.
- PBR fabric suit + bare-metal armor (procedural normal maps, see below).
- 4 playable characters with distinct proportions/colors/helmets; 5 enemy types with distinct scale/colors (boss 1.5× with gold crest, sniper with rifle mesh).

### Vehicles
- Rover RX-7 at real size (4.5×1.9 m): chassis, hood, rear bed, glass cabin, roof + roll bars, front bumper, grille, headlights/taillights (emissive), side mirrors, exhaust pipe, wheels 0.8 m with hub caps that spin at ω = v/r.
- PBR painted metal + reflective glass.

### Weapons
- Held weapon meshes at real lengths per weapon (0.25–1.2 m): receiver + barrel + grip; sniper gets a glass scope tube, energy rifle an emissive coil.
- Muzzle flash light (0.06 s) + camera recoil kick (0.008–0.02 rad) on every shot; launcher impact spawns a smoke burst.

### Buildings
- Concrete walls with procedural albedo + normal maps, painted-metal roofs, reflective glass windows (1.4×1.2 m), roof pipes, vents, antenna with emissive tip, door frames + handles, accent light strip on the station.
- Interior lights in the station (2 OmniLights) + emissive Power Core with its own light.

### Lighting
- Directional sun with soft shadows (PCF blur 1.5, max distance 140 m), ProceduralSky + sky ambient (0.6 energy), fog, interior OmniLights.
- Emissive materials for energy/crystals/core/lights.

### Effects
- Walking dust (GPU particles at the feet while moving on ground), muzzle flash light, camera recoil, launcher smoke burst, hit markers.

## Performance guards (realism must not break 60 FPS)

- Materials: 128×128 procedural textures, cached per surface (generated once).
- Manual LOD: detail props (vents, pipes, antenna) hidden beyond 60 m.
- Lights: 1 sun + 3 interior + 1 core + 1 muzzle = 6 max, all small ranges.
- No heavy per-frame polling (see `Docs/PERFORMANCE.md`).

## Honest limits (Godot on mobile)

1. **No real bloom/glow post-processing** — the GL Compatibility renderer (required for the widest iOS support) does not support it. Glow is faked with emissive materials + lights.
2. **No downloaded/sculpted assets** — everything is primitives + procedural textures. Surfaces read as clean PBR, not as scanned meshes; fine surface detail (stitching, panel gaps) is suggested by normal maps, not geometry.
3. **No skeletal animation** — characters are posed primitives; movement is capsule sliding, not walk cycles.
4. **No real-time global illumination** — lighting is sun + sky ambient + a few point lights.
5. **Upper floors are shells** — no stairs; ground floors only are enterable.
6. Real iOS frame rates are unmeasured (see `Docs/DEVICE_TEST_MATRIX.md`).
