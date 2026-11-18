## Galaxy Frontier — World (ZERON, Godot rebuild).
## Builds the whole level from primitives in code, at REAL-WORLD
## SCALE (1 unit = 1 m): a 1.8 m character, 1.2 x 2.1 m doors,
## 3.0 m floors, 7 m streets, a 4.5 m rover. Three villages
## (Landing / Outpost / Extraction) with 12 houses + a two-storey
## station, streets connecting them, mountain terrain, PBR
## materials (procedural concrete/asphalt/dirt/metal/glass),
## interior lighting, and manual LOD for detail props. No imported
## assets. All failure paths are guarded: a missing scene file logs
## an error and the world stays up instead of crashing.
## Honest limit: upper floors are exterior shells — no stairs yet,
## so only ground floors are enterable (see Docs/REALISM.md).
extends Node3D

const PLAYER_SCENE := "res://scenes/player.tscn"
const ENEMY_SCENE := "res://scenes/enemy.tscn"
const HUD_SCENE := "res://scenes/hud.tscn"

const PLAYER_SPAWN := Vector3(-70.0, 0.5, -50.0)
const SPAWN_YAW := -2.19
const FLOOR_HEIGHT := 3.2
const STREET_WIDTH := 7.0

## Village centers: Landing (-70,-50), Outpost (0,0), Extraction (70,60).
const VILLAGES := [
	{"name": "Landing", "center": Vector2(-70.0, -50.0)},
	{"name": "Outpost", "center": Vector2(0.0, 0.0)},
	{"name": "Extraction", "center": Vector2(70.0, 60.0)},
]

var player: GFPlayer = null
var mission: GFMissionManager = null
var hud: GFHUD = null
var perf: GFPerformanceManager = null
var vehicle: GFVehicle = null
## Points of interest for the minimap: {pos: Vector3, kind: String}.
var pois: Array = []

var _zones: Array = []
var _zone_check_timer: float = 0.0
var _lod_timer: float = 0.0
var _detail_nodes: Array[Node3D] = []
var _street_segments: Array = []
var _core_mesh: MeshInstance3D = null
var _terminal_screen_mat: StandardMaterial3D = null
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 12345
	_build_environment()
	_build_ground()
	_build_streets()
	_build_station()
	_build_villages()
	_build_props()
	_spawn_interactables()
	_spawn_zones()
	mission = GFMissionManager.new()
	add_child(mission)
	mission.set_targets({
		"landing": Vector3(-70.0, 0.0, -50.0),
		"outpost": Vector3(0.0, 0.0, 0.0),
		"building": Vector3(0.0, 0.0, 0.0),
		"power_core": Vector3(-6.0, 0.0, -4.0),
		"terminal": Vector3(8.0, 0.0, -6.0),
		"defeat": Vector3(0.0, 0.0, 0.0),
		"extraction": Vector3(70.0, 0.0, 60.0),
	})
	perf = GFPerformanceManager.new()
	add_child(perf)
	_spawn_player()
	_spawn_enemies()
	_spawn_vehicle()
	_spawn_hud()
	if mission != null:
		mission.start_from_save(SaveManager.load_game())
		if hud != null and mission != null:
			hud.bind_world(self, player, mission)


func _mat(color: Color, emission: Color = Color(0, 0, 0), energy: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.85
	if energy > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = energy
	return m


func _box(size: Vector3, pos: Vector3, mat: Material, parent: Node = null) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = mat
	mesh.position = pos
	(parent if parent != null else self).add_child(mesh)
	return mesh


func _build_environment() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.12, 0.08, 0.35)
	sky_mat.sky_horizon_color = Color(0.85, 0.45, 0.25)
	sky_mat.ground_bottom_color = Color(0.05, 0.03, 0.08)
	sky_mat.ground_horizon_color = Color(0.35, 0.2, 0.3)
	sky_mat.sun_angle_max = 30.0
	sky.sky_material = sky_mat
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.6
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.55, 0.35, 0.45)
	environment.fog_density = 0.008
	env.environment = environment
	add_child(env)
	# Directional sun with soft shadows (PCF blur) + ambient sky.
	var sun := DirectionalLight3D.new()
	sun.add_to_group("sun_lights")
	sun.rotation_degrees = Vector3(-50.0, -30.0, 0.0)
	sun.shadow_enabled = SettingsManager.quality > 0
	sun.shadow_blur = 1.5
	sun.directional_shadow_max_distance = 140.0
	sun.light_energy = 1.1
	add_child(sun)


func _build_ground() -> void:
	_box(Vector3(240.0, 1.0, 240.0), Vector3(0.0, -0.5, 0.0), GFMaterials.dirt())
	var ground_body := StaticBody3D.new()
	ground_body.collision_layer = 1
	ground_body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(240.0, 1.0, 240.0)
	shape.shape = box_shape
	shape.position = Vector3(0.0, -0.5, 0.0)
	ground_body.add_child(shape)
	add_child(ground_body)
	# Mountain ring + a big northern ridge (real scale: 12–22 m high).
	var hill_mat := GFMaterials.dirt(Color(0.3, 0.24, 0.3))
	for i in 10:
		var angle := TAU * float(i) / 10.0
		var hill := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 1.0
		sphere.height = 2.0
		hill.mesh = sphere
		hill.material_override = hill_mat
		hill.position = Vector3(cos(angle) * 128.0, -2.0, sin(angle) * 128.0)
		hill.scale = Vector3(34.0, 12.0, 34.0)
		add_child(hill)
	for pos in [Vector3(-60.0, -4.0, -105.0), Vector3(0.0, -5.0, -110.0), Vector3(60.0, -4.0, -105.0)]:
		var mountain := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 1.0
		sphere.height = 2.0
		mountain.mesh = sphere
		mountain.material_override = GFMaterials.dirt(Color(0.38, 0.36, 0.42))
		mountain.position = pos
		mountain.scale = Vector3(45.0, 22.0, 40.0)
		add_child(mountain)


func _build_street(from: Vector2, to: Vector2) -> void:
	var a := Vector3(from.x, 0.0, from.y)
	var b := Vector3(to.x, 0.0, to.y)
	var dir: Vector3 = b - a
	var length := dir.length()
	var strip := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(STREET_WIDTH, 0.06, length)
	strip.mesh = box
	strip.material_override = GFMaterials.asphalt()
	strip.position = (a + b) / 2.0 + Vector3(0.0, 0.03, 0.0)
	strip.rotation.y = atan2(dir.x, dir.z)
	add_child(strip)
	_street_segments.append({"a": from, "b": to})


func _build_streets() -> void:
	_build_street(Vector2(-70.0, -50.0), Vector2(0.0, 0.0))
	_build_street(Vector2(0.0, 0.0), Vector2(70.0, 60.0))
	_build_street(Vector2(0.0, -18.0), Vector2(0.0, 18.0))


func _near_street(p: Vector2, margin: float = 5.0) -> bool:
	for seg in _street_segments:
		var a: Vector2 = seg["a"]
		var b: Vector2 = seg["b"]
		var ab := b - a
		var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		if (p - (a + ab * t)).length() < STREET_WIDTH / 2.0 + margin:
			return true
	return false


func _near_village(p: Vector2, margin: float = 16.0) -> bool:
	for v in VILLAGES:
		if (p - v["center"]).length() < margin:
			return true
	return false


## One house. w/d in meters, floors x 3.0 m each. Door gap 1.4 m
## on the front (+z local) with an auto GFDoor (1.2 x 2.1 m).
## Windows: reflective glass 1.4 x 1.2 m. Roof slab + vent (LOD).
func _build_house(center: Vector3, w: float, d: float, floors: int, rot_y: float, wall_color: Color) -> void:
	var root := Node3D.new()
	root.position = center
	root.rotation.y = rot_y
	add_child(root)
	var wall_mat := GFMaterials.concrete(wall_color)
	var roof_mat := GFMaterials.painted_metal(Color(0.35, 0.36, 0.4))
	var height := FLOOR_HEIGHT * float(floors)
	# Thin floor slab (0.12 m — the player walks at y=0).
	_box(Vector3(w, 0.12, d), Vector3(0.0, 0.06, 0.0), GFMaterials.concrete(Color(0.3, 0.32, 0.38)), root)
	# Back + side walls (full height).
	_box(Vector3(w, height, 0.3), Vector3(0.0, height / 2.0, -d / 2.0), wall_mat, root)
	_box(Vector3(0.3, height, d), Vector3(-w / 2.0, height / 2.0, 0.0), wall_mat, root)
	_box(Vector3(0.3, height, d), Vector3(w / 2.0, height / 2.0, 0.0), wall_mat, root)
	# Front wall: two segments + lintel above the 1.4 m door gap.
	var seg_w := (w - 1.4) / 2.0
	_box(Vector3(seg_w, height, 0.3), Vector3(-(0.7 + seg_w / 2.0), height / 2.0, d / 2.0), wall_mat, root)
	_box(Vector3(seg_w, height, 0.3), Vector3(0.7 + seg_w / 2.0, height / 2.0, d / 2.0), wall_mat, root)
	_box(Vector3(1.4, height - 2.1, 0.3), Vector3(0.0, 2.1 + (height - 2.1) / 2.0, d / 2.0), wall_mat, root)
	# Floor slab between floors + roof slab with overhang.
	if floors > 1:
		_box(Vector3(w + 0.4, 0.25, d + 0.4), Vector3(0.0, FLOOR_HEIGHT, 0.0), wall_mat, root)
	_box(Vector3(w + 0.6, 0.25, d + 0.6), Vector3(0.0, height + 0.12, 0.0), roof_mat, root)
	# Windows (glass) per floor on front + sides.
	var glass := GFMaterials.glass()
	for f in floors:
		var wy := FLOOR_HEIGHT * float(f) + 1.6
		for wx in [-w / 4.0, w / 4.0]:
			_box(Vector3(1.4, 1.2, 0.08), Vector3(wx, wy, d / 2.0 + 0.12), glass, root)
		_box(Vector3(0.08, 1.2, 1.4), Vector3(-w / 2.0 - 0.12, wy, 0.0), glass, root)
	# Auto door at the front gap.
	var door := GFDoor.new()
	door.position = Vector3(0.0, 0.0, d / 2.0)
	root.add_child(door)
	# Roof vent (LOD detail: hidden beyond 60 m).
	var vent := _box(Vector3(0.5, 0.5, 0.5), Vector3(w / 4.0, height + 0.5, 0.0), GFMaterials.bare_metal(), root)
	_detail_nodes.append(vent)
	# Collision: walls only (floor is the ground plane).
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var wall_boxes: Array = [
		[Vector3(w, height, 0.3), Vector3(0.0, height / 2.0, -d / 2.0)],
		[Vector3(0.3, height, d), Vector3(-w / 2.0, height / 2.0, 0.0)],
		[Vector3(0.3, height, d), Vector3(w / 2.0, height / 2.0, 0.0)],
		[Vector3(seg_w, height, 0.3), Vector3(-(0.7 + seg_w / 2.0), height / 2.0, d / 2.0)],
		[Vector3(seg_w, height, 0.3), Vector3(0.7 + seg_w / 2.0, height / 2.0, d / 2.0)],
		[Vector3(1.4, height - 2.1, 0.3), Vector3(0.0, 2.1 + (height - 2.1) / 2.0, d / 2.0)],
	]
	for wb in wall_boxes:
		var col := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = wb[0]
		col.shape = bs
		col.position = wb[1]
		body.add_child(col)
	root.add_child(body)
	pois.append({"pos": center, "kind": "house"})


func _build_villages() -> void:
	# Landing village: 4 houses around the landing pad.
	_build_house(Vector3(-78.0, 0.0, -58.0), 7.0, 6.0, 1, 0.3, Color(0.55, 0.5, 0.42))
	_build_house(Vector3(-62.0, 0.0, -56.0), 8.0, 6.0, 2, -0.2, Color(0.5, 0.52, 0.58))
	_build_house(Vector3(-76.0, 0.0, -40.0), 6.0, 6.0, 1, 1.2, Color(0.58, 0.45, 0.38))
	_build_house(Vector3(-60.0, 0.0, -42.0), 7.0, 6.0, 1, 2.6, Color(0.45, 0.5, 0.45))
	# Outpost village: 4 houses around the station.
	_build_house(Vector3(-14.0, 0.0, -14.0), 8.0, 6.0, 2, 0.5, Color(0.52, 0.5, 0.46))
	_build_house(Vector3(16.0, 0.0, -12.0), 7.0, 6.0, 1, -0.8, Color(0.48, 0.5, 0.55))
	_build_house(Vector3(-16.0, 0.0, 12.0), 6.0, 6.0, 1, 1.8, Color(0.55, 0.48, 0.42))
	_build_house(Vector3(14.0, 0.0, 14.0), 8.0, 7.0, 2, 2.4, Color(0.5, 0.48, 0.52))
	# Extraction village: 4 houses.
	_build_house(Vector3(62.0, 0.0, 52.0), 7.0, 6.0, 1, 0.4, Color(0.54, 0.5, 0.44))
	_build_house(Vector3(78.0, 0.0, 54.0), 8.0, 6.0, 2, -0.4, Color(0.46, 0.5, 0.54))
	_build_house(Vector3(64.0, 0.0, 70.0), 6.0, 6.0, 1, 1.5, Color(0.56, 0.47, 0.4))
	_build_house(Vector3(80.0, 0.0, 70.0), 7.0, 6.0, 1, 2.8, Color(0.48, 0.52, 0.46))


func _build_station() -> void:
	# Outpost station: 24 x 16 m, two floors x 3.2 m = 6.4 m + roof.
	var wall_mat := GFMaterials.concrete(Color(0.45, 0.48, 0.55))
	var accent_mat := GFMaterials.emissive(Color(0.15, 0.7, 0.65), 0.8)
	var height := FLOOR_HEIGHT * 2.0
	_box(Vector3(24.0, 0.12, 16.0), Vector3(0.0, 0.06, 0.0), GFMaterials.concrete(Color(0.3, 0.32, 0.38)))
	# North wall + side walls (full height).
	_box(Vector3(24.0, height, 0.3), Vector3(0.0, height / 2.0, -8.0), wall_mat)
	_box(Vector3(0.3, height, 16.0), Vector3(-12.0, height / 2.0, 0.0), wall_mat)
	_box(Vector3(0.3, height, 16.0), Vector3(12.0, height / 2.0, 0.0), wall_mat)
	# South wall: door gap 1.4 m at x=0, lintel above, upper wall.
	var seg_w := (24.0 - 1.4) / 2.0
	_box(Vector3(seg_w, height, 0.3), Vector3(-(0.7 + seg_w / 2.0), height / 2.0, 8.0), wall_mat)
	_box(Vector3(seg_w, height, 0.3), Vector3(0.7 + seg_w / 2.0, height / 2.0, 8.0), wall_mat)
	_box(Vector3(1.4, 1.1, 0.3), Vector3(0.0, 2.65, 8.0), wall_mat)
	_box(Vector3(1.4, FLOOR_HEIGHT, 0.3), Vector3(0.0, FLOOR_HEIGHT + FLOOR_HEIGHT / 2.0, 8.0), wall_mat)
	# Mid-floor slab + roof slab + accent strip.
	_box(Vector3(24.0, 0.25, 16.0), Vector3(0.0, FLOOR_HEIGHT, 0.0), wall_mat)
	_box(Vector3(25.0, 0.3, 17.0), Vector3(0.0, height + 0.15, 0.0), GFMaterials.painted_metal(Color(0.35, 0.36, 0.4)))
	_box(Vector3(24.2, 0.15, 0.2), Vector3(0.0, 3.35, 8.15), accent_mat)
	# Windows: reflective glass, both floors, front + sides.
	var glass := GFMaterials.glass()
	for f in 2:
		var wy := FLOOR_HEIGHT * float(f) + 1.6
		for wx in [-9.0, -5.0, 5.0, 9.0]:
			_box(Vector3(1.4, 1.2, 0.08), Vector3(wx, wy, 8.12), glass)
		for wz in [-4.0, 4.0]:
			_box(Vector3(0.08, 1.2, 1.4), Vector3(-12.12, wy, wz), glass)
			_box(Vector3(0.08, 1.2, 1.4), Vector3(12.12, wy, wz), glass)
	# Station auto door (south wall).
	var door := GFDoor.new()
	door.position = Vector3(0.0, 0.0, 8.0)
	add_child(door)
	# Roof pipes + antenna (LOD details).
	for px in [-8.0, -6.0]:
		var pipe := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.18
		cyl.bottom_radius = 0.18
		cyl.height = 1.6
		pipe.mesh = cyl
		pipe.material_override = GFMaterials.bare_metal()
		pipe.position = Vector3(px, height + 0.9, -4.0)
		add_child(pipe)
		_detail_nodes.append(pipe)
	var antenna := MeshInstance3D.new()
	var ant_cyl := CylinderMesh.new()
	ant_cyl.top_radius = 0.04
	ant_cyl.bottom_radius = 0.06
	ant_cyl.height = 3.0
	antenna.mesh = ant_cyl
	antenna.material_override = GFMaterials.bare_metal(Color(0.6, 0.62, 0.65))
	antenna.position = Vector3(9.0, height + 1.5, -5.0)
	add_child(antenna)
	_detail_nodes.append(antenna)
	var tip := MeshInstance3D.new()
	var tip_sphere := SphereMesh.new()
	tip_sphere.radius = 0.12
	tip_sphere.height = 0.24
	tip.mesh = tip_sphere
	tip.material_override = GFMaterials.emissive(Color(1.0, 0.2, 0.2), 2.0)
	tip.position = Vector3(9.0, height + 3.0, -5.0)
	add_child(tip)
	# Collision: walls only.
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var wall_boxes: Array = [
		[Vector3(24.0, height, 0.3), Vector3(0.0, height / 2.0, -8.0)],
		[Vector3(0.3, height, 16.0), Vector3(-12.0, height / 2.0, 0.0)],
		[Vector3(0.3, height, 16.0), Vector3(12.0, height / 2.0, 0.0)],
		[Vector3(seg_w, height, 0.3), Vector3(-(0.7 + seg_w / 2.0), height / 2.0, 8.0)],
		[Vector3(seg_w, height, 0.3), Vector3(0.7 + seg_w / 2.0, height / 2.0, 8.0)],
		[Vector3(1.4, 1.1, 0.3), Vector3(0.0, 2.65, 8.0)],
		[Vector3(1.4, FLOOR_HEIGHT, 0.3), Vector3(0.0, FLOOR_HEIGHT + FLOOR_HEIGHT / 2.0, 8.0)],
	]
	for wb in wall_boxes:
		var col := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = wb[0]
		col.shape = bs
		col.position = wb[1]
		body.add_child(col)
	add_child(body)
	# Terminal (inside the station).
	_box(Vector3(2.0, 1.2, 0.8), Vector3(8.0, 0.6, -6.0), GFMaterials.bare_metal(Color(0.2, 0.22, 0.28)))
	_terminal_screen_mat = GFMaterials.emissive(Color(0.1, 0.5, 0.9), 1.2)
	_box(Vector3(1.6, 1.0, 0.1), Vector3(8.0, 1.9, -5.6), _terminal_screen_mat)
	# Power Core pedestal + core.
	var ped := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.7
	cyl.bottom_radius = 0.9
	cyl.height = 1.0
	ped.mesh = cyl
	ped.material_override = GFMaterials.bare_metal(Color(0.35, 0.36, 0.42))
	ped.position = Vector3(-6.0, 0.5, -4.0)
	add_child(ped)
	_core_mesh = MeshInstance3D.new()
	var core_sphere := SphereMesh.new()
	core_sphere.radius = 0.45
	core_sphere.height = 0.9
	_core_mesh.mesh = core_sphere
	_core_mesh.material_override = GFMaterials.emissive(Color(0.2, 0.9, 0.95), 2.5)
	_core_mesh.position = Vector3(-6.0, 1.5, -4.0)
	add_child(_core_mesh)
	var core_light := OmniLight3D.new()
	core_light.position = Vector3(-6.0, 2.5, -4.0)
	core_light.light_color = Color(0.3, 0.9, 0.95)
	core_light.light_energy = 1.5
	core_light.omni_range = 8.0
	add_child(core_light)
	# Interior lights (station ground + upper floor).
	var light1 := OmniLight3D.new()
	light1.position = Vector3(0.0, 2.8, 0.0)
	light1.light_color = Color(1.0, 0.95, 0.8)
	light1.light_energy = 0.8
	light1.omni_range = 12.0
	add_child(light1)
	var light2 := OmniLight3D.new()
	light2.position = Vector3(0.0, 6.0, 0.0)
	light2.light_color = Color(1.0, 0.95, 0.8)
	light2.light_energy = 0.6
	light2.omni_range = 10.0
	add_child(light2)


func _build_props() -> void:
	var rock_mat := GFMaterials.dirt(Color(0.4, 0.34, 0.4))
	var crystal_mat := GFMaterials.emissive(Color(0.2, 0.8, 0.9), 1.0)
	var crate_mat := GFMaterials.wood()
	for i in 40:
		var x := _rng.randf_range(-110.0, 110.0)
		var z := _rng.randf_range(-110.0, 110.0)
		if _near_village(Vector2(x, z), 14.0) or _near_street(Vector2(x, z), 4.0):
			continue
		var rock := _box(Vector3(1, 1, 1), Vector3.ZERO, rock_mat)
		var s := _rng.randf_range(0.6, 2.4)
		rock.scale = Vector3(s, s * 0.7, s)
		rock.position = Vector3(x, s * 0.35, z)
		rock.rotation.y = _rng.randf_range(0.0, TAU)
	for i in 12:
		var crystal := MeshInstance3D.new()
		var prism := PrismMesh.new()
		prism.size = Vector3(0.7, 2.2, 0.7)
		crystal.mesh = prism
		crystal.material_override = crystal_mat
		var cx := _rng.randf_range(-100.0, 100.0)
		var cz := _rng.randf_range(-100.0, 100.0)
		if _near_village(Vector2(cx, cz), 14.0) or _near_street(Vector2(cx, cz), 4.0):
			continue
		crystal.position = Vector3(cx, 1.1, cz)
		crystal.rotation.z = _rng.randf_range(-0.25, 0.25)
		add_child(crystal)
	for pos in [Vector3(-8.0, 0.5, 4.0), Vector3(8.0, 0.5, -8.0), Vector3(66.0, 0.5, 56.0)]:
		_box(Vector3(1.2, 1.0, 1.2), pos, crate_mat)


func _add_interactable(id: String, prompt: String, action: String, pos: Vector3) -> GFInteractable:
	var inter := GFInteractable.new()
	inter.interact_id = id
	inter.prompt = prompt
	inter.action = action
	inter.position = pos
	add_child(inter)
	inter.interacted.connect(_on_interacted)
	return inter


func _add_pickup(pickup_type: String, pos: Vector3) -> void:
	var pickup := GFPickup.new()
	pickup.item_id = pickup_type
	pickup.position = pos
	add_child(pickup)
	pickup.interacted.connect(_on_interacted)
	pois.append({"pos": pos, "kind": "pickup"})


func _add_weapon_pickup(weapon_key: String, pos: Vector3) -> void:
	var pickup := GFWeaponPickup.new()
	pickup.weapon_key = weapon_key
	pickup.position = pos
	add_child(pickup)
	pickup.interacted.connect(_on_interacted)
	pois.append({"pos": pos, "kind": "weapon"})


func _spawn_interactables() -> void:
	_add_interactable("power_core", "Take the Power Core", "core", Vector3(-6.0, 1.5, -4.0))
	_add_interactable("terminal", "Activate the Power Core", "terminal", Vector3(8.0, 1.5, -5.5))
	_add_interactable("crate_1", "Open Crate (+ammo, +medkit)", "crate", Vector3(-8.0, 1.0, 4.0))
	_add_interactable("crate_2", "Open Crate (+ammo, +shield cell)", "crate", Vector3(8.0, 1.0, -8.0))
	_add_interactable("crate_3", "Open Crate (+ammo, +medkit)", "crate", Vector3(66.0, 1.0, 56.0))
	# Pickups: on the ground and on crate tops / inside buildings.
	_add_pickup("medkit", Vector3(-68.0, 0.6, -48.0))
	_add_pickup("medkit", Vector3(-8.0, 1.2, 4.0))
	_add_pickup("medkit", Vector3(4.0, 0.6, -6.0))
	_add_pickup("shield_cell", Vector3(2.0, 0.6, 8.0))
	_add_pickup("shield_cell", Vector3(8.0, 1.2, -8.0))
	_add_pickup("shield_cell", Vector3(-14.0, 0.6, -12.0))
	_add_pickup("ammo_rifle", Vector3(66.0, 1.2, 56.0))
	_add_pickup("ammo_pistol", Vector3(60.0, 0.6, 66.0))
	_add_pickup("core_fragment", Vector3(10.0, 0.6, 10.0))
	# Weapon pickups lying in the world.
	_add_weapon_pickup("smg", Vector3(12.0, 0.6, 6.0))
	_add_weapon_pickup("sniper", Vector3(6.0, 0.6, 6.0))
	_add_weapon_pickup("energy", Vector3(72.0, 0.6, 58.0))


func _add_zone(zone_id: String, pos: Vector3, size: Vector3) -> void:
	var zone := GFZoneArea.new()
	zone.zone_id = zone_id
	zone.position = pos
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	zone.add_child(shape)
	add_child(zone)
	zone.zone_entered.connect(_on_zone_entered)
	_zones.append({"id": zone_id, "center": pos, "half": size / 2.0})
	var ring := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = minf(size.x, size.z) * 0.45
	cyl.bottom_radius = minf(size.x, size.z) * 0.45
	cyl.height = 0.08
	ring.mesh = cyl
	ring.material_override = _mat(Color(0.2, 0.9, 0.7), Color(0.2, 0.9, 0.7), 0.7)
	ring.position = Vector3(pos.x, 0.06, pos.z)
	add_child(ring)


func _spawn_zones() -> void:
	_add_zone("landing", Vector3(-70.0, 1.5, -50.0), Vector3(12.0, 4.0, 12.0))
	_add_zone("outpost", Vector3(0.0, 2.0, 0.0), Vector3(30.0, 6.0, 24.0))
	_add_zone("building", Vector3(0.0, 2.0, 0.0), Vector3(22.0, 5.0, 14.0))
	_add_zone("extraction", Vector3(70.0, 1.5, 60.0), Vector3(12.0, 4.0, 12.0))


func _spawn_player() -> void:
	var scene: PackedScene = load(PLAYER_SCENE)
	if scene == null:
		push_error("World: player scene failed to load: " + PLAYER_SCENE)
		return
	player = scene.instantiate() as GFPlayer
	if player == null:
		push_error("World: player scene is not a GFPlayer")
		return
	player.position = PLAYER_SPAWN
	player.yaw = SPAWN_YAW
	player.rotation.y = SPAWN_YAW
	add_child(player)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if not DisplayServer.is_touchscreen_available() else Input.MOUSE_MODE_VISIBLE


func _spawn_enemies() -> void:
	var scene: PackedScene = load(ENEMY_SCENE)
	if scene == null:
		push_error("World: enemy scene failed to load: " + ENEMY_SCENE)
		return
	# Mixed types: grunt x2, runner, armored, sniper, boss (Guardian).
	var spawns: Array = [
		{"type": "grunt", "pos": Vector3(-10.0, 0.5, -6.0), "patrol": [Vector3(-10.0, 0.5, -6.0), Vector3(2.0, 0.5, -12.0), Vector3(4.0, 0.5, 2.0)]},
		{"type": "runner", "pos": Vector3(8.0, 0.5, 6.0), "patrol": [Vector3(8.0, 0.5, 6.0), Vector3(14.0, 0.5, 10.0), Vector3(2.0, 0.5, 12.0)]},
		{"type": "armored", "pos": Vector3(-4.0, 0.5, -14.0), "patrol": [Vector3(-4.0, 0.5, -14.0), Vector3(-12.0, 0.5, -16.0), Vector3(-8.0, 0.5, -6.0)]},
		{"type": "sniper", "pos": Vector3(30.0, 0.5, 20.0), "patrol": [Vector3(30.0, 0.5, 20.0), Vector3(38.0, 0.5, 26.0), Vector3(26.0, 0.5, 28.0)]},
		{"type": "boss", "pos": Vector3(70.0, 0.5, 60.0), "patrol": [Vector3(70.0, 0.5, 60.0), Vector3(76.0, 0.5, 64.0), Vector3(64.0, 0.5, 66.0)]},
		{"type": "grunt", "pos": Vector3(-60.0, 0.5, -46.0), "patrol": [Vector3(-60.0, 0.5, -46.0), Vector3(-66.0, 0.5, -52.0), Vector3(-56.0, 0.5, -54.0)]},
	]
	for data in spawns:
		var enemy := scene.instantiate() as GFEnemy
		if enemy == null:
			push_error("World: enemy scene is not a GFEnemy")
			continue
		enemy.configure(String(data["type"]))
		enemy.position = data["pos"]
		enemy.patrol_points = data["patrol"]
		add_child(enemy)
		enemy.died.connect(_on_enemy_died)


func _spawn_vehicle() -> void:
	vehicle = GFVehicle.new()
	# On the outpost cross street (x=0), clear of the station (z<=8)
	# and of the houses at (±16,12) and (14,14). Faces +z (away from
	# the station) so driving forward never starts inside a wall.
	vehicle.position = Vector3(0.0, 0.5, 14.0)
	vehicle.rotation.y = PI
	add_child(vehicle)
	pois.append({"pos": Vector3(0.0, 0.0, 14.0), "kind": "vehicle"})


func _spawn_hud() -> void:
	var scene: PackedScene = load(HUD_SCENE)
	if scene == null:
		push_error("World: HUD scene failed to load: " + HUD_SCENE)
		return
	hud = scene.instantiate() as GFHUD
	if hud == null:
		push_error("World: HUD scene is not a GFHUD")
		return
	add_child(hud)


func _process(delta: float) -> void:
	_zone_check_timer += delta
	if _zone_check_timer >= 0.5:
		_zone_check_timer = 0.0
		_check_zones()
		_update_lod()
	if player != null and player.global_position.y < -10.0:
		player.global_position = PLAYER_SPAWN
		player.velocity = Vector3.ZERO


## Manual LOD: detail props (roof vents, pipes, antenna) hide
## beyond 60 m from the player — checked twice a second, never
## every frame.
func _update_lod() -> void:
	if player == null:
		return
	var p := player.global_position
	for node in _detail_nodes:
		if is_instance_valid(node):
			node.visible = node.global_position.distance_to(p) < 60.0


func _check_zones() -> void:
	if player == null or mission == null or mission.completed:
		return
	var p: Vector3 = player.global_position
	for zone in _zones:
		var c: Vector3 = zone["center"]
		var h: Vector3 = zone["half"]
		if absf(p.x - c.x) <= h.x and absf(p.y - c.y) <= h.y and absf(p.z - c.z) <= h.z:
			mission.on_zone_entered(String(zone["id"]))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and player != null:
		player.try_interact()


func _on_zone_entered(zone_id: String) -> void:
	if mission != null:
		mission.on_zone_entered(zone_id)


func _on_interacted(inter: GFInteractable) -> void:
	match inter.action:
		"crate":
			if player != null:
				player.add_ammo("rifle", 30)
				player.add_ammo("pistol", 12)
				if inter.interact_id == "crate_2":
					player.add_item("shield_cell", 1)
				else:
					player.add_item("medkit", 1)
			inter.set_used()
		"core":
			if _core_mesh != null:
				var tween := _core_mesh.create_tween()
				tween.tween_property(_core_mesh, "scale", Vector3(0.01, 0.01, 0.01), 0.4)
			inter.set_used()
		"terminal":
			if _terminal_screen_mat != null:
				_terminal_screen_mat.emission = Color(0.2, 1.0, 0.3)
				_terminal_screen_mat.albedo_color = Color(0.2, 1.0, 0.3)
			inter.set_used()
		"pickup":
			if player != null and inter is GFPickup:
				var note := (inter as GFPickup).apply_to(player)
				if hud != null and note != "":
					hud.toast(note)
		"weapon":
			if player != null and inter is GFWeaponPickup:
				var note := (inter as GFWeaponPickup).apply_to(player)
				if hud != null and note != "":
					hud.toast(note)
		"loot":
			if hud != null and inter is GFLootBox:
				hud.open_loot(inter as GFLootBox)
	if mission != null:
		mission.on_interacted(inter)


func _on_enemy_died(enemy: GFEnemy) -> void:
	if mission != null:
		mission.on_enemy_defeated()
	var data := SaveManager.load_game()
	data["enemies_defeated_total"] = int(data.get("enemies_defeated_total", 0)) + 1
	SaveManager.save_game(data)
	# Loot box drops at the body with the enemy type's contents.
	var drops: Dictionary = GFGameData.ENEMY_DROPS.get(enemy.enemy_type, GFLootBox.STANDARD_DROPS)
	var box := GFLootBox.new()
	box.position = enemy.global_position + Vector3(0.0, 0.3, 0.0)
	box.set_drops(drops)
	add_child(box)
	box.action = "loot"
	box.interacted.connect(_on_interacted)


func toggle_pause() -> void:
	if player != null and player.dead:
		return
	if get_tree().paused:
		get_tree().paused = false
		if hud != null:
			hud.show_pause(false)
		if not DisplayServer.is_touchscreen_available():
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		get_tree().paused = true
		if hud != null:
			hud.show_pause(true)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
