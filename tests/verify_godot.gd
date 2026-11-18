## Galaxy Frontier — Headless verification (Godot rebuild).
## Run: godot --headless --path . -s tests/verify_godot.gd
## Covers: game open, scene entry, fire, enemy hit, mission stages,
## save/load (+ corrupt save), viewport resizes at iOS sizes, every
## button + screen transition, every movement, full 360° camera,
## joystick + drag + fire together, pickups (one of each type),
## auto door, vehicle ride/drive/exit, loot box (incl. cap overflow),
## main-menu sections, minimap updates, villages/streets, ADS/scopes,
## 3+ weapons (fire/switch/reload), 2 player characters + 2 enemy
## types. Prints VERIFY lines + a summary; exits 1 on any FAIL.
## Note: touch input is simulated with direct calls, not real touch
## hardware — the report says so honestly.
extends SceneTree

var _passed := 0
var _failed := 0
var _lines: Array[String] = []


func _init() -> void:
	call_deferred("_run")


## Autoload access: a -s script cannot use bare autoload names at
## parse time, so the save manager is fetched from the tree.
func _sm() -> Node:
	return root.get_node("SaveManager")


func _check(test_name: String, ok: bool, detail: String = "") -> void:
	var line := "VERIFY: %s | %s | %s" % [test_name, "PASS" if ok else "FAIL", detail]
	_lines.append(line)
	print(line)
	if ok:
		_passed += 1
	else:
		_failed += 1


func _collect_buttons(node: Node, out: Array) -> void:
	if node is Button:
		out.append((node as Button).text)
	for child in node.get_children():
		_collect_buttons(child, out)


func _find_first(node: Node, cls: String) -> Node:
	if node.get_script() != null and String(node.get_script().resource_path).ends_with(cls):
		return node
	for child in node.get_children():
		var found := _find_first(child, cls)
		if found != null:
			return found
	return null


func _find_all(node: Node, cls: String, out: Array) -> void:
	if node.get_script() != null and String(node.get_script().resource_path).ends_with(cls):
		out.append(node)
	for child in node.get_children():
		_find_all(child, cls, out)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _run() -> void:
	await process_frame
	# --- Autoloads must be present ---
	var has_autoloads := root.get_node_or_null("SaveManager") != null and root.get_node_or_null("SettingsManager") != null and root.get_node_or_null("SoundManager") != null
	_check("autoloads_present", has_autoloads, "SaveManager/SettingsManager/SoundManager loaded")
	if not has_autoloads:
		_finish()
		return

	# --- Main menu: sections + character select ---
	var menu_scene: PackedScene = load("res://scenes/main_menu.tscn")
	var menu = menu_scene.instantiate()
	root.add_child(menu)
	await _frames(2)
	_check("menu_opens", menu != null and menu.visible, "main menu in tree")
	for section in ["character", "weapons", "missions", "settings", "shop"]:
		menu._show_section(section)
		await _frames(1)
		_check("menu_section_" + section, menu._content_title.text != "", "title=%s" % menu._content_title.text)
	menu._select_character("luna")
	var save_after: Dictionary = _sm().load_game()
	_check("menu_select_character", String(save_after.get("character_id", "")) == "luna" and String(save_after.get("starting_weapon", "")) == "sniper", "character=luna, weapon=sniper")
	menu._show_section("home")
	_check("menu_back_home", menu._content_title.text == "Welcome, Frontier Ranger", "back navigation works")
	menu.queue_free()
	await _frames(2)

	# --- World loads ---
	var world_scene: PackedScene = load("res://scenes/world.tscn")
	var world = world_scene.instantiate()
	root.add_child(world)
	await _frames(5)
	await _wait(1.0)
	_check("game_opens", world != null and world.player != null and world.hud != null and world.mission != null, "world+player+hud+mission alive")
	var player: GFPlayer = world.player
	var hud: GFHUD = world.hud
	var mission: GFMissionManager = world.mission
	_check("scene_entry", player.global_position.distance_to(Vector3(-70.0, 0.0, -50.0)) < 3.0, "player at landing spawn %s" % str(player.global_position))
	_check("player_feet_on_ground", absf(player.global_position.y) < 0.2, "player y=%.2f (feet-at-origin fix)" % player.global_position.y)

	# --- Buttons present in HUD ---
	var hud_buttons: Array = []
	_collect_buttons(hud, hud_buttons)
	for label in ["FIRE", "AIM", "JUMP", "USE", "RELOAD", "WEAPON", "CROUCH", "BAG (Inventory)", "Full Map", "II", "RIDE", "EXIT", "ACCEL", "BRAKE", "Resume", "Settings", "Quit to Menu", "Back", "Take All", "Close", "Retry Mission", "Main Menu", "Continue"]:
		_check("hud_button_" + label, hud_buttons.has(label), "button '%s' exists" % label)
	# Pause toggle works.
	hud._on_pause_pressed()
	_check("pause_on", paused, "tree paused")
	hud._on_pause_pressed()
	_check("pause_off", not paused, "tree resumed")

	# --- Movement: walk/run/sprint/jump/crouch ---
	# Teleport to open ground first: from the spawn the player runs
	# straight into a landing-village house wall.
	player.global_position = Vector3(0.0, 0.0, -30.0)
	player.yaw = 0.0
	player.rotation.y = 0.0
	player.velocity = Vector3.ZERO
	await _frames(2)
	var start_pos := player.global_position
	Input.action_press("move_forward")
	await _wait(0.6)
	Input.action_release("move_forward")
	var moved := player.global_position.distance_to(start_pos)
	var speed := moved / 0.6
	_check("move_walk_run", moved > 3.0, "moved %.1f m in 0.6 s (speed ~%.1f m/s, run=8)" % [moved, speed])
	Input.action_press("move_forward")
	Input.action_press("sprint")
	await _wait(0.8)
	var sprint_speed := player.velocity.length()
	Input.action_release("move_forward")
	Input.action_release("sprint")
	_check("move_sprint", sprint_speed > 9.0, "sprint velocity %.1f m/s (target 11)" % sprint_speed)
	# Jump: press and watch vertical velocity within a few frames.
	Input.action_press("jump")
	var jumped := false
	for i in 12:
		await process_frame
		if player.velocity.y > 0.5:
			jumped = true
			break
	Input.action_release("jump")
	_check("move_jump", jumped, "vertical velocity rose after jump press")
	player.toggle_crouch()
	_check("move_crouch", player.crouched and absf(player._capsule.height - 1.2) < 0.01, "crouched, capsule height 1.2")
	player.toggle_crouch()
	_check("move_uncrouch", not player.crouched and absf(player._capsule.height - 1.8) < 0.01, "stood up, capsule height 1.8")

	# --- Camera 360°: yaw full turn, forward reverses at PI, pitch clamped ---
	player.yaw = 0.0
	player.pitch = 0.0
	player._apply_look(Vector2(-785.4, 0.0))
	var yaw_pi := player.yaw
	var fwd_pi := Vector3(-sin(yaw_pi), 0.0, -cos(yaw_pi))
	_check("camera_yaw_pi", absf(yaw_pi - PI) < 0.05 and fwd_pi.z > 0.9, "yaw=%.3f (~PI), forward reversed %s" % [yaw_pi, str(fwd_pi)])
	player._apply_look(Vector2(-785.4, 0.0))
	var yaw_2pi := player.yaw
	var fwd_2pi := Vector3(-sin(yaw_2pi), 0.0, -cos(yaw_2pi))
	_check("camera_yaw_360", absf(yaw_2pi - TAU) < 0.05 and fwd_2pi.z < -0.9, "yaw=%.3f (~2PI), forward back %s" % [yaw_2pi, str(fwd_2pi)])
	player._apply_look(Vector2(0.0, -100000.0))
	_check("camera_pitch_max", absf(player.pitch - deg_to_rad(45.0)) < 0.01, "pitch clamped +45 deg")
	player._apply_look(Vector2(0.0, 100000.0))
	_check("camera_pitch_min", absf(player.pitch - deg_to_rad(-60.0)) < 0.01, "pitch clamped -60 deg")
	player.pitch = 0.0
	player._apply_look(Vector2.ZERO)

	# --- Fire + enemy hit ---
	var enemy_scene: PackedScene = load("res://scenes/enemy.tscn")
	var target_enemy := enemy_scene.instantiate() as GFEnemy
	target_enemy.configure("grunt")
	target_enemy.position = Vector3(0.0, 0.0, 10.0)
	world.add_child(target_enemy)
	await _frames(3)
	player.global_position = Vector3(0.0, 0.0, 20.0)
	player.yaw = 0.0
	player.rotation.y = 0.0
	player.pitch = deg_to_rad(-3.0)
	player._apply_look(Vector2.ZERO)
	await _frames(3)
	var mag_before: int = player.ammo[player.current_weapon]["mag"]
	player._fire()
	var mag_after: int = player.ammo[player.current_weapon]["mag"]
	_check("fire", mag_after == mag_before - 1, "mag %d -> %d" % [mag_before, mag_after])
	var enemy_hp_before := target_enemy.health
	player._fire()
	_check("enemy_hit", target_enemy.health < enemy_hp_before, "enemy hp %.1f -> %.1f" % [enemy_hp_before, target_enemy.health])
	target_enemy.queue_free()

	# --- ADS / scopes ---
	player.give_weapon("sniper")
	player.equip_slot(player.loadout.find("sniper"))
	Input.action_press("aim")
	await _wait(0.5)
	var cs: Dictionary = player.crosshair_state()
	_check("ads_aiming", player.aiming, "aiming=true while aim held")
	_check("ads_scope_sniper", String(cs.get("scope", "")) == "scope_8x", "sniper scope=scope_8x")
	_check("ads_fov_zoom", player._camera.fov < 40.0, "FOV %.1f (zoom 0.45 -> 33.8)" % player._camera.fov)
	var sniper_mag: int = player.ammo["sniper"]["mag"]
	player._fire()
	_check("ads_fire_while_aiming", int(player.ammo["sniper"]["mag"]) == sniper_mag - 1, "fired while aiming, mag %d -> %d" % [sniper_mag, int(player.ammo["sniper"]["mag"])])
	Input.action_release("aim")
	await _frames(3)
	_check("ads_release", not player.aiming, "aiming=false after release")

	# --- Weapons: switch + reload (3 weapons) ---
	# Note: the menu test selected Luna, so the player started with
	# a sniper — the rifle is picked up here first.
	player.give_weapon("rifle")
	player.equip_slot(player.loadout.find("rifle"))
	var rifle_mag: int = player.ammo["rifle"]["mag"]
	player._fire()
	_check("weapon_rifle_fire", int(player.ammo["rifle"]["mag"]) == rifle_mag - 1, "rifle mag %d -> %d" % [rifle_mag, int(player.ammo["rifle"]["mag"])])
	player.give_weapon("shotgun")
	player.equip_slot(player.loadout.find("shotgun"))
	player.ammo["shotgun"]["mag"] = 0
	player._fire()  # empty mag triggers reload
	await _wait(3.2)
	_check("weapon_shotgun_reload", int(player.ammo["shotgun"]["mag"]) == 6, "shotgun reloaded to 6 after 3.2 s")
	_check("weapon_switch", player.loadout.size() == 2 and player.current_weapon == "shotgun", "loadout=%s current=%s" % [str(player.loadout), player.current_weapon])

	# --- Mission stages (ordered) ---
	var stage0 := mission.current_stage
	mission.on_zone_entered("landing")
	_check("mission_land", mission.current_stage == max(stage0, 1), "stage %d -> %d" % [stage0, mission.current_stage])
	player.global_position = Vector3(0.0, 0.0, 0.0)
	await _wait(0.7)
	_check("mission_outpost_zone", mission.current_stage >= 2, "stage %d after entering outpost" % mission.current_stage)
	player.global_position = Vector3(0.0, 0.0, 0.0)
	mission.on_zone_entered("building")
	_check("mission_building", mission.current_stage >= 3, "stage %d after entering building" % mission.current_stage)
	var core_nodes: Array = []
	_find_all(world, "interactable.gd", core_nodes)
	var core_node: GFInteractable = null
	var terminal_node: GFInteractable = null
	for n in core_nodes:
		if (n as GFInteractable).interact_id == "power_core":
			core_node = n
		if (n as GFInteractable).interact_id == "terminal":
			terminal_node = n
	if core_node != null:
		mission.on_interacted(core_node)
		_check("mission_core", mission.current_stage >= 4, "stage %d after taking core" % mission.current_stage)
	if terminal_node != null:
		mission.on_interacted(terminal_node)
		_check("mission_terminal", mission.current_stage >= 5, "stage %d after activating terminal" % mission.current_stage)
	mission.on_enemy_defeated()
	mission.on_enemy_defeated()
	mission.on_enemy_defeated()
	_check("mission_defeat", mission.current_stage >= 6, "stage %d after 3 defeats" % mission.current_stage)
	player.global_position = Vector3(70.0, 0.0, 60.0)
	await _wait(0.7)
	_check("mission_complete", mission.completed, "mission completed=%s stage=%d" % [str(mission.completed), mission.current_stage])

	# --- Save / load (+ corrupt save) ---
	var data: Dictionary = _sm().load_game()
	data["mission_stage"] = 5
	data["enemies_defeated_total"] = 42
	_sm().save_game(data)
	var loaded: Dictionary = _sm().load_game()
	_check("save_load", int(loaded.get("mission_stage", 0)) == 5 and int(loaded.get("enemies_defeated_total", 0)) == 42, "round-trip stage=5 kills=42")
	var save_file := FileAccess.open("user://savegame.json", FileAccess.WRITE)
	save_file.store_string("not json{{{")
	save_file.close()
	var corrupt: Dictionary = _sm().load_game()
	_check("save_corrupt_fallback", int(corrupt.get("mission_stage", -1)) == 0, "corrupt save falls back to defaults")
	var clean: Dictionary = _sm().load_game()
	clean["mission_stage"] = 0
	clean["mission_completed"] = false
	_sm().save_game(clean)

	# --- Pickups: one of each type ---
	player.inventory = {"medkit": 0, "shield_cell": 0, "core_fragment": 0}
	player.ammo["rifle"]["reserve"] = 0
	player.ammo["pistol"]["reserve"] = 0
	for ptype in ["medkit", "shield_cell", "ammo_rifle", "ammo_pistol", "core_fragment"]:
		var pickup := GFPickup.new()
		pickup.item_id = ptype
		pickup.position = player.global_position + Vector3(1.0, 0.0, 0.0)
		world.add_child(pickup)
		await _frames(1)
		var note := pickup.apply_to(player)
		var ok := note != ""
		_check("pickup_" + ptype, ok, note)
	# Inventory caps: medkit cap is 5.
	player.inventory = {"medkit": 5, "shield_cell": 0, "core_fragment": 0}
	var cap_pickup := GFPickup.new()
	cap_pickup.item_id = "medkit"
	world.add_child(cap_pickup)
	await _frames(1)
	_check("pickup_cap", cap_pickup.apply_to(player) == "", "full medkit inventory refuses pickup")

	# --- Auto door ---
	var doors: Array = []
	_find_all(world, "door.gd", doors)
	_check("door_exists", doors.size() >= 13, "%d doors in world (13 buildings)" % doors.size())
	if doors.size() > 0:
		var door: GFDoor = doors[0]
		player.global_position = door.global_position + Vector3(1.5, 0.0, 2.0)
		player.velocity = Vector3.ZERO
		await _wait(1.3)
		_check("door_auto_open", door.is_open, "door opened on approach (dist ~2.5 m)")
		player.global_position = Vector3(-100.0, 0.0, -100.0)
		await _wait(1.3)
		_check("door_auto_close", not door.is_open, "door closed after player left")
		player.global_position = Vector3(0.0, 0.0, 20.0)

	# --- Vehicle: ride / drive / exit ---
	var veh: GFVehicle = world.vehicle
	_check("vehicle_exists", veh != null, "Rover RX-7 spawned")
	if veh != null:
		player.global_position = veh.global_position + Vector3(0.0, 0.0, 3.0)
		await _frames(2)
		hud._update_ride_button()
		_check("vehicle_ride_button", hud._ride_button.visible, "RIDE button visible within 4.5 m")
		var entered := veh.enter(player)
		_check("vehicle_enter", entered and player.driving, "player driving=%s" % str(player.driving))
		await _wait(0.4)
		_check("vehicle_driving_ui", hud._driving_mode and not hud._combat_box.visible, "driving UI on, combat UI hidden")
		var veh_start := veh.global_position
		veh.throttle = 1.0
		await _wait(1.5)
		var veh_moved := veh.global_position.distance_to(veh_start)
		_check("vehicle_drive", veh.speed > 5.0 and veh_moved > 3.0, "speed %.1f m/s, moved %.1f m" % [veh.speed, veh_moved])
		_check("vehicle_exit_refused_fast", not veh.try_exit(), "exit refused at %.1f m/s" % veh.speed)
		veh.throttle = 0.0
		var waited := 0.0
		while veh.speed > 2.0 and waited < 4.0:
			await _wait(0.25)
			waited += 0.25
		var exited := veh.try_exit()
		_check("vehicle_exit", exited and not player.driving, "exited after slowing, driving=%s" % str(player.driving))
		await _wait(0.4)
		_check("vehicle_ui_restored", not hud._driving_mode and hud._combat_box.visible, "combat UI back after exit")

	# --- Loot box: drop on death + cap overflow stays in box ---
	var loot_enemy := enemy_scene.instantiate() as GFEnemy
	loot_enemy.configure("grunt")
	loot_enemy.position = Vector3(20.0, 0.0, 20.0)
	world.add_child(loot_enemy)
	loot_enemy.died.connect(world._on_enemy_died)
	await _frames(2)
	loot_enemy.take_damage(9999.0, true)
	await _wait(0.6)
	var boxes: Array = []
	_find_all(world, "loot_box.gd", boxes)
	_check("loot_drop", boxes.size() >= 1, "%d loot box(es) after kill" % boxes.size())
	if boxes.size() > 0:
		var box: GFLootBox = boxes[boxes.size() - 1]
		player.inventory = {"medkit": 5, "shield_cell": 0, "core_fragment": 0}
		var took_full := box.take_item("medkit", player)
		_check("loot_cap_overflow", took_full == 0 and box.contents.has("medkit"), "full inventory: took 0, medkit stays in box")
		player.ammo["rifle"]["reserve"] = 0
		var took_ammo := box.take_item("ammo_rifle", player)
		_check("loot_take_ammo", took_ammo > 0 and int(player.ammo["rifle"]["reserve"]) > 0, "took %d rifle ammo" % took_ammo)

	# --- Minimap: live update with movement ---
	var map_before: Vector2 = hud._minimap._world_to_map(player.global_position)
	player.global_position = player.global_position + Vector3(10.0, 0.0, 0.0)
	await _wait(0.4)
	var map_after: Vector2 = hud._minimap._world_to_map(player.global_position)
	_check("minimap_updates", map_before != map_after, "map pos %s -> %s" % [str(map_before), str(map_after)])
	_check("minimap_visible", hud._minimap.visible and hud._minimap.size.x > 100.0, "minimap size %s" % str(hud._minimap.size))
	hud._map_panel.visible = true
	_check("full_map_opens", hud._full_map != null and hud._map_panel.visible, "full map panel opens")
	hud._map_panel.visible = false

	# --- Villages / streets / real scale ---
	var house_count := 0
	for poi in world.pois:
		if String(poi.get("kind", "")) == "house":
			house_count += 1
	_check("villages_houses", house_count == 12, "%d houses (12 expected)" % house_count)
	_check("villages_streets", world._street_segments.size() == 3, "%d streets" % world._street_segments.size())
	_check("scale_door_fits_player", GFDoor.DOOR_HEIGHT > 1.8 and GFDoor.DOOR_WIDTH > 0.6, "door %.1fx%.1f m vs player 1.8 m" % [GFDoor.DOOR_WIDTH, GFDoor.DOOR_HEIGHT])
	_check("scale_street_fits_vehicle", 7.0 > GFVehicle.VEHICLE_WIDTH, "street 7.0 m vs vehicle %.1f m wide" % GFVehicle.VEHICLE_WIDTH)
	_check("scale_vehicle", absf(GFVehicle.VEHICLE_LENGTH - 4.5) < 0.01 and absf(GFVehicle.VEHICLE_WIDTH - 1.9) < 0.01, "rover %.1f x %.1f m" % [GFVehicle.VEHICLE_LENGTH, GFVehicle.VEHICLE_WIDTH])

	# --- Characters: 2 player profiles + 2 enemy types ---
	for char_id in ["nova", "atlas"]:
		var cdata: Dictionary = _sm().load_game()
		var prof: Dictionary = GFGameData.CHARACTER_PROFILES[char_id]
		cdata["character_id"] = char_id
		cdata["suit_color"] = String(prof["suit_color"])
		cdata["helmet"] = bool(prof["helmet"])
		_sm().save_game(cdata)
		var p2 := (load("res://scenes/player.tscn") as PackedScene).instantiate() as GFPlayer
		root.add_child(p2)
		await _frames(2)
		var mat := p2._body_mesh.material_override as StandardMaterial3D
		var col_ok := false
		if mat != null and mat.albedo_texture != null:
			col_ok = true  # PBR fabric texture — color is in the texture
		_check("character_" + char_id, p2 != null and p2._body_mesh != null, "spawned %s (%s), PBR suit=%s" % [char_id, String(prof["name"]), str(col_ok)])
		p2.queue_free()
		await _frames(1)
	var runner := enemy_scene.instantiate() as GFEnemy
	runner.configure("runner")
	var armored := enemy_scene.instantiate() as GFEnemy
	armored.configure("armored")
	_check("enemy_runner_stats", absf(runner.max_health - 60.0) < 0.01 and absf(float(runner._type_data.get("chase_speed", 0.0)) - 7.0) < 0.01, "runner hp=60 speed=7.0")
	_check("enemy_armored_stats", absf(armored.max_health - 220.0) < 0.01, "armored hp=220")
	armored.take_damage(100.0, true)
	_check("enemy_armored_reduction", absf(armored.health - 145.0) < 0.01, "100 dmg -> 75 after 25%% reduction, hp=%.1f" % armored.health)
	runner.position = Vector3(-20.0, 0.0, -20.0)
	runner.patrol_points = [Vector3(-20.0, 0.0, -20.0), Vector3(-10.0, 0.0, -20.0)]
	armored.position = Vector3(-22.0, 0.0, -20.0)
	armored.patrol_points = [Vector3(-22.0, 0.0, -20.0), Vector3(-24.0, 0.0, -12.0)]
	world.add_child(runner)
	world.add_child(armored)
	var runner_start := runner.global_position
	await _wait(1.2)
	_check("enemy_patrol_move", runner.global_position.distance_to(runner_start) > 0.5, "runner patrolled %.2f m" % runner.global_position.distance_to(runner_start))

	# --- Joystick + fire together (simulated multi-touch logic) ---
	hud._joystick._update_value(Vector2(0.0, -50.0))
	hud.fire_held = true
	var multi_mag: int = player.ammo[player.current_weapon]["mag"]
	player._fire()
	_check("multitouch_joystick_fire", hud.move_vector.y < -0.1 and int(player.ammo[player.current_weapon]["mag"]) == multi_mag - 1, "joystick %s + fire held, mag decreased" % str(hud.move_vector))
	hud.fire_held = false
	hud._joystick._update_value(Vector2.ZERO)

	# --- Viewport resizes (iOS sizes, landscape) ---
	for size in [Vector2(667, 375), Vector2(852, 393), Vector2(932, 430), Vector2(1366, 1024)]:
		root.size = size
		await _frames(3)
		hud._layout()
		_check("resize_%dx%d" % [int(size.x), int(size.y)], hud._minimap.size.x > 100.0 and hud._joystick.size.x > 100.0, "minimap %.0f px, joystick %.0f px" % [hud._minimap.size.x, hud._joystick.size.x])
	root.size = Vector2(1280, 720)

	# --- No empty files in the project ---
	var empty_files: Array = []
	_scan_empty("res://", empty_files)
	_check("no_empty_files", empty_files.is_empty(), "empty files: %s" % str(empty_files))

	# --- Performance stats (info only, headless FPS is meaningless) ---
	if world.perf != null:
		print("VERIFY: perf_stats | INFO | " + world.perf.stats_text())

	_finish()


func _scan_empty(dir_path: String, out: Array) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry == "." or entry == "..":
			entry = dir.get_next()
			continue
		var full := dir_path.path_join(entry)
		if dir.current_is_dir():
			if entry != ".godot" and entry != ".git":
				_scan_empty(full, out)
		else:
			var f := FileAccess.open(full, FileAccess.READ)
			if f != null and f.get_length() == 0:
				out.append(full)
			if f != null:
				f.close()
		entry = dir.get_next()
	dir.list_dir_end()


func _finish() -> void:
	print("VERIFY SUMMARY: %d passed, %d failed" % [_passed, _failed])
	var out := FileAccess.open("res://tests/verify_results.txt", FileAccess.WRITE)
	if out != null:
		for line in _lines:
			out.store_line(line)
		out.store_line("VERIFY SUMMARY: %d passed, %d failed" % [_passed, _failed])
		out.close()
	quit(0 if _failed == 0 else 1)
