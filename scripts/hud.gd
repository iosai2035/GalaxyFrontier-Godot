## Galaxy Frontier — HUD (CanvasLayer, built in code).
## Fully responsive mobile UI — every element uses anchors and
## containers, sizes are viewport fractions (never fixed pixels),
## and Safe Areas (notch / Dynamic Island / iPad edges) are applied
## on every screen via DisplayServer.get_display_safe_area().
## Working: virtual joystick, Fire/Aim/Jump/Use/Reload/Weapon/
## Crouch buttons, health + shield bars, ammo counter, objective,
## live minimap (+ full map), inventory, loot box panel, driving
## controls (steer joystick + Accelerate/Brake + Exit) that replace
## the walk/combat buttons while driving, RIDE button near a
## vehicle, toasts, pause/settings, game-over and mission-complete.
## Multi-touch: joystick, camera drag and Fire are separate
## controls, so they work at the same time without conflict.
## Every button has a working handler — no decorative buttons.
class_name GFHUD
extends CanvasLayer

var move_vector: Vector2 = Vector2.ZERO
var fire_held: bool = false
var aim_held: bool = false

var _player: GFPlayer = null
var _mission: GFMissionManager = null
var _world: Node = null

var _root: Control
var _top_left: VBoxContainer
var _top_right: VBoxContainer
var _objective_label: Label
var _health_bar: ProgressBar
var _shield_bar: ProgressBar
var _health_label: Label
var _ammo_label: Label
var _weapon_label: Label
var _fps_label: Label
var _prompt_label: Label
var _toast_label: Label
var _flash: ColorRect
var _crosshair: GFCrosshair
var _joystick: GFJoystick
var _minimap: GFMinimap
var _full_map: GFMinimap
var _combat_box: VBoxContainer
var _drive_box: HBoxContainer
var _steer_joystick: GFJoystick
var _ride_button: Button
var _exit_button: Button
var _interact_button: Button
var _pause_panel: PanelContainer
var _settings_panel: PanelContainer
var _inventory_panel: PanelContainer
var _inventory_list: VBoxContainer
var _loot_panel: PanelContainer
var _loot_list: VBoxContainer
var _loot_box: GFLootBox = null
var _map_panel: PanelContainer
var _game_over_panel: PanelContainer
var _complete_panel: PanelContainer
var _ui_timer: float = 0.0
var _toast_timer: float = 0.0
var _driving_mode: bool = false
var _ui_scale: float = 1.0


func _ready() -> void:
	add_to_group("hud")
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_build()
	get_viewport().size_changed.connect(_layout)
	_layout()


## Safe-area margins in pixels (0 on desktop / Linux).
func _safe_margins() -> Dictionary:
	var vp := get_viewport().get_visible_rect().size
	var safe := DisplayServer.get_display_safe_area()
	var m := {
		"left": maxf(0.0, safe.position.x),
		"top": maxf(0.0, safe.position.y),
		"right": maxf(0.0, vp.x - safe.end.x),
		"bottom": maxf(0.0, vp.y - safe.end.y),
	}
	return m


func _layout() -> void:
	var vp := get_viewport().get_visible_rect().size
	if vp.x <= 0.0 or vp.y <= 0.0:
		return
	_ui_scale = clampf(minf(vp.x / 1280.0, vp.y / 720.0), 0.7, 1.4)
	var m := _safe_margins()
	var sl: float = m["left"]
	var st: float = m["top"]
	var sr: float = m["right"]
	var sb: float = m["bottom"]
	# Top-left status block.
	_top_left.position = Vector2(sl + 12.0, st + 10.0)
	var bar_w := clampf(vp.x * 0.22, 180.0, 300.0)
	_health_bar.custom_minimum_size = Vector2(bar_w, 18.0 * _ui_scale)
	_shield_bar.custom_minimum_size = Vector2(bar_w, 18.0 * _ui_scale)
	_top_left.size = _top_left.get_combined_minimum_size()
	# Top-right: minimap + weapon info.
	var map_size := clampf(vp.y * 0.28, 140.0, 260.0)
	_minimap.custom_minimum_size = Vector2(map_size, map_size)
	_top_right.position = Vector2(vp.x - sr - 12.0 - map_size - 8.0, st + 10.0)
	_top_right.custom_minimum_size = Vector2(map_size + 8.0, 0.0)
	_top_right.size = _top_right.get_combined_minimum_size()
	# Objective: centered strip, 60% of the width.
	_objective_label.position = Vector2(vp.x * 0.2, st + 8.0)
	_objective_label.custom_minimum_size = Vector2(vp.x * 0.6, 30.0)
	_objective_label.size = _objective_label.custom_minimum_size
	# Joystick bottom-left.
	var joy_size := clampf(minf(vp.x, vp.y) * 0.24, 150.0, 220.0)
	_joystick.custom_minimum_size = Vector2(joy_size, joy_size)
	_joystick.size = _joystick.custom_minimum_size
	_joystick.position = Vector2(sl + 16.0, vp.y - sb - 16.0 - joy_size)
	# Combat buttons bottom-right.
	var btn := 84.0 * _ui_scale
	_combat_box.size = _combat_box.get_combined_minimum_size()
	_combat_box.position = Vector2(vp.x - sr - 16.0 - _combat_box.size.x, vp.y - sb - 16.0 - _combat_box.size.y)
	# Drive controls: steer joystick left, pedals right.
	_steer_joystick.custom_minimum_size = Vector2(joy_size, joy_size)
	_steer_joystick.size = _steer_joystick.custom_minimum_size
	_steer_joystick.position = Vector2(sl + 16.0, vp.y - sb - 16.0 - joy_size)
	_drive_box.size = _drive_box.get_combined_minimum_size()
	_drive_box.position = Vector2(vp.x - sr - 16.0 - _drive_box.size.x, vp.y - sb - 16.0 - _drive_box.size.y)
	# Prompt + toast above the bottom center.
	_prompt_label.position = Vector2(vp.x * 0.5 - 200.0, vp.y - sb - 120.0)
	_prompt_label.size = Vector2(400.0, 30.0)
	_toast_label.position = Vector2(vp.x * 0.5 - 220.0, vp.y - sb - 160.0)
	_toast_label.size = Vector2(440.0, 30.0)
	_ride_button.size = _ride_button.custom_minimum_size
	_ride_button.position = Vector2(vp.x * 0.5 - 70.0, vp.y - sb - 220.0)
	# Panels: centered, width capped at 85% of the viewport.
	var panel_w := minf(vp.x * 0.85, 440.0)
	_full_map.custom_minimum_size = Vector2(minf(vp.x * 0.7, 460.0), minf(vp.y * 0.7, 460.0))
	for panel in [_pause_panel, _settings_panel, _inventory_panel, _loot_panel, _map_panel, _game_over_panel, _complete_panel]:
		if panel == null:
			continue
		panel.custom_minimum_size = Vector2(panel_w, 0.0)
		panel.size = panel.get_combined_minimum_size()
		panel.position = (vp - panel.size) / 2.0


func bind_world(world: Node, player: GFPlayer, mission: GFMissionManager) -> void:
	_world = world
	_player = player
	_mission = mission
	player.health_changed.connect(_on_health_changed)
	player.ammo_changed.connect(_on_ammo_changed)
	player.weapon_changed.connect(_on_weapon_changed)
	player.inventory_changed.connect(_on_inventory_changed)
	player.interact_prompt_changed.connect(_on_prompt_changed)
	player.died.connect(show_game_over)
	mission.stage_changed.connect(_on_stage_changed)
	mission.mission_completed.connect(show_mission_complete)
	_minimap.bind(world, player, mission)
	_full_map.bind(world, player, mission)
	if world != null and "pois" in world:
		_minimap.pois = world.pois
		_full_map.pois = world.pois
	_on_health_changed(player.health, player.shield)
	_on_stage_changed(mission.current_stage, mission.current_text())
	_layout()


func _bar_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style


func _bg_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.55)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style


func _make_bar(fill: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 100.0
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", _bg_style())
	bar.add_theme_stylebox_override("fill", _bar_style(fill))
	return bar


func _make_button(text: String, min_size: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", int(16.0 * _ui_scale))
	return b


func _build() -> void:
	_flash = ColorRect.new()
	_flash.color = Color(1.0, 0.0, 0.0, 0.0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_flash)
	_crosshair = GFCrosshair.new()
	_root.add_child(_crosshair)

	# Top-left: health / shield / FPS.
	_top_left = VBoxContainer.new()
	_top_left.add_theme_constant_override("separation", 4)
	_root.add_child(_top_left)
	_health_label = Label.new()
	_health_label.text = "HP 100 / 100"
	_top_left.add_child(_health_label)
	_health_bar = _make_bar(Color(0.2, 0.85, 0.3))
	_top_left.add_child(_health_bar)
	var shield_label := Label.new()
	shield_label.text = "Shield"
	_top_left.add_child(shield_label)
	_shield_bar = _make_bar(Color(0.2, 0.6, 1.0))
	_top_left.add_child(_shield_bar)
	_fps_label = Label.new()
	_fps_label.text = ""
	_top_left.add_child(_fps_label)
	var bag_button := _make_button("BAG (Inventory)", Vector2(170.0, 40.0))
	bag_button.pressed.connect(_open_inventory)
	_top_left.add_child(bag_button)

	# Top-right: minimap, weapon, ammo, pause, full map.
	_top_right = VBoxContainer.new()
	_top_right.add_theme_constant_override("separation", 4)
	_root.add_child(_top_right)
	_minimap = GFMinimap.new()
	_minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_right.add_child(_minimap)
	_weapon_label = Label.new()
	_weapon_label.text = "Assault Rifle"
	_top_right.add_child(_weapon_label)
	_ammo_label = Label.new()
	_ammo_label.text = "30 / 240"
	_top_right.add_child(_ammo_label)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 6)
	_top_right.add_child(top_row)
	var map_button := _make_button("Full Map", Vector2(110.0, 40.0))
	map_button.pressed.connect(func() -> void: _map_panel.visible = true)
	top_row.add_child(map_button)
	var pause_button := _make_button("II", Vector2(56.0, 40.0))
	pause_button.pressed.connect(_on_pause_pressed)
	top_row.add_child(pause_button)

	# Objective (center top).
	_objective_label = Label.new()
	_objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective_label.text = "Objective"
	_root.add_child(_objective_label)

	# Prompt + toast (center bottom).
	_prompt_label = Label.new()
	_prompt_label.custom_minimum_size = Vector2(400.0, 30.0)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.text = ""
	_root.add_child(_prompt_label)
	_toast_label = Label.new()
	_toast_label.custom_minimum_size = Vector2(440.0, 30.0)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.text = ""
	_root.add_child(_toast_label)

	# Joystick (bottom-left).
	_joystick = GFJoystick.new()
	_joystick.moved.connect(func(v: Vector2) -> void: move_vector = v)
	_root.add_child(_joystick)

	# Combat buttons (bottom-right).
	_combat_box = VBoxContainer.new()
	_combat_box.add_theme_constant_override("separation", 8)
	_root.add_child(_combat_box)
	var btn := 84.0
	var fire_button := _make_button("FIRE", Vector2(btn * 1.4, btn * 1.4))
	fire_button.button_down.connect(func() -> void: fire_held = true)
	fire_button.button_up.connect(func() -> void: fire_held = false)
	_combat_box.add_child(fire_button)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_combat_box.add_child(row)
	var aim_button := _make_button("AIM", Vector2(btn, btn * 0.75))
	aim_button.button_down.connect(func() -> void: aim_held = true)
	aim_button.button_up.connect(func() -> void: aim_held = false)
	row.add_child(aim_button)
	var jump_button := _make_button("JUMP", Vector2(btn, btn * 0.75))
	jump_button.button_down.connect(func() -> void: Input.action_press("jump"))
	jump_button.button_up.connect(func() -> void: Input.action_release("jump"))
	row.add_child(jump_button)
	_interact_button = _make_button("USE", Vector2(btn, btn * 0.75))
	_interact_button.pressed.connect(_on_interact_pressed)
	row.add_child(_interact_button)
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 8)
	_combat_box.add_child(row2)
	var reload_button := _make_button("RELOAD", Vector2(btn, btn * 0.66))
	reload_button.pressed.connect(func() -> void: Input.action_press("reload"))
	reload_button.button_up.connect(func() -> void: Input.action_release("reload"))
	row2.add_child(reload_button)
	var switch_button := _make_button("WEAPON", Vector2(btn, btn * 0.66))
	switch_button.pressed.connect(func() -> void: Input.action_press("switch_weapon"))
	switch_button.button_up.connect(func() -> void: Input.action_release("switch_weapon"))
	row2.add_child(switch_button)
	var crouch_button := _make_button("CROUCH", Vector2(btn, btn * 0.66))
	crouch_button.pressed.connect(func() -> void:
		if _player != null:
			_player.toggle_crouch())
	row2.add_child(crouch_button)

	# Driving controls (hidden until driving).
	_steer_joystick = GFJoystick.new()
	_steer_joystick.visible = false
	_steer_joystick.moved.connect(_on_steer_moved)
	_root.add_child(_steer_joystick)
	_drive_box = HBoxContainer.new()
	_drive_box.add_theme_constant_override("separation", 8)
	_drive_box.visible = false
	_root.add_child(_drive_box)
	var accel_button := _make_button("ACCEL", Vector2(btn, btn * 2.0))
	accel_button.button_down.connect(func() -> void: _set_drive_throttle(1.0))
	accel_button.button_up.connect(func() -> void: _set_drive_throttle(0.0))
	_drive_box.add_child(accel_button)
	var brake_button := _make_button("BRAKE", Vector2(btn, btn * 2.0))
	brake_button.button_down.connect(func() -> void: _set_drive_throttle(-1.0))
	brake_button.button_up.connect(func() -> void: _set_drive_throttle(0.0))
	_drive_box.add_child(brake_button)
	_exit_button = _make_button("EXIT", Vector2(btn, btn * 2.0))
	_exit_button.pressed.connect(_on_exit_pressed)
	_drive_box.add_child(_exit_button)

	# RIDE button (appears near a vehicle).
	_ride_button = _make_button("RIDE", Vector2(140.0, 64.0))
	_ride_button.visible = false
	_ride_button.pressed.connect(_on_ride_pressed)
	_root.add_child(_ride_button)

	# Panels.
	_pause_panel = _make_panel("PAUSED")
	_add_panel_button(_pause_panel, "Resume", _on_resume_pressed)
	_add_panel_button(_pause_panel, "Settings", _show_settings)
	_add_panel_button(_pause_panel, "Quit to Menu", _on_quit_pressed)
	_add_panel_button(_pause_panel, "Back", _on_resume_pressed)
	_settings_panel = _make_panel("SETTINGS")
	_build_settings(_settings_panel.get_child(0) as VBoxContainer)
	_inventory_panel = _make_panel("INVENTORY")
	_inventory_list = VBoxContainer.new()
	_inventory_list.add_theme_constant_override("separation", 6)
	_inventory_panel.get_child(0).add_child(_inventory_list)
	_add_panel_button(_inventory_panel, "Close", func() -> void: _inventory_panel.visible = false)
	_loot_panel = _make_panel("LOOT BOX")
	_loot_list = VBoxContainer.new()
	_loot_list.add_theme_constant_override("separation", 6)
	_loot_panel.get_child(0).add_child(_loot_list)
	_add_panel_button(_loot_panel, "Take All", _on_take_all_pressed)
	_add_panel_button(_loot_panel, "Close", func() -> void: _loot_panel.visible = false)
	_map_panel = _make_panel("MAP — ZERON")
	_full_map = GFMinimap.new()
	_full_map.custom_minimum_size = Vector2(420.0, 420.0)
	_map_panel.get_child(0).add_child(_full_map)
	_add_panel_button(_map_panel, "Close", func() -> void: _map_panel.visible = false)
	_game_over_panel = _make_panel("YOU DIED")
	_add_panel_button(_game_over_panel, "Retry Mission", _on_retry_pressed)
	_add_panel_button(_game_over_panel, "Main Menu", _on_quit_pressed)
	_complete_panel = _make_panel("MISSION COMPLETE")
	var complete_label := Label.new()
	complete_label.text = "The Lost Power Core is restored.\nZERON is safe — for now."
	complete_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_complete_panel.get_child(0).add_child(complete_label)
	_add_panel_button(_complete_panel, "Continue", func() -> void: _complete_panel.visible = false)
	_add_panel_button(_complete_panel, "Main Menu", _on_quit_pressed)


func _make_panel(title: String) -> PanelContainer:
	var panel := PanelContainer.new()
	# Top-left anchors; _layout() centers it with explicit size.
	panel.custom_minimum_size = Vector2(360.0, 0.0)
	panel.visible = false
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var title_label := Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title_label)
	_root.add_child(panel)
	return panel


func _add_panel_button(panel: PanelContainer, text: String, handler: Callable) -> void:
	var b := _make_button(text, Vector2(260.0, 48.0))
	b.pressed.connect(handler)
	(panel.get_child(0) as VBoxContainer).add_child(b)


func _build_settings(box: VBoxContainer) -> void:
	var sens_label := Label.new()
	sens_label.text = "Camera sensitivity"
	box.add_child(sens_label)
	var sens_slider := HSlider.new()
	sens_slider.min_value = 0.1
	sens_slider.max_value = 3.0
	sens_slider.step = 0.1
	sens_slider.value = SettingsManager.sensitivity
	sens_slider.custom_minimum_size = Vector2(260.0, 24.0)
	sens_slider.value_changed.connect(func(v: float) -> void:
		SettingsManager.sensitivity = v
		SettingsManager.save_settings())
	box.add_child(sens_slider)
	var quality_label := Label.new()
	quality_label.text = "Graphics quality"
	box.add_child(quality_label)
	var quality_option := OptionButton.new()
	for q in SettingsManager.QUALITY_NAMES:
		quality_option.add_item(q)
	quality_option.selected = SettingsManager.quality
	quality_option.custom_minimum_size = Vector2(260.0, 40.0)
	quality_option.item_selected.connect(func(index: int) -> void:
		SettingsManager.quality = index
		SettingsManager.save_settings()
		SettingsManager.apply_quality())
	box.add_child(quality_option)
	var invert_check := CheckButton.new()
	invert_check.text = "Invert camera Y"
	invert_check.button_pressed = SettingsManager.invert_y
	invert_check.toggled.connect(func(on: bool) -> void:
		SettingsManager.invert_y = on
		SettingsManager.save_settings())
	box.add_child(invert_check)
	var back_button := _make_button("Back", Vector2(260.0, 48.0))
	back_button.pressed.connect(func() -> void:
		_settings_panel.visible = false
		_pause_panel.visible = true)
	box.add_child(back_button)


func _process(delta: float) -> void:
	_ui_timer += delta
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0:
			_toast_label.text = ""
	if _flash.color.a > 0.0:
		var c := _flash.color
		c.a = maxf(0.0, c.a - delta * 2.0)
		_flash.color = c
	# Throttled UI refresh (0.25 s): FPS, crosshair, driving mode,
	# ride proximity. Never heavy per-frame polling.
	if _ui_timer >= 0.25:
		_ui_timer = 0.0
		_fps_label.text = "%d FPS" % Engine.get_frames_per_second()
		if _player != null:
			_crosshair.update_state(_player.crosshair_state())
			_set_driving_mode(_player.driving)
			_update_ride_button()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_on_pause_pressed()


func _set_driving_mode(driving: bool) -> void:
	if driving == _driving_mode:
		return
	_driving_mode = driving
	_combat_box.visible = not driving
	_joystick.visible = not driving
	_drive_box.visible = driving
	_steer_joystick.visible = driving
	_interact_button.visible = not driving
	if not driving:
		_set_drive_throttle(0.0)


func _on_steer_moved(v: Vector2) -> void:
	if _world != null and _world.vehicle != null:
		_world.vehicle.steer = clampf(v.x, -1.0, 1.0)


func _set_drive_throttle(value: float) -> void:
	if _world != null and _world.vehicle != null:
		_world.vehicle.throttle = value


func _update_ride_button() -> void:
	if _player == null or _world == null or _world.vehicle == null:
		_ride_button.visible = false
		return
	if _player.driving:
		_ride_button.visible = false
		return
	var dist: float = _player.global_position.distance_to(_world.vehicle.global_position)
	_ride_button.visible = dist <= 4.5


func _on_ride_pressed() -> void:
	if _world != null and _world.vehicle != null and _player != null:
		if _world.vehicle.enter(_player):
			toast("Driving the Rover RX-7")
		else:
			toast("Vehicle is occupied")


func _on_exit_pressed() -> void:
	if _world != null and _world.vehicle != null:
		if _world.vehicle.try_exit():
			toast("Exited the vehicle")
		else:
			toast("Too fast to exit — slow down first!")


func toast(message: String) -> void:
	_toast_label.text = message
	_toast_timer = 2.5


func open_loot(box: GFLootBox) -> void:
	_loot_box = box
	_refresh_loot()
	_loot_panel.visible = true


func _refresh_loot() -> void:
	for child in _loot_list.get_children():
		child.queue_free()
	if _loot_box == null or _loot_box.is_empty():
		_loot_panel.visible = false
		return
	for item_id in _loot_box.contents.keys():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var label := Label.new()
		var amount: int = _loot_box.contents[item_id]
		var item_label: String = item_id
		if GFPickup.ITEM_INFO.has(item_id):
			item_label = String(GFPickup.ITEM_INFO[item_id]["name"])
		elif item_id.begins_with("ammo_"):
			name = "%s Ammo" % String(GFPlayer.WEAPONS.get(item_id.substr(5), {}).get("name", item_id))
		label.text = "%s x%d" % [item_label, amount]
		row.add_child(label)
		var take_button := _make_button("Take", Vector2(90.0, 40.0))
		var id: String = item_id
		take_button.pressed.connect(func() -> void:
			if _loot_box != null and _player != null:
				var taken: int = _loot_box.take_item(id, _player)
				if taken > 0:
					toast("Took %d x %s" % [taken, item_label])
					_refresh_loot()
				else:
					toast("No room — inventory full"))
		row.add_child(take_button)
		_loot_list.add_child(row)


func _on_take_all_pressed() -> void:
	if _loot_box != null and _player != null:
		var result: Dictionary = _loot_box.take_all(_player)
		var total := 0
		for key in result:
			total += int(result[key])
		toast("Took %d items from the loot box" % total if total > 0 else "Nothing fit — inventory full")
		_refresh_loot()


func _open_inventory() -> void:
	_refresh_inventory()
	_inventory_panel.visible = true


func _refresh_inventory() -> void:
	for child in _inventory_list.get_children():
		child.queue_free()
	if _player == null:
		return
	for item_id in _player.inventory.keys():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var label := Label.new()
		var item_name: String = item_id
		if GFPickup.ITEM_INFO.has(item_id):
			item_name = String(GFPickup.ITEM_INFO[item_id]["name"])
		label.text = "%s: %d" % [item_name, int(_player.inventory[item_id])]
		row.add_child(label)
		if item_id == "medkit" or item_id == "shield_cell":
			var use_button := _make_button("Use", Vector2(90.0, 40.0))
			var id: String = item_id
			use_button.pressed.connect(func() -> void:
				if _player.use_item(id):
					toast("Used %s" % item_name)
					_refresh_inventory()
				else:
					toast("Cannot use %s now" % item_name))
			row.add_child(use_button)
		_inventory_list.add_child(row)
	# Loadout weapons with Equip buttons.
	var weapons_label := Label.new()
	weapons_label.text = "Weapons:"
	_inventory_list.add_child(weapons_label)
	for i in _player.loadout.size():
		var key: String = _player.loadout[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var label := Label.new()
		label.text = "%s%s" % [String(GFPlayer.WEAPONS[key]["name"]), " (equipped)" if i == _player.loadout_index else ""]
		row.add_child(label)
		var equip_button := _make_button("Equip", Vector2(90.0, 40.0))
		var index := i
		equip_button.pressed.connect(func() -> void:
			_player.equip_slot(index)
			_refresh_inventory())
		row.add_child(equip_button)
		_inventory_list.add_child(row)


func _on_health_changed(health: float, shield: float) -> void:
	_health_bar.value = health
	_shield_bar.value = shield
	_health_label.text = "HP %d / 100" % int(health)
	if health < 100.0:
		_flash.color = Color(1.0, 0.0, 0.0, 0.25)


func _on_ammo_changed(weapon_name: String, mag: int, reserve: int) -> void:
	_weapon_label.text = weapon_name
	_ammo_label.text = "%d / %d" % [mag, reserve]


func _on_weapon_changed(weapon_name: String) -> void:
	_weapon_label.text = weapon_name


func _on_inventory_changed(_inventory: Dictionary) -> void:
	if _inventory_panel.visible:
		_refresh_inventory()


func _on_prompt_changed(text: String) -> void:
	_prompt_label.text = text
	_interact_button.visible = text != "" and not _driving_mode


func _on_stage_changed(_index: int, text: String) -> void:
	_objective_label.text = text


func _on_interact_pressed() -> void:
	if _player != null:
		_player.try_interact()


func _on_pause_pressed() -> void:
	if _world != null and _world.has_method("toggle_pause"):
		_world.toggle_pause()


func _on_resume_pressed() -> void:
	if _world != null and _world.has_method("toggle_pause"):
		_world.toggle_pause()


func _show_settings() -> void:
	_pause_panel.visible = false
	_settings_panel.visible = true


func show_pause(show: bool) -> void:
	_pause_panel.visible = show
	if not show:
		_settings_panel.visible = false
		_inventory_panel.visible = false
		_loot_panel.visible = false
		_map_panel.visible = false


func show_game_over() -> void:
	_game_over_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func show_mission_complete() -> void:
	_complete_panel.visible = true


func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
