## Galaxy Frontier — Player (third-person, Godot rebuild).
## CharacterBody3D. Body is built from primitives (capsule + boxes)
## in _ready — no imported meshes. Health 100 + Shield 100, shield
## absorbs damage first. Two hitscan weapons: Pistol and Assault Rifle.
class_name GFPlayer
extends CharacterBody3D

signal health_changed(health: float, shield: float)
signal ammo_changed(weapon_name: String, mag: int, reserve: int)
signal weapon_changed(weapon_name: String)
signal inventory_changed(inventory: Dictionary)
signal died
signal interact_prompt_changed(text: String)

const WALK_SPEED := 5.0
const RUN_SPEED := 8.0
const SPRINT_SPEED := 11.0
const CROUCH_SPEED := 2.5
const ACCEL := 20.0
const JUMP_VELOCITY := 7.0
const GRAVITY := 20.0
const MAX_HEALTH := 100.0
const MAX_SHIELD := 100.0
const INTERACT_RANGE := 3.2
# Inventory caps: what does not fit stays in the loot box / on the ground.
const ITEM_CAPS := {"medkit": 5, "shield_cell": 5, "core_fragment": 3}
const ITEM_NAMES := {
	"medkit": "Medkit (+50 HP)",
	"shield_cell": "Shield Cell (+50 Shield)",
	"core_fragment": "Core Fragment (mission item)",
}

## Full weapon table (also in Docs/WEAPONS.md):
##   key     | damage | rate/s | mag | reserve | range | reload | spread | zoom  | scope    | pellets | splash
##   pistol  | 20     | 3.0    | 12  | 120     | 80 m  | 1.1 s  | 1.5°   | 0.85  | iron     | 1       | -
##   smg     | 14     | 12.0   | 32  | 192     | 60 m  | 1.4 s  | 3.0°   | 0.80  | iron     | 1       | -
##   rifle   | 18     | 10.0   | 30  | 240     | 100 m | 1.8 s  | 2.0°   | 0.80  | iron     | 1       | -
##   sniper  | 85     | 0.8    | 5   | 30      | 200 m | 2.5 s  | 0.3°   | 0.45  | scope_8x | 1       | -
##   shotgun | 12/pel | 1.2    | 6   | 36      | 30 m  | 2.8 s  | 6.0°   | 0.85  | iron     | 6       | -
##   energy  | 24     | 5.0    | 24  | 144     | 120 m | 1.6 s  | 1.0°   | 0.75  | scope_4x | 1       | -
##   launcher| 90     | 0.7    | 4   | 16      | 150 m | 3.0 s  | 1.0°   | 0.85  | iron     | 1       | 3.0 m
const WEAPONS := {
	"pistol": {
		"name": "Pistol", "damage": 20.0, "fire_interval": 0.33,
		"mag_size": 12, "reserve_max": 120, "range": 80.0, "reload_time": 1.1,
		"spread_deg": 1.5, "zoom": 0.85, "scope": "iron", "pellets": 1, "splash": 0.0,
	},
	"smg": {
		"name": "SMG", "damage": 14.0, "fire_interval": 0.083,
		"mag_size": 32, "reserve_max": 192, "range": 60.0, "reload_time": 1.4,
		"spread_deg": 3.0, "zoom": 0.80, "scope": "iron", "pellets": 1, "splash": 0.0,
	},
	"rifle": {
		"name": "Assault Rifle", "damage": 18.0, "fire_interval": 0.1,
		"mag_size": 30, "reserve_max": 240, "range": 100.0, "reload_time": 1.8,
		"spread_deg": 2.0, "zoom": 0.80, "scope": "iron", "pellets": 1, "splash": 0.0,
	},
	"sniper": {
		"name": "Sniper Rifle", "damage": 85.0, "fire_interval": 1.25,
		"mag_size": 5, "reserve_max": 30, "range": 200.0, "reload_time": 2.5,
		"spread_deg": 0.3, "zoom": 0.45, "scope": "scope_8x", "pellets": 1, "splash": 0.0,
	},
	"shotgun": {
		"name": "Shotgun", "damage": 12.0, "fire_interval": 0.83,
		"mag_size": 6, "reserve_max": 36, "range": 30.0, "reload_time": 2.8,
		"spread_deg": 6.0, "zoom": 0.85, "scope": "iron", "pellets": 6, "splash": 0.0,
	},
	"energy": {
		"name": "Energy Rifle", "damage": 24.0, "fire_interval": 0.2,
		"mag_size": 24, "reserve_max": 144, "range": 120.0, "reload_time": 1.6,
		"spread_deg": 1.0, "zoom": 0.75, "scope": "scope_4x", "pellets": 1, "splash": 0.0,
	},
	"launcher": {
		"name": "Launcher", "damage": 90.0, "fire_interval": 1.4,
		"mag_size": 4, "reserve_max": 16, "range": 150.0, "reload_time": 3.0,
		"spread_deg": 1.0, "zoom": 0.85, "scope": "iron", "pellets": 1, "splash": 3.0,
	},
}

var health: float = MAX_HEALTH
var shield: float = MAX_SHIELD
var dead: bool = false
var crouched: bool = false
var driving: bool = false
var aiming: bool = false
# Two carried weapons (loadout slots). Switch toggles between them.
var loadout: Array[String] = ["rifle", "pistol"]
var loadout_index: int = 0
var current_weapon: String = "rifle"
var ammo: Dictionary = {}
# Inventory: consumables picked up in the world. Mission items are
# tracked here too (core_fragment is not usable, only collectable).
var inventory: Dictionary = {"medkit": 0, "shield_cell": 0, "core_fragment": 0}
var fire_cooldown: float = 0.0
var reload_timer: float = 0.0
var reloading: bool = false
var switch_timer: float = 0.0
var yaw: float = 0.0
var pitch: float = 0.0

var _spring_arm: SpringArm3D
var _camera: Camera3D
var _body_mesh: MeshInstance3D
var _collision: CollisionShape3D
var _capsule: CapsuleShape3D
var _nearest_interactable: Node3D = null
var _scan_timer: float = 0.0
var _vehicle: Node3D = null
var _weapon_mesh: MeshInstance3D = null
var _muzzle_light: OmniLight3D = null
var _muzzle_timer: float = 0.0
var _dust: GPUParticles3D = null
var _recoil_pitch: float = 0.0


func _ready() -> void:
	add_to_group("player")
	collision_layer = 4
	collision_mask = 1
	_capsule = CapsuleShape3D.new()
	_capsule.radius = 0.3
	_capsule.height = 1.8
	_collision = CollisionShape3D.new()
	_collision.shape = _capsule
	# Capsule center at 0.9 m so the node origin sits at the FEET
	# (the visual body is built feet-at-origin). Without this the
	# physics body settles 0.9 m up and the character floats.
	_collision.position = Vector3(0.0, 0.9, 0.0)
	add_child(_collision)
	_build_body()
	_spring_arm = SpringArm3D.new()
	_spring_arm.spring_length = 4.2
	_spring_arm.margin = 0.3
	_spring_arm.position = Vector3(0.0, 1.6, 0.0)
	add_child(_spring_arm)
	_camera = Camera3D.new()
	_camera.fov = 75.0
	_camera.current = true
	_spring_arm.add_child(_camera)
	for key in WEAPONS:
		ammo[key] = {"mag": 0, "reserve": 0}
	# Starting weapon (from the main-menu choice) + sidearm, both
	# loaded. Other weapons are picked up in the world.
	var start_weapon := String(SaveManager.load_game().get("starting_weapon", "rifle"))
	if not WEAPONS.has(start_weapon):
		start_weapon = "rifle"
	loadout = [start_weapon, "pistol" if start_weapon != "pistol" else "rifle"]
	for key in loadout:
		ammo[key] = {"mag": WEAPONS[key]["mag_size"], "reserve": WEAPONS[key]["reserve_max"]}
	current_weapon = loadout[0]
	_emit_ammo()
	health_changed.emit(health, shield)


func _build_body() -> void:
	# Realistic human proportions (1 unit = 1 m, character 1.8 m):
	# head ~0.26 m, shoulders ~0.5 m wide, torso ~0.9 m, legs ~0.85 m.
	# Customization from the main menu (saved): suit color, body
	# type (shoulder width) and helmet. PBR fabric suit + metal armor.
	var save := SaveManager.load_game()
	var suit_color := Color.html(String(save.get("suit_color", "#2673d9")))
	var body_type := String(save.get("body_type", "male"))
	var helmet_on := bool(save.get("helmet", false))
	var suit := GFMaterials.fabric(suit_color)
	var armor := GFMaterials.bare_metal(Color(0.25, 0.26, 0.3))
	var dark := GFMaterials.fabric(Color(0.08, 0.1, 0.14))
	var visor := GFMaterials.emissive(Color(0.2, 0.9, 0.8), 1.5)
	var shoulder_w := 0.88 if body_type == "female" else 1.0
	# Torso: capsule radius 0.26, height 1.0, center y 1.05.
	_body_mesh = MeshInstance3D.new()
	var body := CapsuleMesh.new()
	body.radius = 0.26
	body.height = 1.0
	_body_mesh.mesh = body
	_body_mesh.material_override = suit
	_body_mesh.position = Vector3(0.0, 1.05, 0.0)
	_body_mesh.scale.x = shoulder_w
	add_child(_body_mesh)
	# Chest armor plate + belt.
	var plate := MeshInstance3D.new()
	var plate_box := BoxMesh.new()
	plate_box.size = Vector3(0.42 * shoulder_w, 0.5, 0.08)
	plate.mesh = plate_box
	plate.material_override = armor
	plate.position = Vector3(0.0, 1.25, -0.26)
	add_child(plate)
	var belt := MeshInstance3D.new()
	var belt_box := BoxMesh.new()
	belt_box.size = Vector3(0.46 * shoulder_w, 0.08, 0.5)
	belt.mesh = belt_box
	belt.material_override = dark
	belt.position = Vector3(0.0, 0.82, 0.0)
	add_child(belt)
	# Legs: two boxes 0.17 x 0.8 x 0.2, feet at the ground.
	for leg_x in [-0.11, 0.11]:
		var leg := MeshInstance3D.new()
		var leg_box := BoxMesh.new()
		leg_box.size = Vector3(0.17, 0.8, 0.2)
		leg.mesh = leg_box
		leg.material_override = dark
		leg.position = Vector3(leg_x, 0.4, 0.0)
		add_child(leg)
	# Arms: two boxes 0.12 x 0.7 x 0.14 at the sides.
	for arm_x in [-0.34 * shoulder_w, 0.34 * shoulder_w]:
		var arm := MeshInstance3D.new()
		var arm_box := BoxMesh.new()
		arm_box.size = Vector3(0.12, 0.7, 0.14)
		arm.mesh = arm_box
		arm.material_override = suit
		arm.position = Vector3(arm_x, 1.15, 0.0)
		add_child(arm)
	# Head: 0.26 x 0.28 x 0.26 at y 1.72 (real human head size).
	var head := MeshInstance3D.new()
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(0.26, 0.28, 0.26)
	head.mesh = head_mesh
	head.material_override = dark
	head.position = Vector3(0.0, 1.72, 0.0)
	add_child(head)
	if helmet_on:
		var helmet := MeshInstance3D.new()
		var helmet_mesh := BoxMesh.new()
		helmet_mesh.size = Vector3(0.32, 0.12, 0.32)
		helmet.mesh = helmet_mesh
		helmet.material_override = armor
		helmet.position = Vector3(0.0, 1.9, 0.0)
		add_child(helmet)
	var visor_mesh := MeshInstance3D.new()
	var visor_box := BoxMesh.new()
	visor_box.size = Vector3(0.2, 0.07, 0.03)
	visor_mesh.mesh = visor_box
	visor_mesh.material_override = visor
	visor_mesh.position = Vector3(0.0, 1.73, -0.14)
	add_child(visor_mesh)
	# Held weapon: real-size mesh, rebuilt when the weapon changes.
	_weapon_mesh = MeshInstance3D.new()
	_weapon_mesh.position = Vector3(0.28, 1.2, -0.35)
	_weapon_mesh.rotation.x = deg_to_rad(-8.0)
	add_child(_weapon_mesh)
	_update_weapon_mesh()
	# Muzzle flash light (off until firing).
	_muzzle_light = OmniLight3D.new()
	_muzzle_light.light_color = Color(1.0, 0.85, 0.4)
	_muzzle_light.light_energy = 0.0
	_muzzle_light.omni_range = 5.0
	_muzzle_light.position = Vector3(0.28, 1.25, -1.0)
	add_child(_muzzle_light)
	# Walking dust: small puffs at the feet while moving on ground.
	_dust = GPUParticles3D.new()
	_dust.amount = 12
	_dust.lifetime = 0.5
	_dust.position = Vector3(0.0, 0.1, 0.0)
	var dust_mat := ParticleProcessMaterial.new()
	dust_mat.direction = Vector3(0.0, 1.0, 0.0)
	dust_mat.spread = 40.0
	dust_mat.initial_velocity_min = 0.4
	dust_mat.initial_velocity_max = 1.0
	dust_mat.gravity = Vector3(0.0, -0.5, 0.0)
	dust_mat.scale_min = 0.05
	dust_mat.scale_max = 0.14
	_dust.process_material = dust_mat
	var dust_mesh := SphereMesh.new()
	dust_mesh.radius = 0.06
	dust_mesh.height = 0.12
	_dust.draw_pass_1 = dust_mesh
	var dust_surface := StandardMaterial3D.new()
	dust_surface.albedo_color = Color(0.7, 0.65, 0.58, 0.35)
	dust_surface.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_dust.draw_pass_1.material = dust_surface
	_dust.emitting = false
	add_child(_dust)


## Rebuilds the held weapon mesh at real scale. Lengths (m):
## pistol 0.25, smg 0.6, rifle 0.9, sniper 1.2, shotgun 1.0,
## energy 0.95, launcher 1.1. Body + barrel + grip, PBR metal.
func _update_weapon_mesh() -> void:
	if _weapon_mesh == null:
		return
	for child in _weapon_mesh.get_children():
		child.queue_free()
	var lengths := {"pistol": 0.25, "smg": 0.6, "rifle": 0.9, "sniper": 1.2, "shotgun": 1.0, "energy": 0.95, "launcher": 1.1}
	var length := float(lengths.get(current_weapon, 0.9))
	var metal := GFMaterials.bare_metal(Color(0.2, 0.21, 0.24))
	var grip_mat := GFMaterials.fabric(Color(0.1, 0.1, 0.12))
	var receiver := MeshInstance3D.new()
	var receiver_box := BoxMesh.new()
	receiver_box.size = Vector3(0.07, 0.12, length * 0.55)
	receiver.mesh = receiver_box
	receiver.material_override = metal
	receiver.position = Vector3(0.0, 0.0, -length * 0.2)
	_weapon_mesh.add_child(receiver)
	var barrel := MeshInstance3D.new()
	var barrel_cyl := CylinderMesh.new()
	barrel_cyl.top_radius = 0.025
	barrel_cyl.bottom_radius = 0.025
	barrel_cyl.height = length * 0.45
	barrel.mesh = barrel_cyl
	barrel.material_override = metal
	barrel.rotation.x = deg_to_rad(90.0)
	barrel.position = Vector3(0.0, 0.02, -length * 0.65)
	_weapon_mesh.add_child(barrel)
	var grip := MeshInstance3D.new()
	var grip_box := BoxMesh.new()
	grip_box.size = Vector3(0.06, 0.18, 0.07)
	grip.mesh = grip_box
	grip.material_override = grip_mat
	grip.position = Vector3(0.0, -0.12, length * 0.05)
	_weapon_mesh.add_child(grip)
	if current_weapon == "sniper":
		var scope := MeshInstance3D.new()
		var scope_cyl := CylinderMesh.new()
		scope_cyl.top_radius = 0.04
		scope_cyl.bottom_radius = 0.04
		scope_cyl.height = 0.3
		scope.mesh = scope_cyl
		scope.material_override = GFMaterials.glass()
		scope.rotation.x = deg_to_rad(90.0)
		scope.position = Vector3(0.0, 0.09, -length * 0.25)
		_weapon_mesh.add_child(scope)
	elif current_weapon == "energy":
		var coil := MeshInstance3D.new()
		var coil_box := BoxMesh.new()
		coil_box.size = Vector3(0.09, 0.09, length * 0.4)
		coil.mesh = coil_box
		coil.material_override = GFMaterials.emissive(Color(0.2, 0.9, 0.95), 1.2)
		coil.position = Vector3(0.0, 0.0, -length * 0.4)
		_weapon_mesh.add_child(coil)


func _unhandled_input(event: InputEvent) -> void:
	if dead:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_apply_look(event.relative)
	elif event is InputEventScreenDrag:
		# Right half of the screen drags the camera; the left half is
		# the virtual joystick (handled by the HUD).
		if event.position.x > get_viewport().get_visible_rect().size.x * 0.4:
			_apply_look(event.relative)


func _apply_look(relative: Vector2) -> void:
	# Full 360-degree yaw: yaw is NEVER clamped, the camera can spin
	# around the character endlessly. Only pitch is clamped so the
	# camera can never flip over the character.
	var sens: float = SettingsManager.sensitivity * 0.004
	var invert := -1.0 if SettingsManager.invert_y else 1.0
	yaw -= relative.x * sens
	pitch = clampf(pitch - relative.y * sens * invert, deg_to_rad(-60.0), deg_to_rad(45.0))
	rotation.y = yaw
	_spring_arm.rotation.x = pitch + _recoil_pitch


func _physics_process(delta: float) -> void:
	if dead or driving:
		return
	if switch_timer > 0.0:
		switch_timer -= delta
	if fire_cooldown > 0.0:
		fire_cooldown -= delta
	if reloading:
		reload_timer -= delta
		if reload_timer <= 0.0:
			_finish_reload()
	# Recoil decays; muzzle flash lasts 0.06 s; dust puffs only
	# while actually moving on the ground.
	_recoil_pitch = move_toward(_recoil_pitch, 0.0, delta * 0.35)
	_spring_arm.rotation.x = pitch + _recoil_pitch
	if _muzzle_timer > 0.0:
		_muzzle_timer -= delta
		if _muzzle_timer <= 0.0 and _muzzle_light != null:
			_muzzle_light.light_energy = 0.0
	if _dust != null:
		var moving := Vector2(velocity.x, velocity.z).length() > 2.0
		_dust.emitting = moving and is_on_floor()
	_update_aim(delta)
	_apply_gravity(delta)
	_handle_jump()
	_handle_crouch()
	_handle_move(delta)
	_handle_weapons(delta)
	_scan_timer -= delta
	if _scan_timer <= 0.0:
		_scan_timer = 0.15
		_update_interactable()
	move_and_slide()


## Aim / ADS: hold right mouse (or the AIM button). Zooms the camera
## (FOV x weapon zoom), shortens the camera arm, slows movement and
## tightens spread. Firing while aiming is fully allowed.
func _update_aim(delta: float) -> void:
	var hud := _get_hud()
	var want_aim: bool = Input.is_action_pressed("aim") or (hud != null and hud.aim_held)
	aiming = want_aim and not reloading and switch_timer <= 0.0
	var target_fov := 75.0
	var target_arm := 4.2
	if aiming:
		target_fov = 75.0 * float(WEAPONS[current_weapon]["zoom"])
		target_arm = 2.4
	_camera.fov = lerpf(_camera.fov, target_fov, minf(1.0, delta * 10.0))
	_spring_arm.spring_length = lerpf(_spring_arm.spring_length, target_arm, minf(1.0, delta * 10.0))


func current_spread_rad() -> float:
	var w: Dictionary = WEAPONS[current_weapon]
	var spread := deg_to_rad(float(w["spread_deg"]))
	if aiming:
		spread *= 0.35
	var moving := Vector2(velocity.x, velocity.z).length()
	if moving > 6.0:
		spread *= 1.8
	elif moving > 0.5:
		spread *= 1.3
	return spread


## Crosshair state for the HUD: gap in pixels, scope overlay type.
func crosshair_state() -> Dictionary:
	var gap := 6.0 + current_spread_rad() * 400.0
	if aiming:
		gap *= 0.5
	return {"gap": gap, "aiming": aiming, "scope": String(WEAPONS[current_weapon]["scope"])}


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta


func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor() and not crouched:
		velocity.y = JUMP_VELOCITY


func _handle_crouch() -> void:
	if Input.is_action_just_pressed("crouch"):
		toggle_crouch()


func toggle_crouch() -> void:
	crouched = not crouched
	_capsule.height = 1.2 if crouched else 1.8
	_collision.position.y = 0.6 if crouched else 0.9
	_body_mesh.scale.y = 0.7 if crouched else 1.0


func _handle_move(delta: float) -> void:
	var input_vec := Vector2.ZERO
	input_vec.y = Input.get_axis("move_forward", "move_back")
	input_vec.x = Input.get_axis("move_left", "move_right")
	var hud := _get_hud()
	if hud != null and hud.move_vector.length() > 0.05:
		input_vec = hud.move_vector
	var speed := WALK_SPEED
	if Input.is_action_pressed("sprint") and input_vec.y < -0.1 and not crouched:
		speed = SPRINT_SPEED
	elif input_vec.length() > 0.9:
		speed = RUN_SPEED
	if crouched:
		speed = CROUCH_SPEED
	if aiming:
		speed *= 0.6
	var dir := (transform.basis * Vector3(input_vec.x, 0.0, input_vec.y))
	if dir.length() > 1.0:
		dir = dir.normalized()
	elif input_vec.length() > 0.0 and input_vec.length() <= 1.0:
		dir = dir.normalized() * input_vec.length()
	var target := dir * speed
	velocity.x = move_toward(velocity.x, target.x, ACCEL * delta)
	velocity.z = move_toward(velocity.z, target.z, ACCEL * delta)


func _handle_weapons(_delta: float) -> void:
	if reloading or switch_timer > 0.0:
		return
	if Input.is_action_just_pressed("switch_weapon"):
		_switch_weapon()
		return
	if Input.is_action_just_pressed("reload"):
		_start_reload()
		return
	var hud := _get_hud()
	var want_fire: bool = Input.is_action_pressed("fire") or (hud != null and hud.fire_held)
	if want_fire and fire_cooldown <= 0.0:
		_fire()


func _switch_weapon() -> void:
	if loadout.size() < 2:
		return
	loadout_index = (loadout_index + 1) % loadout.size()
	current_weapon = loadout[loadout_index]
	switch_timer = 0.4
	weapon_changed.emit(WEAPONS[current_weapon]["name"])
	_update_weapon_mesh()
	_emit_ammo()


func equip_slot(index: int) -> void:
	if index < 0 or index >= loadout.size() or index == loadout_index:
		return
	loadout_index = index
	current_weapon = loadout[loadout_index]
	switch_timer = 0.4
	weapon_changed.emit(WEAPONS[current_weapon]["name"])
	_update_weapon_mesh()
	_emit_ammo()


## Picks up a weapon into the loadout. If both slots are full the
## new weapon replaces the secondary slot. Full mag + reserve.
func give_weapon(weapon_key: String) -> bool:
	if not WEAPONS.has(weapon_key):
		return false
	if loadout.has(weapon_key):
		ammo[weapon_key] = {"mag": WEAPONS[weapon_key]["mag_size"], "reserve": WEAPONS[weapon_key]["reserve_max"]}
		_emit_ammo()
		return true
	if loadout.size() < 2:
		loadout.append(weapon_key)
	else:
		loadout[1] = weapon_key
	ammo[weapon_key] = {"mag": WEAPONS[weapon_key]["mag_size"], "reserve": WEAPONS[weapon_key]["reserve_max"]}
	loadout_index = loadout.find(weapon_key)
	current_weapon = weapon_key
	weapon_changed.emit(WEAPONS[current_weapon]["name"])
	_update_weapon_mesh()
	_emit_ammo()
	return true


func _start_reload() -> void:
	var state: Dictionary = ammo[current_weapon]
	if state["mag"] >= WEAPONS[current_weapon]["mag_size"]:
		return
	if state["reserve"] <= 0:
		return
	reloading = true
	reload_timer = WEAPONS[current_weapon]["reload_time"]


func _finish_reload() -> void:
	reloading = false
	var w: Dictionary = WEAPONS[current_weapon]
	var state: Dictionary = ammo[current_weapon]
	var need: int = w["mag_size"] - state["mag"]
	var taken: int = mini(need, state["reserve"])
	state["mag"] += taken
	state["reserve"] -= taken
	_emit_ammo()


func _fire() -> void:
	var w: Dictionary = WEAPONS[current_weapon]
	var state: Dictionary = ammo[current_weapon]
	if state["mag"] <= 0:
		_start_reload()
		return
	state["mag"] -= 1
	fire_cooldown = w["fire_interval"]
	_emit_ammo()
	# Muzzle flash + slight camera recoil kick.
	if _muzzle_light != null:
		_muzzle_light.light_energy = 4.0
		_muzzle_timer = 0.06
	var kick := 0.008 if current_weapon != "sniper" and current_weapon != "launcher" else 0.02
	_recoil_pitch = minf(_recoil_pitch + kick, 0.06)
	var spread := current_spread_rad()
	var pellets: int = w["pellets"]
	for i in pellets:
		var dir: Vector3 = -_camera.global_transform.basis.z
		if spread > 0.0:
			dir = dir.rotated(_camera.global_transform.basis.x, randf_range(-spread, spread))
			dir = dir.rotated(_camera.global_transform.basis.y, randf_range(-spread, spread))
		var from: Vector3 = _camera.global_position
		var to: Vector3 = from + dir.normalized() * float(w["range"])
		var query := PhysicsRayQueryParameters3D.create(from, to, 0xFFFFFFFF, [self])
		var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty():
			continue
		var hit_pos: Vector3 = hit.get("position", to)
		_spawn_hit_marker(hit_pos)
		var splash: float = w["splash"]
		if splash > 0.0:
			_apply_splash(hit_pos, splash, float(w["damage"]))
		else:
			var collider: Object = hit.get("collider")
			if collider != null and collider.has_method("take_damage"):
				collider.take_damage(float(w["damage"]), true)


func _apply_splash(center: Vector3, radius: float, damage: float) -> void:
	_spawn_smoke(center)
	for node in get_tree().get_nodes_in_group("enemies"):
		if node is GFEnemy and (node as GFEnemy).state != GFEnemy.State.DEAD:
			if (node as Node3D).global_position.distance_to(center) <= radius:
				(node as GFEnemy).take_damage(damage, true)


## One-shot smoke burst at an explosion (launcher impact).
func _spawn_smoke(pos: Vector3) -> void:
	var smoke := GPUParticles3D.new()
	smoke.amount = 24
	smoke.lifetime = 1.2
	smoke.one_shot = true
	smoke.explosiveness = 0.9
	smoke.position = pos
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0.0, 1.0, 0.0)
	mat.spread = 60.0
	mat.initial_velocity_min = 1.0
	mat.initial_velocity_max = 3.0
	mat.gravity = Vector3(0.0, 0.5, 0.0)
	mat.scale_min = 0.2
	mat.scale_max = 0.5
	smoke.process_material = mat
	var mesh := SphereMesh.new()
	mesh.radius = 0.15
	mesh.height = 0.3
	smoke.draw_pass_1 = mesh
	var surf := StandardMaterial3D.new()
	surf.albedo_color = Color(0.25, 0.25, 0.25, 0.5)
	surf.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke.draw_pass_1.material = surf
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		scene_root = get_tree().root
	scene_root.add_child(smoke)
	smoke.emitting = true
	var timer := get_tree().create_timer(2.0)
	timer.timeout.connect(smoke.queue_free)


func _spawn_hit_marker(pos: Vector3) -> void:
	var marker := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.08
	sphere.height = 0.16
	marker.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.9, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.8, 0.1)
	mat.emission_energy_multiplier = 3.0
	marker.material_override = mat
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		scene_root = get_tree().root
	scene_root.add_child(marker)
	marker.global_position = pos
	var tween := marker.create_tween()
	tween.tween_interval(0.12)
	tween.tween_callback(marker.queue_free)


func _update_interactable() -> void:
	var best: Node3D = null
	var best_dist := INTERACT_RANGE
	for node in get_tree().get_nodes_in_group("interactables"):
		if not (node is Node3D):
			continue
		if node.has_method("is_usable") and not node.is_usable():
			continue
		var d: float = global_position.distance_to((node as Node3D).global_position)
		if d < best_dist:
			best_dist = d
			best = node
	if best != _nearest_interactable:
		_nearest_interactable = best
		if best != null and best.has_method("get_prompt"):
			interact_prompt_changed.emit(best.get_prompt())
		else:
			interact_prompt_changed.emit("")


func try_interact() -> void:
	if _nearest_interactable != null and _nearest_interactable.has_method("interact"):
		_nearest_interactable.interact(self)


func take_damage(amount: float) -> void:
	if dead:
		return
	var remaining := amount
	if shield > 0.0:
		var absorbed: float = minf(shield, remaining)
		shield -= absorbed
		remaining -= absorbed
	if remaining > 0.0:
		health -= remaining
	health_changed.emit(health, shield)
	if health <= 0.0:
		health = 0.0
		dead = true
		died.emit()


func heal(amount: float) -> void:
	if dead:
		return
	health = minf(MAX_HEALTH, health + amount)
	health_changed.emit(health, shield)


func restore_shield(amount: float) -> void:
	if dead:
		return
	shield = minf(MAX_SHIELD, shield + amount)
	health_changed.emit(health, shield)


func add_ammo(weapon_key: String, amount: int) -> int:
	if not ammo.has(weapon_key):
		return 0
	var state: Dictionary = ammo[weapon_key]
	var space: int = int(WEAPONS[weapon_key]["reserve_max"]) - state["reserve"]
	var added: int = mini(space, amount)
	state["reserve"] += added
	_emit_ammo()
	return added


## Adds items to the inventory. Returns how many actually fit —
## the rest stays where it came from (loot box / ground).
func add_item(item_id: String, amount: int) -> int:
	if not inventory.has(item_id):
		return 0
	var cap: int = ITEM_CAPS.get(item_id, 99)
	var space: int = cap - int(inventory[item_id])
	var added: int = mini(space, amount)
	if added > 0:
		inventory[item_id] = int(inventory[item_id]) + added
		inventory_changed.emit(inventory)
	return added


func use_item(item_id: String) -> bool:
	if int(inventory.get(item_id, 0)) <= 0:
		return false
	match item_id:
		"medkit":
			if health >= MAX_HEALTH:
				return false
			heal(50.0)
		"shield_cell":
			if shield >= MAX_SHIELD:
				return false
			restore_shield(50.0)
		_:
			return false
	inventory[item_id] = int(inventory[item_id]) - 1
	inventory_changed.emit(inventory)
	return true


func set_driving(value: bool, vehicle: Node3D) -> void:
	driving = value
	_vehicle = vehicle if value else null
	set_physics_process(!value)
	visible = !value
	collision_layer = 0 if value else 4
	if value:
		velocity = Vector3.ZERO


func _emit_ammo() -> void:
	var state: Dictionary = ammo[current_weapon]
	ammo_changed.emit(WEAPONS[current_weapon]["name"], state["mag"], state["reserve"])


func _get_hud() -> Node:
	return get_tree().get_first_node_in_group("hud")
