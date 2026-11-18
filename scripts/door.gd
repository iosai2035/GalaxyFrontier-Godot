## Galaxy Frontier — Door (auto, PUBG-style).
## Opens automatically when the player comes close — no interact
## button for normal doors — and closes automatically after the
## player has passed and moved away. Real-world scale: the leaf is
## 1.2 m wide x 2.1 m high (standard single door), sliding sideways
## 1.35 m with a visible tween and a procedural sound; while open
## its collision is disabled so the player can walk through.
## PBR painted-metal leaf + frame + handle.
class_name GFDoor
extends Node3D

const DOOR_WIDTH := 1.2
const DOOR_HEIGHT := 2.1
const OPEN_DISTANCE := 3.0
const CLOSE_DISTANCE := 4.5
const CHECK_INTERVAL := 0.1
const SLIDE_DISTANCE := 1.35

var open_amount: float = 0.0  # 0 closed .. 1 open
var is_open: bool = false

var _mesh: MeshInstance3D
var _body: StaticBody3D
var _check_timer: float = 0.0
var _tween: Tween = null
var _player: Node3D = null


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	# Frame (two jambs + lintel) — static, always present.
	var frame_mat := GFMaterials.bare_metal(Color(0.3, 0.31, 0.34))
	for side in [-1.0, 1.0]:
		var jamb := MeshInstance3D.new()
		var jamb_box := BoxMesh.new()
		jamb_box.size = Vector3(0.12, DOOR_HEIGHT + 0.12, 0.18)
		jamb.mesh = jamb_box
		jamb.material_override = frame_mat
		jamb.position = Vector3(side * (DOOR_WIDTH / 2.0 + 0.06), (DOOR_HEIGHT + 0.12) / 2.0, 0.0)
		add_child(jamb)
	var lintel := MeshInstance3D.new()
	var lintel_box := BoxMesh.new()
	lintel_box.size = Vector3(DOOR_WIDTH + 0.36, 0.12, 0.18)
	lintel.mesh = lintel_box
	lintel.material_override = frame_mat
	lintel.position = Vector3(0.0, DOOR_HEIGHT + 0.06, 0.0)
	add_child(lintel)
	# Leaf: painted metal with two recessed panels and a handle.
	_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(DOOR_WIDTH, DOOR_HEIGHT, 0.08)
	_mesh.mesh = box
	_mesh.material_override = GFMaterials.painted_metal(Color(0.2, 0.55, 0.55))
	_mesh.position = Vector3(0.0, DOOR_HEIGHT / 2.0, 0.0)
	add_child(_mesh)
	for panel_y in [0.6, 1.55]:
		var panel := MeshInstance3D.new()
		var panel_box := BoxMesh.new()
		panel_box.size = Vector3(0.8, 0.6, 0.03)
		panel.mesh = panel_box
		panel.material_override = GFMaterials.bare_metal(Color(0.16, 0.45, 0.45))
		panel.position = Vector3(0.0, panel_y, -0.05)
		_mesh.add_child(panel)
	var handle := MeshInstance3D.new()
	var handle_box := BoxMesh.new()
	handle_box.size = Vector3(0.05, 0.05, 0.22)
	handle.mesh = handle_box
	handle.material_override = GFMaterials.bare_metal(Color(0.8, 0.8, 0.82))
	handle.position = Vector3(-DOOR_WIDTH / 2.0 + 0.15, 1.05, -0.12)
	_mesh.add_child(handle)
	_body = StaticBody3D.new()
	_body.collision_layer = 1
	_body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(DOOR_WIDTH, DOOR_HEIGHT, 0.12)
	shape.shape = box_shape
	shape.position = Vector3(0.0, DOOR_HEIGHT / 2.0, 0.0)
	_body.add_child(shape)
	add_child(_body)


func _process(delta: float) -> void:
	_check_timer -= delta
	if _check_timer > 0.0:
		return
	_check_timer = CHECK_INTERVAL
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		return
	var dist: float = global_position.distance_to(_player.global_position)
	if not is_open and dist <= OPEN_DISTANCE:
		_set_open(true)
	elif is_open and dist >= CLOSE_DISTANCE:
		_set_open(false)


func _set_open(value: bool) -> void:
	if value == is_open:
		return
	is_open = value
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	var target_x := SLIDE_DISTANCE if value else 0.0
	_tween.tween_property(_mesh, "position:x", target_x, 0.7).set_trans(Tween.TRANS_SINE)
	if value:
		_body.set_deferred("collision_layer", 0)
		SoundManager.play_door()
	else:
		_body.set_deferred("collision_layer", 1)
		SoundManager.play_door()
	open_amount = 1.0 if value else 0.0


## Test helper: force the door state without a player nearby.
func force_open(value: bool) -> void:
	_set_open(value)
