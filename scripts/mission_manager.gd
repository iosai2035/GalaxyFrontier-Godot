## Galaxy Frontier — MissionManager.
## "The Lost Power Core" (simplified, 8 stages, strict order).
## The world feeds it events: zone entries, interactions, enemy deaths.
## Progress is saved through SaveManager on every stage advance.
class_name GFMissionManager
extends Node

signal stage_changed(index: int, text: String)
signal mission_completed

const STAGES := [
	{"id": "land", "text": "Land on ZERON — reach the landing zone", "type": "zone", "target": "landing"},
	{"id": "reach_outpost", "text": "Reach the outpost", "type": "zone", "target": "outpost"},
	{"id": "enter_building", "text": "Enter the station building", "type": "zone", "target": "building"},
	{"id": "find_core", "text": "Find the Power Core", "type": "interact", "target": "power_core"},
	{"id": "activate_core", "text": "Activate the Power Core at the terminal", "type": "interact", "target": "terminal"},
	{"id": "defeat_enemies", "text": "Defeat the hostiles (0/3)", "type": "defeat", "target": "3"},
	{"id": "reach_extraction", "text": "Reach the extraction zone", "type": "zone", "target": "extraction"},
	{"id": "complete", "text": "Mission complete", "type": "auto", "target": ""},
]

var current_stage: int = 0
var defeated_count: int = 0
var completed: bool = false
# World positions for each stage target, set by the world
# (landing, outpost, building, power_core, terminal, defeat,
# extraction). Used by the minimap objective marker.
var targets: Dictionary = {}


func set_targets(t: Dictionary) -> void:
	targets = t.duplicate()


func current_target_position() -> Vector3:
	if completed:
		return Vector3.ZERO
	var stage: Dictionary = STAGES[current_stage]
	var key := String(stage["target"])
	if stage["type"] == "defeat":
		return targets.get("defeat", Vector3.ZERO)
	if targets.has(key):
		return targets[key]
	return Vector3.ZERO


func start_from_save(data: Dictionary) -> void:
	current_stage = clampi(int(data.get("mission_stage", 0)), 0, STAGES.size() - 1)
	completed = bool(data.get("mission_completed", false))
	if completed:
		current_stage = STAGES.size() - 1
	_emit_stage()


func current_text() -> String:
	if completed:
		return "Mission complete — The Lost Power Core"
	var stage: Dictionary = STAGES[current_stage]
	if stage["type"] == "defeat":
		return "Defeat the hostiles (%d/%d)" % [defeated_count, int(stage["target"])]
	return String(stage["text"])


func on_zone_entered(zone_id: String) -> void:
	if completed:
		return
	var stage: Dictionary = STAGES[current_stage]
	if stage["type"] == "zone" and stage["target"] == zone_id:
		_advance()


func on_interacted(interactable: GFInteractable) -> void:
	if completed:
		return
	var stage: Dictionary = STAGES[current_stage]
	if stage["type"] == "interact" and stage["target"] == interactable.interact_id:
		_advance()


func on_enemy_defeated() -> void:
	if completed:
		return
	var stage: Dictionary = STAGES[current_stage]
	if stage["type"] != "defeat":
		return
	defeated_count += 1
	if defeated_count >= int(stage["target"]):
		_advance()
	else:
		_emit_stage()


func _advance() -> void:
	current_stage += 1
	if current_stage >= STAGES.size() - 1:
		completed = true
		_save_progress()
		mission_completed.emit()
		_emit_stage()
		return
	_save_progress()
	_emit_stage()


func _emit_stage() -> void:
	stage_changed.emit(current_stage, current_text())


func _save_progress() -> void:
	var data := SaveManager.load_game()
	data["mission_stage"] = current_stage
	data["mission_completed"] = completed
	SaveManager.save_game(data)
