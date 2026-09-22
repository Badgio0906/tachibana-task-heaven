class_name TaskAudioManager
extends Node

var music: AudioStreamPlayer
var effects: Array[AudioStreamPlayer] = []
var streams: Dictionary = {}
var effect_index := 0
var started_usec := 0
var latency := 0.0
var last_clock := -1.0
var is_web := OS.has_feature("web")

func _ready() -> void:
	music = AudioStreamPlayer.new()
	add_child(music)
	for i in range(12):
		var player := AudioStreamPlayer.new()
		add_child(player)
		effects.append(player)
	for name in ["tutorial", "stage_01", "stage_02", "stage_03", "tambourine", "triangle", "cymbal", "kick", "error", "omit", "clear", "fail", "wind"]:
		streams[name] = load("res://assets/audio/" + name + ".wav")

func unlock() -> void:
	if is_web: JavaScriptBridge.eval("window.TaskAudio.init()", true)

func ready_to_play() -> bool:
	return not is_web or bool(JavaScriptBridge.eval("!!window.TaskAudio.ready", true))

func start_track(index: int) -> void:
	var name := "tutorial" if index == 0 else "stage_%02d" % index
	last_clock = -1.0
	if is_web:
		JavaScriptBridge.eval("window.TaskAudio.start('%s')" % name, true)
	else:
		music.stream_paused = false
		music.stream = streams[name]
		latency = AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
		started_usec = Time.get_ticks_usec()
		music.play()

func clock_seconds() -> float:
	var value: float
	if is_web:
		value = float(JavaScriptBridge.eval("window.TaskAudio.clock()", true))
	else:
		value = (Time.get_ticks_usec() - started_usec) / 1000000.0 - latency
	last_clock = maxf(last_clock, value)
	return last_clock

func stop() -> void:
	music.stop()
	if is_web: JavaScriptBridge.eval("window.TaskAudio.stop()", true)

func play_effect(name: String) -> void:
	if is_web:
		JavaScriptBridge.eval("window.TaskAudio.play('%s')" % name, true)
	else:
		var player := effects[effect_index % effects.size()]
		effect_index += 1
		player.stream = streams[name]
		player.play()

func task_sound(channel: int) -> void:
	play_effect(["tambourine", "triangle", "cymbal", "kick"][channel - 1])

func set_volume(value: float) -> void:
	if is_web: JavaScriptBridge.eval("window.TaskAudio.volume(%f)" % value, true)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(value, .001)))
