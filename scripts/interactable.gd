## Galaxy Frontier — Interactable (Area3D).
## Doors, crates, terminals, the Power Core and pickups.
## The world connects to `interacted` and decides the effect.
class_name GFInteractable
extends Area3D

signal interacted(interactable: GFInteractable)

@export var interact_id: String = ""
@export var prompt: String = "Interact"
@export var action: String = "generic"
@export var usable: bool = true


func _ready() -> void:
	add_to_group("interactables")
	collision_layer = 0
	collision_mask = 0
	monitoring = true
	monitorable = false
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 2.5
	shape.shape = sphere
	add_child(shape)


func is_usable() -> bool:
	return usable


func get_prompt() -> String:
	return prompt


func interact(_player: Node3D) -> void:
	if not usable:
		return
	interacted.emit(self)


func set_used() -> void:
	usable = false
