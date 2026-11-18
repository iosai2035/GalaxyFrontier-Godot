## Galaxy Frontier — Minimap (Control, drawn in code).
## Live top-down map of ZERON: player position + facing arrow,
## alive enemies (red dots), mission objective (pulsing marker),
## extraction/safe zone (green circle), points of interest
## (houses, pickups, weapons, vehicle, Power Core).
## World bounds are x,z in [-120, 120] (real scale, 240 m map).
## Redraws every 0.25 s — never every frame. The same control is
## reused for the small minimap and the full-screen map (bigger
## size, same code).
class_name GFMinimap
extends Control

const WORLD_HALF := 120.0

var player: GFPlayer = null
var mission: GFMissionManager = null
var world: Node = null
var pois: Array = []  # [{pos: Vector3, kind: String}]

var _redraw_timer: float = 0.0
var _pulse: float = 0.0


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(180.0, 180.0)


func bind(p_world: Node, p_player: GFPlayer, p_mission: GFMissionManager) -> void:
	world = p_world
	player = p_player
	mission = p_mission


func _process(delta: float) -> void:
	_redraw_timer += delta
	_pulse += delta
	if _redraw_timer >= 0.25:
		_redraw_timer = 0.0
		queue_redraw()


func _world_to_map(pos: Vector3) -> Vector2:
	var s := size
	var nx := (pos.x + WORLD_HALF) / (WORLD_HALF * 2.0)
	var nz := (pos.z + WORLD_HALF) / (WORLD_HALF * 2.0)
	return Vector2(nx * s.x, nz * s.y)


func _draw() -> void:
	var s := size
	draw_rect(Rect2(Vector2.ZERO, s), Color(0.02, 0.04, 0.1, 0.75))
	draw_rect(Rect2(Vector2.ZERO, s), Color(0.3, 0.9, 0.8, 0.8), false, 2.0)
	# Grid lines every 40 m.
	for i in range(1, 6):
		var f := float(i) / 6.0
		draw_line(Vector2(f * s.x, 0.0), Vector2(f * s.x, s.y), Color(1, 1, 1, 0.08), 1.0)
		draw_line(Vector2(0.0, f * s.y), Vector2(s.x, f * s.y), Color(1, 1, 1, 0.08), 1.0)
	# Safe zone = extraction zone circle.
	var extraction := Vector3(70.0, 0.0, 60.0)
	var ex := _world_to_map(extraction)
	var ex_r := 6.0 / (WORLD_HALF * 2.0) * s.x
	draw_arc(ex, ex_r, 0.0, TAU, 32, Color(0.2, 1.0, 0.4, 0.9), 2.0)
	draw_circle(ex, ex_r, Color(0.2, 1.0, 0.4, 0.08))
	# Points of interest, colored by kind.
	var poi_colors := {
		"house": Color(0.4, 0.8, 1.0),
		"pickup": Color(0.3, 1.0, 0.4),
		"weapon": Color(1.0, 0.85, 0.2),
		"vehicle": Color(1.0, 0.55, 0.1),
	}
	for poi in pois:
		var p: Vector2 = _world_to_map(poi["pos"])
		var color: Color = poi_colors.get(String(poi.get("kind", "")), Color(1, 1, 1))
		draw_circle(p, maxf(3.0, s.x * 0.012), color)
	# Mission objective marker (pulsing).
	if mission != null and not mission.completed:
		var target: Vector3 = mission.current_target_position()
		if target != Vector3.ZERO:
			var tp := _world_to_map(target)
			var pr := maxf(5.0, s.x * 0.02) * (1.0 + 0.25 * sin(_pulse * 4.0))
			draw_arc(tp, pr, 0.0, TAU, 24, Color(1.0, 0.85, 0.1, 1.0), 2.5)
			draw_circle(tp, maxf(3.0, s.x * 0.008), Color(1.0, 0.85, 0.1))
	# Enemies (alive only).
	for node in get_tree().get_nodes_in_group("enemies"):
		if node is GFEnemy and (node as GFEnemy).state != GFEnemy.State.DEAD:
			var ep: Vector2 = _world_to_map((node as Node3D).global_position)
			draw_circle(ep, maxf(3.0, s.x * 0.011), Color(1.0, 0.2, 0.15))
	# Player arrow.
	if player != null and is_instance_valid(player):
		var pp := _world_to_map(player.global_position)
		var yaw: float = player.yaw
		var fwd := Vector2(-sin(yaw), -cos(yaw))
		var perp := Vector2(-fwd.y, fwd.x)
		var r := maxf(7.0, s.x * 0.035)
		var tip := pp + fwd * r
		var left := pp - fwd * r * 0.7 + perp * r * 0.6
		var right := pp - fwd * r * 0.7 - perp * r * 0.6
		draw_colored_polygon(PackedVector2Array([tip, left, right]), Color(0.25, 0.9, 0.75))
		draw_arc(pp, r * 1.15, 0.0, TAU, 24, Color(1, 1, 1, 0.6), 1.5)
