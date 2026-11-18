## Galaxy Frontier — Crosshair (Control, drawn in code).
## Center-screen crosshair. The gap widens with spread and movement
## and tightens while aiming. With a magnified scope (sniper 8x,
## energy 4x) a scope overlay is drawn instead: darkened edges
## around a circle with cross lines. Iron sights show the plain
## crosshair only.
class_name GFCrosshair
extends Control

var gap: float = 10.0
var aiming: bool = false
var scope: String = "iron"


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func update_state(state: Dictionary) -> void:
	gap = float(state.get("gap", 10.0))
	aiming = bool(state.get("aiming", false))
	scope = String(state.get("scope", "iron"))
	queue_redraw()


func _draw() -> void:
	var c := size / 2.0
	if scope == "scope_8x" and aiming:
		_draw_scope(c, minf(size.x, size.y) * 0.32)
	elif scope == "scope_4x" and aiming:
		_draw_scope(c, minf(size.x, size.y) * 0.42)
	_draw_cross(c)


func _draw_scope(c: Vector2, r: float) -> void:
	var shade := Color(0.0, 0.0, 0.0, 0.82)
	draw_rect(Rect2(0, 0, size.x, c.y - r), shade)
	draw_rect(Rect2(0, c.y + r, size.x, size.y - (c.y + r)), shade)
	draw_rect(Rect2(0, c.y - r, c.x - r, r * 2.0), shade)
	draw_rect(Rect2(c.x + r, c.y - r, size.x - (c.x + r), r * 2.0), shade)
	draw_arc(c, r, 0.0, TAU, 64, Color(0.1, 0.1, 0.1, 1.0), 6.0)
	draw_arc(c, r, 0.0, TAU, 64, Color(1, 1, 1, 0.7), 2.0)
	draw_line(Vector2(c.x - r, c.y), Vector2(c.x + r, c.y), Color(1, 1, 1, 0.8), 1.5)
	draw_line(Vector2(c.x, c.y - r), Vector2(c.x, c.y + r), Color(1, 1, 1, 0.8), 1.5)


func _draw_cross(c: Vector2) -> void:
	var color := Color(1.0, 1.0, 1.0, 0.9) if not aiming else Color(0.4, 1.0, 0.8, 0.95)
	var len := 9.0
	var g := gap
	draw_line(Vector2(c.x - g - len, c.y), Vector2(c.x - g, c.y), color, 2.0)
	draw_line(Vector2(c.x + g, c.y), Vector2(c.x + g + len, c.y), color, 2.0)
	draw_line(Vector2(c.x, c.y - g - len), Vector2(c.x, c.y - g), color, 2.0)
	draw_line(Vector2(c.x, c.y + g), Vector2(c.x, c.y + g + len), color, 2.0)
	draw_circle(c, 1.5, color)
