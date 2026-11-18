## Galaxy Frontier — Main menu (PUBG-style, built in code).
## Sections: Play / Character / Weapons / Missions / Settings /
## Shop (spec only — no real purchases). Every section is
## navigable to and back from, every option works for real or is
## honestly labelled NOT IMPLEMENTED — no decorative sections.
## Responsive: anchors + containers, viewport-fraction sizes,
## Safe Areas on every screen. Character choice (4 profiles),
## suit colors, helmet and body type are saved and applied to the
## player in the world; the starting weapon choice is saved too.
class_name GFMainMenu
extends Control

var _sections: Dictionary = {}
var _menu_box: VBoxContainer
var _content_title: Label
var _content_box: VBoxContainer
var _status_label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	_show_section("home")


func _safe_margins() -> Dictionary:
	var vp := get_viewport().get_visible_rect().size
	var safe := DisplayServer.get_display_safe_area()
	return {
		"left": maxf(0.0, safe.position.x),
		"top": maxf(0.0, safe.position.y),
		"right": maxf(0.0, vp.x - safe.end.x),
		"bottom": maxf(0.0, vp.y - safe.end.y),
	}


func _make_button(text: String, min_size: Vector2 = Vector2(260.0, 52.0)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 18)
	return b


func _build() -> void:
	var m := _safe_margins()
	# Background panel.
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var root := HBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = m["left"] + 16.0
	root.offset_top = m["top"] + 16.0
	root.offset_right = -m["right"] - 16.0
	root.offset_bottom = -m["bottom"] - 16.0
	root.add_theme_constant_override("separation", 24)
	add_child(root)
	# Left: title + navigation.
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 10)
	left.custom_minimum_size = Vector2(300.0, 0.0)
	root.add_child(left)
	var title := Label.new()
	title.text = "GALAXY\nFRONTIER"
	title.add_theme_font_size_override("font_size", 44)
	left.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Planet ZERON — The Lost Power Core"
	subtitle.add_theme_font_size_override("font_size", 16)
	left.add_child(subtitle)
	_menu_box = VBoxContainer.new()
	_menu_box.add_theme_constant_override("separation", 8)
	left.add_child(_menu_box)
	var nav := [
		["PLAY", "play"],
		["CHARACTER", "character"],
		["WEAPONS", "weapons"],
		["MISSIONS", "missions"],
		["SETTINGS", "settings"],
		["SHOP (Spec)", "shop"],
	]
	for item in nav:
		var b := _make_button(item[0])
		var section := String(item[1])
		b.pressed.connect(func() -> void: _on_nav(section))
		_menu_box.add_child(b)
	_status_label = Label.new()
	_status_label.text = ""
	left.add_child(_status_label)
	# Right: content area.
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 10)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(right)
	_content_title = Label.new()
	_content_title.text = ""
	_content_title.add_theme_font_size_override("font_size", 28)
	right.add_child(_content_title)
	_content_box = VBoxContainer.new()
	_content_box.add_theme_constant_override("separation", 8)
	_content_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(_content_box)


func _on_nav(section: String) -> void:
	SoundManager.play_click()
	if section == "play":
		get_tree().change_scene_to_file("res://scenes/world.tscn")
		return
	_show_section(section)


func _clear_content() -> void:
	for child in _content_box.get_children():
		child.queue_free()
	_sections.clear()


func _add_back() -> void:
	var back := _make_button("← Back", Vector2(200.0, 48.0))
	back.pressed.connect(func() -> void: _show_section("home"))
	_content_box.add_child(back)


func _show_section(section: String) -> void:
	_clear_content()
	_menu_box.visible = section == "home"
	if section == "home":
		_content_title.text = "Welcome, Frontier Ranger"
		var save := SaveManager.load_game()
		var label := Label.new()
		label.text = "Mission progress: stage %d / 8%s\nEnemies defeated: %d\nLevel %d — %d XP" % [
			int(save.get("mission_stage", 0)),
			" (completed)" if bool(save.get("mission_completed", false)) else "",
			int(save.get("enemies_defeated_total", 0)),
			int(save.get("player_level", 1)),
			int(save.get("player_xp", 0)),
		]
		_content_box.add_child(label)
		var play := _make_button("▶ PLAY — The Lost Power Core")
		play.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/world.tscn"))
		_content_box.add_child(play)
		var reset := _make_button("Reset Progress", Vector2(200.0, 44.0))
		reset.pressed.connect(func() -> void:
			SaveManager.clear_save()
			_show_section("home")
			_status_label.text = "Progress reset.")
		_content_box.add_child(reset)
		return
	match section:
		"character":
			_build_character()
		"weapons":
			_build_weapons()
		"missions":
			_build_missions()
		"settings":
			_build_settings()
		"shop":
			_build_shop()


func _select_character(profile_id: String) -> void:
	var profile: Dictionary = GFGameData.CHARACTER_PROFILES.get(profile_id, {})
	if profile.is_empty():
		return
	var data := SaveManager.load_game()
	data["character_id"] = profile_id
	data["suit_color"] = String(profile["suit_color"])
	data["helmet"] = bool(profile["helmet"])
	data["body_type"] = "female" if profile_id == "luna" else "male"
	data["starting_weapon"] = String(profile["weapon"])
	SaveManager.save_game(data)
	_status_label.text = "Character: %s (%s) — starts with %s" % [
		String(profile["name"]), String(profile["role"]),
		String(GFPlayer.WEAPONS[String(profile["weapon"])]["name"])]
	_show_section("character")


func _build_character() -> void:
	_content_title.text = "CHARACTER"
	var save := SaveManager.load_game()
	var current := String(save.get("character_id", "vex"))
	var desc := Label.new()
	desc.text = "Choose your ranger. Each has a distinct look and starting weapon.\nAll original designs — no copies, no real-person likeness."
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content_box.add_child(desc)
	for profile_id in GFGameData.CHARACTER_PROFILES.keys():
		var profile: Dictionary = GFGameData.CHARACTER_PROFILES[profile_id]
		var b := _make_button("%s — %s (starts: %s)%s" % [
			String(profile["name"]), String(profile["role"]),
			String(GFPlayer.WEAPONS[String(profile["weapon"])]["name"]),
			"  ✓" if profile_id == current else "",
		], Vector2(420.0, 48.0))
		var id: String = profile_id
		b.pressed.connect(func() -> void: _select_character(id))
		_content_box.add_child(b)
	# Suit color swatches (free customization, applies on top).
	var colors_label := Label.new()
	colors_label.text = "Suit color:"
	_content_box.add_child(colors_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_content_box.add_child(row)
	for hex in ["#2673d9", "#2ec8f0", "#4caf50", "#ff7a1a", "#9d7fd6", "#e0e0e0", "#222222"]:
		var sw := _make_button("■", Vector2(52.0, 44.0))
		sw.add_theme_color_override("font_color", Color.html(hex))
		var h: String = hex
		sw.pressed.connect(func() -> void:
			var data := SaveManager.load_game()
			data["suit_color"] = h
			SaveManager.save_game(data)
			_status_label.text = "Suit color set to %s" % h)
		row.add_child(sw)
	var helmet_check := CheckButton.new()
	helmet_check.text = "Helmet"
	helmet_check.button_pressed = bool(save.get("helmet", false))
	helmet_check.toggled.connect(func(on: bool) -> void:
		var data := SaveManager.load_game()
		data["helmet"] = on
		SaveManager.save_game(data))
	_content_box.add_child(helmet_check)
	_add_back()


func _build_weapons() -> void:
	_content_title.text = "WEAPONS"
	var save := SaveManager.load_game()
	var current := String(save.get("starting_weapon", "rifle"))
	var desc := Label.new()
	desc.text = "Full arsenal — pick your starting weapon. The rest are found in the world (weapon pickups, loot boxes)."
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content_box.add_child(desc)
	for key in GFPlayer.WEAPONS.keys():
		var w: Dictionary = GFPlayer.WEAPONS[key]
		var b := _make_button("%s — %d dmg, %.1f/s, mag %d, range %d m, reload %.1fs, %s%s" % [
			String(w["name"]), int(w["damage"]), 1.0 / float(w["fire_interval"]),
			int(w["mag_size"]), int(w["range"]), float(w["reload_time"]),
			String(w["scope"]), "  ✓" if key == current else "",
		], Vector2(560.0, 48.0))
		var k: String = key
		b.pressed.connect(func() -> void:
			var data := SaveManager.load_game()
			data["starting_weapon"] = k
			SaveManager.save_game(data)
			_status_label.text = "Starting weapon: %s" % String(GFPlayer.WEAPONS[k]["name"])
			_show_section("weapons"))
		_content_box.add_child(b)
	_add_back()


func _build_missions() -> void:
	_content_title.text = "MISSIONS"
	var save := SaveManager.load_game()
	var stage := int(save.get("mission_stage", 0))
	var label := Label.new()
	label.text = "The Lost Power Core — stage %d / 8%s" % [stage, " (completed)" if bool(save.get("mission_completed", false)) else ""]
	_content_box.add_child(label)
	var play := _make_button("▶ Play this mission")
	play.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/world.tscn"))
	_content_box.add_child(play)
	for future in ["Signal in the Static (Planet NEXUS)", "The Frozen Vault (Planet VELTRON)"]:
		var row := Label.new()
		row.text = "%s — NOT IMPLEMENTED (later phase)" % future
		_content_box.add_child(row)
	_add_back()


func _build_settings() -> void:
	_content_title.text = "SETTINGS"
	var sens_label := Label.new()
	sens_label.text = "Camera sensitivity"
	_content_box.add_child(sens_label)
	var sens_slider := HSlider.new()
	sens_slider.min_value = 0.1
	sens_slider.max_value = 3.0
	sens_slider.step = 0.1
	sens_slider.value = SettingsManager.sensitivity
	sens_slider.custom_minimum_size = Vector2(300.0, 24.0)
	sens_slider.value_changed.connect(func(v: float) -> void:
		SettingsManager.sensitivity = v
		SettingsManager.save_settings())
	_content_box.add_child(sens_slider)
	var quality_label := Label.new()
	quality_label.text = "Graphics quality"
	_content_box.add_child(quality_label)
	var quality_option := OptionButton.new()
	for q in SettingsManager.QUALITY_NAMES:
		quality_option.add_item(q)
	quality_option.selected = SettingsManager.quality
	quality_option.custom_minimum_size = Vector2(300.0, 40.0)
	quality_option.item_selected.connect(func(index: int) -> void:
		SettingsManager.quality = index
		SettingsManager.save_settings()
		SettingsManager.apply_quality())
	_content_box.add_child(quality_option)
	var invert_check := CheckButton.new()
	invert_check.text = "Invert camera Y"
	invert_check.button_pressed = SettingsManager.invert_y
	invert_check.toggled.connect(func(on: bool) -> void:
		SettingsManager.invert_y = on
		SettingsManager.save_settings())
	_content_box.add_child(invert_check)
	_add_back()


func _build_shop() -> void:
	_content_title.text = "COSMETIC SHOP — SPEC ONLY"
	var note := Label.new()
	note.text = "Design spec only — no real purchases in this build. Suit colors are free in the Character section."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content_box.add_child(note)
	for item in [
		"Golden Ranger Suit — SPEC (not for sale)",
		"Shadow Helmet — SPEC (not for sale)",
		"Neon Visor — SPEC (not for sale)",
		"Rover RX-7 Racing Paint — SPEC (not for sale)",
	]:
		var row := Label.new()
		row.text = item
		_content_box.add_child(row)
	_add_back()
