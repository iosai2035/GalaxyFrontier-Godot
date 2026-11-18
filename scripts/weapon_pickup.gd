## Galaxy Frontier — Weapon pickup.
## A weapon lying in the world (on a crate, in the station, at the
## range). Interact to take it: it enters the player's loadout
## (replacing the secondary slot when both slots are full) with a
## full magazine and reserve. Respawn: none — one per match.
class_name GFWeaponPickup
extends GFInteractable

@export var weapon_key: String = "smg"

var _visual: MeshInstance3D


func _ready() -> void:
	super._ready()
	action = "weapon"
	var w: Dictionary = GFPlayer.WEAPONS.get(weapon_key, {})
	prompt = "Take %s" % String(w.get("name", weapon_key))
	_visual = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.9, 0.25, 0.3)
	_visual.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.75, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.75, 0.2)
	mat.emission_energy_multiplier = 0.8
	_visual.material_override = mat
	_visual.position = Vector3(0.0, 0.6, 0.0)
	add_child(_visual)


func _process(delta: float) -> void:
	if _visual != null:
		_visual.rotation.y += delta * 1.5


func apply_to(player: GFPlayer) -> String:
	if player.give_weapon(weapon_key):
		set_used()
		_visual.visible = false
		SoundManager.play_pickup()
		var w: Dictionary = GFPlayer.WEAPONS.get(weapon_key, {})
		return "Picked up: %s" % String(w.get("name", weapon_key))
	return ""
