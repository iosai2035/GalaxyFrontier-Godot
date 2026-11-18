## Galaxy Frontier — Ground vehicle (Rover RX-7, Godot rebuild).
## CharacterBody3D rover, built from primitives with realistic
## real-world dimensions: 4.5 m long x 1.9 m wide x 1.5 m tall
## (without roof rack), wheels 0.8 m in diameter. Details: painted
## metal body panels, reflective glass cabin, headlights and
## taillights, front bumper, exhaust pipe, roll bars and side
## mirrors. The player enters with the on-screen RIDE button; while
## driving, the HUD shows driving controls (Accelerate / Brake +
## steering joystick + EXIT) and hides the walk/combat buttons.
## Exit is refused while moving faster than 2 m/s. The rover takes
## damage instead of the driver.
class_name GFVehicle
extends CharacterBody3D

signal entered(vehicle: GFVehicle)
signal exited(vehicle: GFVehicle)

const VEHICLE_LENGTH := 4.5
const VEHICLE_WIDTH := 1.9
const WHEEL_RADIUS := 0.4
const MAX_SPEED := 18.0
const ACCEL := 12.0
const BRAKE := 24.0
const REVERSE_SPEED := 6.0
const TURN_RATE := 1.6
const EXIT_MIN_SPEED := 2.0
const MAX_HEALTH := 250.0
const GRAVITY := 20.0

var health: float = MAX_HEALTH
var speed: float = 0.0
var driver: GFPlayer = null
var throttle: float = 0.0  # -1 brake/reverse .. 1 accelerate (from HUD)
var steer: float = 0.0  # -1 left .. 1 right (from HUD joystick)

var _mesh_root: Node3D
var _wheels: Array[MeshInstance3D] = []


func _ready() -> void:
	add_to_group("vehicles")
	collision_layer = 4
	collision_mask = 1
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(VEHICLE_WIDTH, 1.2, VEHICLE_LENGTH)
	shape.shape = box
	# Bottom at local y=0 so the wheels (bottom at local y=0) touch
	# the ground exactly when the body rests on it.
	shape.position = Vector3(0.0, 0.6, 0.0)
	add_child(shape)
	_build_body()


func _box(size: Vector3, pos: Vector3, mat: Material, parent: Node3D = null) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mesh.mesh = b
	mesh.material_override = mat
	mesh.position = pos
	(parent if parent != null else _mesh_root).add_child(mesh)
	return mesh


func _build_body() -> void:
	_mesh_root = Node3D.new()
	add_child(_mesh_root)
	var paint := GFMaterials.painted_metal(Color(0.85, 0.5, 0.1))
	var dark := GFMaterials.bare_metal(Color(0.08, 0.09, 0.11))
	var glass := GFMaterials.glass()
	var light_mat := GFMaterials.emissive(Color(1.0, 0.95, 0.7), 2.0)
	var tail_mat := GFMaterials.emissive(Color(0.9, 0.1, 0.1), 1.5)
	# Chassis + hood + rear bed.
	_box(Vector3(1.9, 0.5, 4.5), Vector3(0.0, 0.75, 0.0), paint)
	_box(Vector3(1.7, 0.25, 1.2), Vector3(0.0, 1.1, -1.5), paint)  # hood
	_box(Vector3(1.7, 0.15, 1.3), Vector3(0.0, 1.05, 1.5), dark)  # bed floor
	# Cabin with reflective glass, roof and roll bars.
	_box(Vector3(1.7, 0.55, 1.6), Vector3(0.0, 1.3, 0.35), glass)
	_box(Vector3(1.8, 0.08, 1.7), Vector3(0.0, 1.62, 0.35), paint)  # roof
	for bx in [-0.8, 0.8]:
		_box(Vector3(0.08, 0.5, 0.08), Vector3(bx, 1.85, -0.4), dark)  # roll bars
		_box(Vector3(0.08, 0.5, 0.08), Vector3(bx, 1.85, 1.1), dark)
	_box(Vector3(1.7, 0.06, 0.06), Vector3(0.0, 2.08, -0.4), dark)
	_box(Vector3(1.7, 0.06, 0.06), Vector3(0.0, 2.08, 1.1), dark)
	# Front bumper, grille, headlights, taillights, mirrors, exhaust.
	_box(Vector3(1.95, 0.18, 0.12), Vector3(0.0, 0.55, -2.28), dark)
	_box(Vector3(1.2, 0.2, 0.05), Vector3(0.0, 0.85, -2.26), dark)
	_box(Vector3(0.35, 0.15, 0.06), Vector3(-0.65, 0.95, -2.26), light_mat)
	_box(Vector3(0.35, 0.15, 0.06), Vector3(0.65, 0.95, -2.26), light_mat)
	_box(Vector3(0.3, 0.12, 0.06), Vector3(-0.7, 0.95, 2.26), tail_mat)
	_box(Vector3(0.3, 0.12, 0.06), Vector3(0.7, 0.95, 2.26), tail_mat)
	_box(Vector3(0.12, 0.08, 0.2), Vector3(-0.98, 1.35, 0.0), dark)  # mirrors
	_box(Vector3(0.12, 0.08, 0.2), Vector3(0.98, 1.35, 0.0), dark)
	var exhaust := MeshInstance3D.new()
	var exhaust_cyl := CylinderMesh.new()
	exhaust_cyl.top_radius = 0.06
	exhaust_cyl.bottom_radius = 0.06
	exhaust_cyl.height = 0.9
	exhaust.mesh = exhaust_cyl
	exhaust.material_override = dark
	exhaust.rotation.x = deg_to_rad(90.0)
	exhaust.position = Vector3(0.75, 1.0, 2.1)
	_mesh_root.add_child(exhaust)
	# Wheels: 0.8 m diameter, with hub caps.
	for wx in [-0.95, 0.95]:
		for wz in [-1.5, 1.5]:
			var wheel := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = WHEEL_RADIUS
			cyl.bottom_radius = WHEEL_RADIUS
			cyl.height = 0.3
			wheel.mesh = cyl
			wheel.material_override = dark
			wheel.rotation.z = deg_to_rad(90.0)
			wheel.position = Vector3(wx, WHEEL_RADIUS, wz)
			_mesh_root.add_child(wheel)
			_wheels.append(wheel)
			var hub := MeshInstance3D.new()
			var hub_cyl := CylinderMesh.new()
			hub_cyl.top_radius = 0.18
			hub_cyl.bottom_radius = 0.18
			hub_cyl.height = 0.32
			hub.mesh = hub_cyl
			hub.material_override = GFMaterials.bare_metal(Color(0.6, 0.62, 0.65))
			hub.rotation.z = deg_to_rad(90.0)
			hub.position = Vector3(wx, WHEEL_RADIUS, wz)
			_mesh_root.add_child(hub)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	if driver == null:
		velocity.x = move_toward(velocity.x, 0.0, BRAKE * delta)
		velocity.z = move_toward(velocity.z, 0.0, BRAKE * delta)
		move_and_slide()
		return
	var target_speed := 0.0
	if throttle > 0.0:
		target_speed = MAX_SPEED * throttle
	elif throttle < 0.0:
		target_speed = -REVERSE_SPEED * -throttle
	if throttle < 0.0 and speed > 0.5:
		speed = move_toward(speed, 0.0, BRAKE * delta)
	else:
		var rate := ACCEL if throttle > 0.0 else BRAKE
		speed = move_toward(speed, target_speed, rate * delta)
	if absf(speed) > 0.5:
		rotation.y -= steer * TURN_RATE * delta * clampf(absf(speed) / 6.0, 0.0, 1.0) * signf(speed)
	var forward := -global_transform.basis.z
	velocity.x = forward.x * speed
	velocity.z = forward.z * speed
	move_and_slide()
	# Wheel spin matches ground speed (real scale: omega = v / r).
	var spin := speed * delta / WHEEL_RADIUS
	for wheel in _wheels:
		wheel.rotation.x += spin


func can_enter() -> bool:
	return driver == null


func enter(player: GFPlayer) -> bool:
	if driver != null:
		return false
	driver = player
	player.set_driving(true, self)
	player.global_position = global_position + Vector3(0.0, 1.2, 0.0)
	entered.emit(self)
	return true


func try_exit() -> bool:
	if driver == null:
		return false
	if absf(speed) > EXIT_MIN_SPEED:
		return false
	var player := driver
	driver = null
	throttle = 0.0
	steer = 0.0
	speed = 0.0
	var side := global_transform.basis.x
	player.global_position = global_position + side * 2.5 + Vector3(0.0, 0.5, 0.0)
	player.set_driving(false, null)
	exited.emit(self)
	return true


func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0.0:
		health = 0.0
		if driver != null:
			try_exit()
