## Galaxy Frontier — ZoneArea (Area3D).
## Landing zone, outpost, building interior, extraction zone.
## Emits zone_entered once per player entry.
class_name GFZoneArea
extends Area3D

signal zone_entered(zone_id: String)

@export var zone_id: String = ""
var _triggered := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 4
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if _triggered:
		return
	if body.is_in_group("player"):
		_triggered = true
		zone_entered.emit(zone_id)


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_triggered = false


func reset_trigger() -> void:
	_triggered = false
