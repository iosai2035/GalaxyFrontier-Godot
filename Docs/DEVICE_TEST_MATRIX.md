# Device Test Matrix — Galaxy Frontier (Godot)

The game is built for all iOS screen sizes: every UI element uses anchors/containers (no fixed pixel positions), sizes are viewport fractions, and Safe Areas (notch / Dynamic Island / iPad edges) are applied on every screen via `DisplayServer.get_display_safe_area()`.

**Honest rule:** fields that cannot be measured without a real device are left **empty** — never filled with fake values. Only the Linux headless checks in this row are real.

| Device | Size (pt) | Aspect | Notch / Dynamic Island | Status |
|---|---|---|---|---|
| iPhone SE (3rd gen) | 375×667 | 16:9 | none | NOT TESTED — no device |
| iPhone 14/15/16 (normal) | 393×852 | 19.5:9 | Dynamic Island | NOT TESTED — no device |
| iPhone Pro Max | 430×932 | 19.5:9 | Dynamic Island | NOT TESTED — no device |
| iPad (10.9") | 820×1180 | 4:3-ish | none | NOT TESTED — no device |
| iPad Pro 12.9" | 1024×1366 | 4:3 | none | NOT TESTED — no device |
| Linux desktop (headless, this VM) | 1280×720 | 16:9 | none | TESTED — see report |

## Layout checks done here (headless)

`tests/verify_godot.gd` resizes the viewport to iPhone SE (667×375 landscape), iPhone normal (852×393), Pro Max (932×430) and iPad 12.9" (1366×1024) landscape sizes and verifies the HUD lays out without errors at each size (anchors recompute, no crashes). That proves the layout code runs at those sizes — it does **not** prove how it looks on a real device. Visual check on real hardware is still required.
