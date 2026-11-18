## Galaxy Frontier — Enemy (Godot rebuild).
## Simple state machine: PATROL / CHASE / ATTACK / RETREAT / DEAD.
## Detects the player by distance + line of sight. Body is built
## from primitives — no imported meshes. Five types (see
## GFGameData.ENEMY_TYPES): grunt, runner, armored, sniper (ranged),
## boss/guardian. Stats and behavior differ per type.
class_name GFEnemy
extends CharacterBody3D

signal died(enemy: GFEnemy)

enum State { PATROL, CHASE, ATTACK, RETREAT, DEAD }

const PATROL_SPEED := 2.0
const RETREAT_SPEED := 3.5
const GRAVITY := 20.0

var enemy_type: String = "grunt"
var health: float = 100.0
var max_health: float = 100.0
var state: int = State.PATROL
var patrol_points: Array[Vector3] = []
var patrol_index: int = 0
var attack_timer: float = 0.0
var retreat_timer: float = 0.0
var target: Node3D = null
# Line of sight is re-checked only every 0.25 s (staggered per enemy
# by a random offset) — never a raycast every physics frame.
var _los_timer: float = 0.0
var _sees_player: bool = false
var _type_data: Dictionary = {}

var _mesh_root: Node3D


## Sets the enemy type BEFORE the node enters the tree (world
## calls this right after instantiate). Applies stats + look.
func configure(type_id: String) -> void:
	if GFGameData.ENEMY_TYPES.has(type_id):
		enemy_type = type_id
	_type_data = GFGameData.ENEMY_TYPES.get(enemy_type, {})
	max_health = float(_type_data.get("hp", 100.0))
	health = max_health


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 2
	collision_mask = 1
	if _type_data.is_empty():
		configure(enemy_type)
	var type_scale := float(_type_data.get("scale", 1.0))
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3 * type_scale
	capsule.height = 1.8 * type_scale
	shape.shape = capsule
	# Same feet-at-origin convention as the player.
	shape.position = Vector3(0.0, 0.9 * type_scale, 0.0)
	add_child(shape)
	_build_body()
	target = get_tree().get_first_node_in_group("player")
	_los_timer = randf() * 0.25


func _build_body() -> void:
	_mesh_root = Node3D.new()
	var type_scale := float(_type_data.get("scale", 1.0))
	_mesh_root.scale = Vector3.ONE * type_scale
	add_child(_mesh_root)
	var armor := GFMaterials.fabric(_type_data.get("color", Color(0.75, 0.15, 0.15)))
	var dark := GFMaterials.fabric(Color(0.1, 0.1, 0.12))
	var eye := GFMaterials.emissive(Color(1.0, 0.15, 0.1), 2.0)
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.26
	capsule.height = 1.0
	body.mesh = capsule
	body.material_override = armor
	body.position = Vector3(0.0, 1.05, 0.0)
	_mesh_root.add_child(body)
	for leg_x in [-0.11, 0.11]:
		var leg := MeshInstance3D.new()
		var leg_box := BoxMesh.new()
		leg_box.size = Vector3(0.17, 0.8, 0.2)
		leg.mesh = leg_box
		leg.material_override = dark
		leg.position = Vector3(leg_x, 0.4, 0.0)
		_mesh_root.add_child(leg)
	var head := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.26, 0.28, 0.26)
	head.mesh = box
	head.material_override = dark
	head.position = Vector3(0.0, 1.72, 0.0)
	_mesh_root.add_child(head)
	for eye_x in [-0.07, 0.07]:
		var eye_mesh := MeshInstance3D.new()
		var eye_box := BoxMesh.new()
		eye_box.size = Vector3(0.06, 0.04, 0.03)
		eye_mesh.mesh = eye_box
		eye_mesh.material_override = eye
		eye_mesh.position = Vector3(eye_x, 1.74, -0.14)
		_mesh_root.add_child(eye_mesh)
	# Sniper carries a long rifle; the boss wears a gold crest.
	if bool(_type_data.get("ranged", false)):
		var rifle := MeshInstance3D.new()
		var rifle_box := BoxMesh.new()
		rifle_box.size = Vector3(0.08, 0.08, 1.4)
		rifle.mesh = rifle_box
		rifle.material_override = dark
		rifle.position = Vector3(0.3, 1.2, -0.3)
		_mesh_root.add_child(rifle)
	if enemy_type == "boss":
		var crest := MeshInstance3D.new()
		var crest_box := BoxMesh.new()
		crest_box.size = Vector3(0.2, 0.4, 0.1)
		crest.mesh = crest_box
		var gold := StandardMaterial3D.new()
		gold.albedo_color = Color(1.0, 0.85, 0.2)
		gold.emission_enabled = true
		gold.emission = Color(1.0, 0.85, 0.2)
		gold.emission_energy_multiplier = 0.6
		crest.material_override = gold
		crest.position = Vector3(0.0, 2.05, 0.0)
		_mesh_root.add_child(crest)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	if target == null or (target is GFPlayer and (target as GFPlayer).dead):
		_apply_gravity(delta)
		move_and_slide()
		return
	attack_timer = maxf(0.0, attack_timer - delta)
	_apply_gravity(delta)
	var to_player: Vector3 = target.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()
	var detect_range := float(_type_data.get("detect_range", 18.0))
	var attack_range := float(_type_data.get("attack_range", 2.2))
	var chase_speed := float(_type_data.get("chase_speed", 4.5))
	var attack_damage := float(_type_data.get("damage", 12.0))
	var attack_cooldown := float(_type_data.get("attack_cooldown", 1.2))
	var ranged := bool(_type_data.get("ranged", false))
	var retreat_health := max_health * 0.25
	_los_timer -= delta
	if _los_timer <= 0.0:
		_los_timer = 0.25
		_sees_player = dist < detect_range and _has_line_of_sight()
	var sees_player := _sees_player
	if health <= retreat_health and state != State.RETREAT and not ranged:
		state = State.RETREAT
		retreat_timer = 3.0
	match state:
		State.PATROL:
			if sees_player:
				state = State.CHASE
			else:
				_patrol(delta)
		State.CHASE:
			if not sees_player and dist > detect_range * 1.3:
				state = State.PATROL
			elif dist <= attack_range:
				state = State.ATTACK
			else:
				# Ranged sniper keeps 10–25 m: backs off when too
				# close, closes in when too far, then shoots.
				if ranged and dist < 10.0:
					_move_toward(-to_player.normalized(), chase_speed, delta)
				else:
					_move_toward(to_player.normalized(), chase_speed, delta)
		State.ATTACK:
			if ranged:
				# Shoot from range while line of sight holds.
				if dist > attack_range * 1.4 or not sees_player:
					state = State.CHASE
				elif attack_timer <= 0.0:
					attack_timer = attack_cooldown
					if target.has_method("take_damage"):
						target.take_damage(attack_damage)
			else:
				if dist > attack_range * 1.4:
					state = State.CHASE
				elif attack_timer <= 0.0:
					attack_timer = attack_cooldown
					if target.has_method("take_damage"):
						target.take_damage(attack_damage)
		State.RETREAT:
			retreat_timer -= delta
			_move_toward(-to_player.normalized(), RETREAT_SPEED, delta)
			if retreat_timer <= 0.0:
				state = State.CHASE if sees_player else State.PATROL
	move_and_slide()


func _patrol(delta: float) -> void:
	if patrol_points.is_empty():
		velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
		return
	var goal: Vector3 = patrol_points[patrol_index]
	var flat := goal - global_position
	flat.y = 0.0
	if flat.length() < 1.0:
		patrol_index = (patrol_index + 1) % patrol_points.size()
		return
	_move_toward(flat.normalized(), PATROL_SPEED, delta)


func _move_toward(dir: Vector3, speed: float, delta: float) -> void:
	velocity.x = move_toward(velocity.x, dir.x * speed, 20.0 * delta)
	velocity.z = move_toward(velocity.z, dir.z * speed, 20.0 * delta)
	if dir.length() > 0.1:
		var target_yaw := atan2(-dir.x, -dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, minf(1.0, 10.0 * delta))


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0


func _has_line_of_sight() -> bool:
	if target == null:
		return false
	var from: Vector3 = global_position + Vector3(0.0, 1.6, 0.0)
	var to: Vector3 = target.global_position + Vector3(0.0, 1.2, 0.0)
	var query := PhysicsRayQueryParameters3D.create(from, to, 1, [self])
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty()


func take_damage(amount: float, _from_player: bool = false) -> void:
	if state == State.DEAD:
		return
	# Armored (25%) and boss (15%) reduce incoming damage.
	var reduction := float(_type_data.get("damage_reduction", 0.0))
	health -= amount * (1.0 - reduction)
	if health <= 0.0:
		health = 0.0
		_die()
	elif health <= max_health * 0.25:
		state = State.RETREAT
		retreat_timer = 3.0


func _die() -> void:
	state = State.DEAD
	collision_layer = 0
	collision_mask = 0
	velocity = Vector3.ZERO
	died.emit(self)
	var tween := create_tween()
	tween.tween_property(_mesh_root, "rotation:x", deg_to_rad(-90.0), 0.4)
	tween.tween_interval(2.5)
	tween.tween_callback(queue_free)
