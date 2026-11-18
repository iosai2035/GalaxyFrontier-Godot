## Galaxy Frontier — Game data (shared tables).
## Playable characters and enemy types. All original
## designs — no copies, no real-person likenesses.
class_name GFGameData

## Playable characters. Each has a distinct look (suit color, body
## scale, helmet) and a starting weapon. Health and speed are the
## same for all four — the difference is look + starting weapon.
const CHARACTER_PROFILES := {
	"nova": {
		"name": "Nova", "role": "Scout",
		"suit_color": "#2ec8f0", "body_scale": 0.92, "helmet": false,
		"weapon": "smg",
		"desc": "Fast scout in light cyan armor. Starts with an SMG.",
	},
	"atlas": {
		"name": "Atlas", "role": "Heavy",
		"suit_color": "#4caf50", "body_scale": 1.12, "helmet": true,
		"weapon": "shotgun",
		"desc": "Heavy trooper in green armor with a helmet. Starts with a Shotgun.",
	},
	"vex": {
		"name": "Vex", "role": "Assault",
		"suit_color": "#ff7a1a", "body_scale": 1.0, "helmet": false,
		"weapon": "rifle",
		"desc": "Assault specialist in orange armor. Starts with an Assault Rifle.",
	},
	"luna": {
		"name": "Luna", "role": "Sharpshooter",
		"suit_color": "#9d7fd6", "body_scale": 0.95, "helmet": true,
		"weapon": "sniper",
		"desc": "Sharpshooter in violet armor with a helmet. Starts with a Sniper Rifle.",
	},
}

## Enemy types. Stats and behavior differ per type.
##   grunt   — standard: balanced, melee, patrols and chases.
##   runner  — fast, fragile: rushes the player, low damage.
##   armored — slow tank: 25% damage reduction, heavy melee.
##   sniper  — ranged: keeps 10–25 m, shoots every 2.5 s.
##   boss    — guardian: 500 HP, 15% reduction, big, heavy melee.
const ENEMY_TYPES := {
	"grunt": {
		"name": "Grunt", "hp": 100.0, "chase_speed": 4.5,
		"damage": 12.0, "detect_range": 18.0, "attack_range": 2.2,
		"attack_cooldown": 1.2, "scale": 1.0,
		"color": Color(0.75, 0.15, 0.15), "damage_reduction": 0.0,
		"ranged": false,
	},
	"runner": {
		"name": "Runner", "hp": 60.0, "chase_speed": 7.0,
		"damage": 8.0, "detect_range": 20.0, "attack_range": 2.0,
		"attack_cooldown": 0.9, "scale": 0.9,
		"color": Color(1.0, 0.55, 0.1), "damage_reduction": 0.0,
		"ranged": false,
	},
	"armored": {
		"name": "Armored", "hp": 220.0, "chase_speed": 3.2,
		"damage": 16.0, "detect_range": 15.0, "attack_range": 2.4,
		"attack_cooldown": 1.5, "scale": 1.15,
		"color": Color(0.35, 0.45, 0.6), "damage_reduction": 0.25,
		"ranged": false,
	},
	"sniper": {
		"name": "Sniper", "hp": 70.0, "chase_speed": 3.5,
		"damage": 20.0, "detect_range": 25.0, "attack_range": 25.0,
		"attack_cooldown": 2.5, "scale": 1.0,
		"color": Color(0.15, 0.45, 0.2), "damage_reduction": 0.0,
		"ranged": true,
	},
	"boss": {
		"name": "Guardian", "hp": 500.0, "chase_speed": 3.8,
		"damage": 25.0, "detect_range": 25.0, "attack_range": 3.0,
		"attack_cooldown": 1.6, "scale": 1.5,
		"color": Color(0.85, 0.65, 0.1), "damage_reduction": 0.15,
		"ranged": false,
	},
}

## Loot dropped by each enemy type (loot box contents).
const ENEMY_DROPS := {
	"grunt": {"ammo_rifle": 30, "ammo_pistol": 12, "medkit": 1, "shield_cell": 1},
	"runner": {"ammo_rifle": 30, "medkit": 1},
	"armored": {"ammo_rifle": 60, "shield_cell": 2},
	"sniper": {"ammo_sniper": 10, "medkit": 1},
	"boss": {"ammo_rifle": 90, "ammo_pistol": 24, "medkit": 2, "shield_cell": 2},
}
