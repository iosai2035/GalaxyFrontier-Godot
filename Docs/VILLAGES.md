# Villages — Planet ZERON (Godot)

Real scale: 1 unit = 1 m. The map is 240×240 m. Three villages, connected by 7 m streets (wide enough for the 1.9 m Rover and for walking side by side).

## Villages

| Village | Center | Buildings | Notes |
|---|---|---|---|
| Landing | (−70, −50) | 4 houses (1 two-storey) | Landing pad / zone; player spawn (−70, −50) |
| Outpost | (0, 0) | Station (two-storey) + 4 houses (2 two-storey) | Power Core + terminal inside the station |
| Extraction | (70, 60) | 4 houses (1 two-storey) | Extraction zone; Guardian boss patrols here |

Total: **12 houses + 1 station = 13 buildings**. Every building is enterable on the ground floor through an auto door (1.2×2.1 m, opens on approach, closes after you pass).

## Streets

| Street | From → To | Width |
|---|---|---|
| Landing–Outpost | (−70,−50) → (0,0) | 7 m |
| Outpost–Extraction | (0,0) → (70,60) | 7 m |
| Outpost cross street | (0,−18) → (0,18) | 7 m |

Streets are flat asphalt strips, clear of rocks and crystals (props are kept ≥ 4 m from street edges), and passable on foot and by vehicle.

## Buildings (real dimensions)

- House: 6–8 m × 6–7 m footprint, 3.0 m per floor, 1 or 2 floors, door 1.2×2.1 m, windows 1.4×1.2 m (reflective glass), roof slab + vent.
- Station: 24×16 m, two floors × 3.2 m = 6.4 m + roof, door 1.2×2.1 m, windows both floors, roof pipes + antenna.
- **Limit (honest):** upper floors are exterior shells — no stairs yet, so only ground floors are enterable. Stairs/interiors for upper floors are a later phase.

## Terrain

- Ground: dirt PBR, 240×240 m.
- Mountains: ring of 10 hills (34×12 m) at ~128 m radius + a northern ridge of 3 big mountains (45×22 m, up to 22 m high).
- 40 rocks + 12 emissive crystals, kept out of villages and off streets.
