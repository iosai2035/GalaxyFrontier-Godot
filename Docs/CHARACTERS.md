# Characters — Galaxy Frontier (Godot)

All designs are original, built from primitives in code — no copies, no real-person likeness.

## Playable characters (4)

Health 100 + shield 100 and movement speeds (5 / 8 / 11 m/s) are the same for all four — the difference is look and starting weapon.

| Character | Role | Suit | Body scale | Helmet | Starting weapon |
|---|---|---|---|---|---|
| Nova | Scout | cyan `#2ec8f0` | 0.92 | no | SMG |
| Atlas | Heavy | green `#4caf50` | 1.12 | yes | Shotgun |
| Vex | Assault | orange `#ff7a1a` | 1.00 | no | Assault Rifle |
| Luna | Sharpshooter | violet `#9d7fd6` | 0.95 | yes | Sniper Rifle |

Selection is in the main menu (Character section) and is saved; suit color swatches and the helmet toggle there are free customization that applies on top. Character height: 1.8 m, head 0.26 m, shoulders ~0.5 m (real human proportions, 1 unit = 1 m).

## Enemy types (5)

| Type | HP | Chase speed | Damage | Detect | Attack | Behavior |
|---|---|---|---|---|---|---|
| Grunt | 100 | 4.5 m/s | 12 melee | 18 m | 2.2 m, 1.2 s | balanced; patrols, chases, retreats < 25 HP |
| Runner | 60 | 7.0 m/s | 8 melee | 20 m | 2.0 m, 0.9 s | fast, fragile; rushes the player |
| Armored | 220 | 3.2 m/s | 16 melee | 15 m | 2.4 m, 1.5 s | slow tank; 25% damage reduction |
| Sniper | 70 | 3.5 m/s | 20 ranged | 25 m | 25 m, 2.5 s | keeps 10–25 m, shoots with line of sight |
| Guardian (boss) | 500 | 3.8 m/s | 25 melee | 25 m | 3.0 m, 1.6 s | big (1.5× scale), gold crest; 15% damage reduction |

Enemy sizes: scale 0.9 (runner) – 1.0 (grunt/sniper) – 1.15 (armored) – 1.5 (boss), all at the same 1.8 m base height.

## Loot per enemy type

| Type | Loot box contents |
|---|---|
| Grunt | 30 rifle ammo, 12 pistol ammo, 1 medkit, 1 shield cell |
| Runner | 30 rifle ammo, 1 medkit |
| Armored | 60 rifle ammo, 2 shield cells |
| Sniper | 10 sniper ammo, 1 medkit |
| Guardian | 90 rifle ammo, 24 pistol ammo, 2 medkits, 2 shield cells |
