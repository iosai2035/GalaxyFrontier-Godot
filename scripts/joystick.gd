## Galaxy Frontier — Virtual joystick (Control).
## Draws its own base + knob. Emits `moved` with a Vector2 where
## up (forward) is (0, -1), matching the keyboard move axis.
class_name GFJoystick
extends Control

signal moved(value: Vector2)

const BASE_RADIUS := 90.0
const KNOB_RADIUS := 38.0

var value: Vector2 = Vector2.ZERO
var _touch_id: int = -1
var _center: Vector2 = Vector2.ZERO


func _radius() -> float:
	# Radius follows the control size, so the joystick scales with
	# the viewport instead of staying a fixed 90 px.
	return maxf(40.0, minf(size.x, size.y) / 2.0 - 10.0)


func _ready() -> void:
	custom_minimum_size = Vector2(BASE_RADIUS * 2.0 + 20.0, BASE_RADIUS * 2.0 + 20.0)
	_center = size / 2.0
	resized.connect(func() -> void: _center = size / 2.0)
	mouse_filter = MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_id == -1:
			_touch_id = event.index
			_update_value(event.position)
		elif not event.pressed and event.index == _touch_id:
			_touch_id = -1
			_set_value(Vector2.ZERO)
	elif event is InputEventScreenDrag:
		if event.index == _touch_id:
			_update_value(event.position)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_touch_id = -2
				_update_value(event.position)
			elif _touch_id == -2:
				_touch_id = -1
				_set_value(Vector2.ZERO)
	elif event is InputEventMouseMotion:
		if _touch_id == -2:
			_update_value(event.position)


func _update_value(pos: Vector2) -> void:
	var offset: Vector2 = pos - _center
	var radius := _radius()
	if offset.length() > radius:
		offset = offset.normalized() * radius
	_set_value(offset / radius)


func _set_value(v: Vector2) -> void:
	value = v
	moved.emit(v)
	queue_redraw()


func _draw() -> void:
	var radius := _radius()
	var knob := minf(KNOB_RADIUS, radius * 0.42)
	var base_color := Color(1.0, 1.0, 1.0, 0.12)
	var ring_color := Color(1.0, 1.0, 1.0, 0.35)
	var knob_color := Color(0.25, 0.85, 0.75, 0.55)
	draw_circle(_center, radius, base_color)
	draw_arc(_center, radius, 0.0, TAU, 48, ring_color, 3.0)
	draw_circle(_center + value * (radius - knob), knob, knob_color)
