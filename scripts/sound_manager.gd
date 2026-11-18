## Galaxy Frontier — SoundManager (autoload).
## All sounds are synthesized in code (AudioStreamWAV, 8-bit,
## 22050 Hz) — no audio files, no downloads. Short blips only:
## door slide, pickup chime, UI click. If synthesis ever fails the
## game simply stays silent; nothing here can crash the game.
extends Node

var _door_stream: AudioStreamWAV = null
var _pickup_stream: AudioStreamWAV = null
var _click_stream: AudioStreamWAV = null
var _players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	_door_stream = _make_sweep(300.0, 620.0, 0.25)
	_pickup_stream = _make_sweep(660.0, 990.0, 0.16)
	_click_stream = _make_sweep(500.0, 500.0, 0.06)
	for i in 4:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)


func _make_sweep(freq_from: float, freq_to: float, duration: float) -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * duration)
	var data := PackedByteArray()
	data.resize(count)
	var phase := 0.0
	for i in count:
		var t := float(i) / float(count)
		var freq := lerpf(freq_from, freq_to, t)
		phase += TAU * freq / float(rate)
		var envelope := 1.0 - t
		var sample := int(127.0 + 110.0 * sin(phase) * envelope)
		data[i] = clampi(sample, 0, 255)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = rate
	stream.data = data
	return stream


func _play(stream: AudioStreamWAV) -> void:
	if stream == null:
		return
	for p in _players:
		if not p.playing:
			p.stream = stream
			p.play()
			return


func play_door() -> void:
	_play(_door_stream)


func play_pickup() -> void:
	_play(_pickup_stream)


func play_click() -> void:
	_play(_click_stream)
