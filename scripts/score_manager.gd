class_name ScoreManager
extends RefCounted

var settings: Dictionary
var score := 0
var combo := 0
var best_combo := 0
var misses := 0
var task := 40.0
var counts := {"PERFECT": 0, "GOOD": 0, "OK": 0, "MISS": 0}

func _init(config: Dictionary) -> void:
	settings = config
	task = float(config.initial_task)

func grade(error_seconds: float) -> String:
	var error := absf(error_seconds)
	if error <= float(settings.PERFECT_WINDOW) + 0.000001: return "PERFECT"
	if error <= float(settings.GOOD_WINDOW) + 0.000001: return "GOOD"
	if error <= float(settings.OK_WINDOW) + 0.000001: return "OK"
	return "MISS"

func apply(grade_name: String) -> void:
	counts[grade_name] += 1
	if grade_name == "MISS":
		misses += 1
		combo = 0
		task = maxf(0.0, task - float(settings.miss_loss))
	else:
		score += {"PERFECT": 100, "GOOD": 70, "OK": 40}[grade_name]
		combo += 1
		best_combo = maxi(best_combo, combo)
		task = minf(100.0, task + float(settings.success_gain))

func cleared() -> bool:
	return task >= float(settings.clear_task) and misses < int(settings.miss_limit)
