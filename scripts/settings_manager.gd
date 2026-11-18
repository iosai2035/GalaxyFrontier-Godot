## Galaxy Frontier — SettingsManager (autoload).
## Owns persistent settings (user://settings.cfg) and builds the
## InputMap actions at startup (so project.godot stays hand-editable).
## No audio settings: there are no audio assets in this build yet.
extends Node

const SETTINGS_PATH := "user://settings.cfg"

var sensitivity: float = 1.0
var quality: int = 1  # 0 Low, 1 Medium, 2 High
var invert_y: bool = false

const QUALITY_NAMES := ["Low", "Medium", "High"]


func _ready() -> void:
	_setup_input()
	load_settings()
	apply_quality()


func _setup_input() -> void:
	_add_key_action("move_forward", [KEY_W, KEY_UP])
	_add_key_action("move_back", [KEY_S, KEY_DOWN])
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("jump", [KEY_SPACE])
	_add_key_action("sprint", [KEY_SHIFT])
	_add_key_action("crouch", [KEY_C, KEY_CTRL])
	_add_key_action("reload", [KEY_R])
	_add_key_action("switch_weapon", [KEY_Q])
	_add_key_action("interact", [KEY_E])
	_add_key_action("pause", [KEY_ESCAPE, KEY_P])
	_add_mouse_action("fire", MOUSE_BUTTON_LEFT)
	_add_mouse_action("aim", MOUSE_BUTTON_RIGHT)


func _add_key_action(action_name: String, keys: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		if not _action_has_event(action_name, ev):
			InputMap.action_add_event(action_name, ev)


func _add_mouse_action(action_name: String, button: MouseButton) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	if not _action_has_event(action_name, ev):
		InputMap.action_add_event(action_name, ev)


func _action_has_event(action_name: String, ev: InputEvent) -> bool:
	for existing in InputMap.action_get_events(action_name):
		if existing.as_text() == ev.as_text():
			return true
	return false


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	sensitivity = clampf(float(cfg.get_value("controls", "sensitivity", 1.0)), 0.1, 3.0)
	quality = clampi(int(cfg.get_value("graphics", "quality", 1)), 0, 2)
	invert_y = bool(cfg.get_value("controls", "invert_y", false))


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("controls", "sensitivity", sensitivity)
	cfg.set_value("controls", "invert_y", invert_y)
	cfg.set_value("graphics", "quality", quality)
	cfg.save(SETTINGS_PATH)


func apply_quality() -> void:
	var vp := get_viewport()
	if vp == null:
		return
	match quality:
		0:
			vp.msaa_3d = Viewport.MSAA_DISABLED
			RenderingServer.set_default_clear_color(Color(0.05, 0.07, 0.12))
		1:
			vp.msaa_3d = Viewport.MSAA_2X
		2:
			vp.msaa_3d = Viewport.MSAA_4X
	for light in get_tree().get_nodes_in_group("sun_lights"):
		if light is DirectionalLight3D:
			light.shadow_enabled = quality > 0
