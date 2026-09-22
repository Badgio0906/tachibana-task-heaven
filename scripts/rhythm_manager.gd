class_name RhythmManager
extends RefCounted

signal judged(channel: int, grade_name: String, delta_ms: float, omitted: bool)
var notes: Array = []
var resolved: Dictionary = {}
var scoring: ScoreManager
var active := false
var offset_seconds := 0.0

func _init(score_state: ScoreManager) -> void:
	scoring = score_state

func begin(round_notes: Array) -> void:
	notes = round_notes
	resolved.clear()
	active = true

func expire(now: float) -> void:
	if not active: return
	for i in range(notes.size()):
		if not resolved.has(i) and now - offset_seconds > float(notes[i].target_time) + float(scoring.settings.OK_WINDOW):
			resolve(i, int(notes[i].channel), "MISS", 0.0, true)

func submit_task(channel: int, now: float) -> void:
	if not active: return
	now -= offset_seconds
	expire(now + offset_seconds)
	var closest := -1
	var distance := INF
	for i in range(notes.size()):
		if resolved.has(i): continue
		var d := absf(now - float(notes[i].target_time))
		if d < distance:
			distance = d
			closest = i
	# Extra taps, including rests, count as misses; they never consume distant notes.
	if closest < 0 or distance > float(scoring.settings.OK_WINDOW):
		scoring.apply("MISS")
		judged.emit(channel, "MISS", 0.0, false)
		return
	var delta := now - float(notes[closest].target_time)
	var grade_name := scoring.grade(delta) if channel == int(notes[closest].channel) else "MISS"
	resolve(closest, channel, grade_name, delta * 1000.0, false)

func resolve(index: int, channel: int, grade_name: String, delta: float, omitted: bool) -> void:
	resolved[index] = grade_name
	scoring.apply(grade_name)
	judged.emit(channel, grade_name, delta, omitted)
