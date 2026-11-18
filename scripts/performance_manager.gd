## Galaxy Frontier — PerformanceManager.
## Budgets (documented in Docs/PERFORMANCE.md):
##   target 60 FPS, draw calls <= 150, primitives <= 500k,
##   video memory <= 512 MB.
## Samples once every 0.5 s (no per-frame polling). If FPS stays
## below 50 for 5 s, auto-quality steps down one tier (with a 10 s
## cooldown); if FPS stays above 58 for 15 s it steps back up, never
## above the user's saved quality, and never writes to disk.
class_name GFPerformanceManager
extends Node

const TARGET_FPS := 60.0
const LOW_FPS := 50.0
const HIGH_FPS := 58.0
const MAX_DRAW_CALLS := 150
const MAX_PRIMITIVES := 500000
const MAX_VIDEO_MEM_MB := 512

const SAMPLE_INTERVAL := 0.5
const LOW_TIME_TO_STEP_DOWN := 5.0
const HIGH_TIME_TO_STEP_UP := 15.0
const STEP_COOLDOWN := 10.0

var fps: float = 0.0
var draw_calls: int = 0
var primitives: int = 0
var video_mem_mb: float = 0.0
var auto_quality: int = -1  # -1 = following the user setting
var over_budget: bool = false

var _sample_timer: float = 0.0
var _low_time: float = 0.0
var _high_time: float = 0.0
var _cooldown: float = 0.0
var _user_quality: int = 1


func _ready() -> void:
	add_to_group("perf")
	_user_quality = SettingsManager.quality
	auto_quality = _user_quality


func _process(delta: float) -> void:
	_sample_timer += delta
	_cooldown = maxf(0.0, _cooldown - delta)
	if _sample_timer < SAMPLE_INTERVAL:
		return
	_sample_timer = 0.0
	fps = float(Engine.get_frames_per_second())
	draw_calls = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	primitives = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	video_mem_mb = float(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED)) / 1048576.0
	over_budget = draw_calls > MAX_DRAW_CALLS or primitives > MAX_PRIMITIVES or video_mem_mb > MAX_VIDEO_MEM_MB
	_auto_quality(delta)


func _auto_quality(_delta: float) -> void:
	if fps < LOW_FPS:
		_low_time += SAMPLE_INTERVAL
		_high_time = 0.0
	elif fps > HIGH_FPS:
		_high_time += SAMPLE_INTERVAL
		_low_time = 0.0
	else:
		_low_time = 0.0
		_high_time = 0.0
	if _cooldown > 0.0:
		return
	if _low_time >= LOW_TIME_TO_STEP_DOWN and auto_quality > 0:
		auto_quality -= 1
		_low_time = 0.0
		_cooldown = STEP_COOLDOWN
		_apply_auto_quality()
	elif _high_time >= HIGH_TIME_TO_STEP_UP and auto_quality < _user_quality:
		auto_quality += 1
		_high_time = 0.0
		_cooldown = STEP_COOLDOWN
		_apply_auto_quality()


func _apply_auto_quality() -> void:
	# In-memory only: the user's saved quality on disk is untouched.
	SettingsManager.quality = auto_quality
	SettingsManager.apply_quality()


func stats_text() -> String:
	return "%d FPS | %d draws | %d tris | %d MB" % [
		int(fps), draw_calls, primitives, int(video_mem_mb)]
