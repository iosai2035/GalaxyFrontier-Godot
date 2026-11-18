## Galaxy Frontier — Loot box.
## Drops where an enemy dies (and, in a later multiplayer phase,
## where a player is eliminated). Holds the fallen one's contents:
## ammo, medkits and shield cells. The player opens it and takes
## what fits: the inventory cap decides — anything that does not fit
## stays in the box. The box vanishes only when fully empty.
class_name GFLootBox
extends GFInteractable

const STANDARD_DROPS := {
	"ammo_rifle": 30,
	"ammo_pistol": 12,
	"medkit": 1,
	"shield_cell": 1,
}

var contents: Dictionary = {}

var _visual: MeshInstance3D


func _ready() -> void:
	super._ready()
	action = "loot"
	prompt = "Open Loot Box"
	_visual = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.9, 0.6, 0.9)
	_visual.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.65, 0.15)
	mat.emission_enabled = true
	mat.emission = Color(0.85, 0.65, 0.15)
	mat.emission_energy_multiplier = 0.7
	_visual.material_override = mat
	_visual.position = Vector3(0.0, 0.35, 0.0)
	add_child(_visual)
	if contents.is_empty():
		contents = STANDARD_DROPS.duplicate()


func set_drops(drops: Dictionary) -> void:
	contents = drops.duplicate()
	if contents.is_empty():
		set_used()


func is_empty() -> bool:
	for key in contents:
		if int(contents[key]) > 0:
			return false
	return true


## Takes one item type out of the box. Returns how many were taken.
## Anything that does not fit in the player's inventory/ammo stays.
func take_item(item_id: String, player: GFPlayer) -> int:
	var have: int = int(contents.get(item_id, 0))
	if have <= 0:
		return 0
	var taken := 0
	if item_id.begins_with("ammo_"):
		# Any weapon ammo: "ammo_sniper" -> sniper, etc.
		taken = player.add_ammo(item_id.substr(5), have)
	else:
		match item_id:
			"ammo_rifle":
				taken = player.add_ammo("rifle", have)
			"ammo_pistol":
				taken = player.add_ammo("pistol", have)
			_:
				taken = player.add_item(item_id, have)
	contents[item_id] = have - taken
	if int(contents[item_id]) <= 0:
		contents.erase(item_id)
	_check_empty()
	return taken


func take_all(player: GFPlayer) -> Dictionary:
	var result := {}
	for item_id in contents.keys():
		result[item_id] = take_item(item_id, player)
	return result


func _check_empty() -> void:
	if is_empty():
		set_used()
		if _visual != null:
			_visual.visible = false
