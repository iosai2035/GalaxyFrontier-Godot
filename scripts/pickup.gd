## Galaxy Frontier — Pickup (world item).
## Health / shield / ammo / mission items lying on the ground or on
## top of crates and surfaces. The player picks them up by walking
## close and pressing Interact (or the USE button): the item enters
## the inventory immediately and the HUD shows a clear notification.
## Pickups respawn 30 s after being taken.
class_name GFPickup
extends GFInteractable

const ITEM_INFO := {
	"medkit": {"name": "Medkit", "color": Color(0.2, 0.9, 0.3)},
	"shield_cell": {"name": "Shield Cell", "color": Color(0.2, 0.6, 1.0)},
	"ammo_rifle": {"name": "Rifle Ammo (+30)", "color": Color(1.0, 0.8, 0.2)},
	"ammo_pistol": {"name": "Pistol Ammo (+12)", "color": Color(1.0, 0.6, 0.2)},
	"core_fragment": {"name": "Core Fragment", "color": Color(0.2, 0.9, 0.95)},
}

@export var item_id: String = "medkit"
@export var amount: int = 1

var _visual: MeshInstance3D
var _spin: float = 0.0


func _ready() -> void:
	super._ready()
	action = "pickup"
	var info: Dictionary = ITEM_INFO.get(item_id, ITEM_INFO["medkit"])
	prompt = "Take %s" % String(info["name"])
	_visual = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.45, 0.45, 0.45)
	_visual.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = info["color"]
	mat.emission_enabled = true
	mat.emission = info["color"]
	mat.emission_energy_multiplier = 1.2
	_visual.material_override = mat
	_visual.position = Vector3(0.0, 0.6, 0.0)
	add_child(_visual)


func _process(delta: float) -> void:
	_spin += delta
	if _visual != null:
		_visual.rotation.y = _spin
		_visual.position.y = 0.6 + sin(_spin * 2.0) * 0.08


## Applies the pickup to the player. Returns a human-readable result
## for the HUD notification (empty string = nothing was taken).
func apply_to(player: GFPlayer) -> String:
	var info: Dictionary = ITEM_INFO.get(item_id, ITEM_INFO["medkit"])
	var taken := 0
	match item_id:
		"ammo_rifle":
			taken = player.add_ammo("rifle", 30 * amount)
			if taken <= 0:
				return ""
		"ammo_pistol":
			taken = player.add_ammo("pistol", 12 * amount)
			if taken <= 0:
				return ""
		_:
			taken = player.add_item(item_id, amount)
			if taken <= 0:
				return ""
	set_used()
	_visual.visible = false
	var timer := get_tree().create_timer(30.0)
	timer.timeout.connect(_respawn)
	SoundManager.play_pickup()
	return "Picked up: %s x%d" % [String(info["name"]), taken]


func _respawn() -> void:
	usable = true
	if _visual != null:
		_visual.visible = true
