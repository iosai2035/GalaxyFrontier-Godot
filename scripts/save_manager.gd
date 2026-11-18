## Galaxy Frontier — SaveManager (autoload).
## Simple JSON save in user://savegame.json. Stores mission progress,
## player level / XP and the active planet. No passwords, no secrets.
extends Node

const SAVE_PATH := "user://savegame.json"
const SAVE_VERSION := 1


func default_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"mission_stage": 0,
		"mission_completed": false,
		"player_level": 1,
		"player_xp": 0,
		"active_planet": "ZERON",
		"enemies_defeated_total": 0,
		"starting_weapon": "rifle",
		"character_id": "vex",
		"body_type": "male",
		"suit_color": "#ff7a1a",
		"helmet": false,
	}


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game(data: Dictionary) -> bool:
	var copy := data.duplicate(true)
	copy["version"] = SAVE_VERSION
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: could not open save file for writing")
		return false
	file.store_string(JSON.stringify(copy))
	file.close()
	return true


func load_game() -> Dictionary:
	if not has_save():
		return default_data()
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("SaveManager: save file unreadable, using defaults")
		return default_data()
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SaveManager: save file corrupt, using defaults")
		return default_data()
	var data := default_data()
	for key in parsed:
		if data.has(key):
			data[key] = parsed[key]
	return data


func clear_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
