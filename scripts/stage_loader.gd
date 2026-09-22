class_name StageLoader
extends RefCounted

static func read_json(path: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert(parsed is Dictionary, "Invalid stage/settings JSON: " + path)
	return parsed

static func load_stage(index: int) -> Dictionary:
	var path := "res://data/tutorial.json" if index == 0 else "res://data/stage_%02d.json" % index
	return compile(read_json(path))

static func compile(data: Dictionary) -> Dictionary:
	var spb := 60.0 / float(data.bpm)
	var cursor := 4.0
	var rounds: Array = []
	for source in data.rounds:
		var count := float(source.length)
		var intro := 4.0 if source.get("final", false) else 0.0
		cursor += intro
		var item := {"demo_start": cursor * spb, "answer_start": (cursor + count + 2.0) * spb,
			"end": (cursor + count * 2.0 + 3.5) * spb, "length": count,
			"final": source.get("final", false), "notes": [], "rests": source.get("rests", [])}
		for note in source.beats:
			item.notes.append({"beat": float(note.beat), "channel": int(note.channel),
				"demo_time": item.demo_start + float(note.beat) * spb,
				"target_time": item.answer_start + float(note.beat) * spb})
		rounds.append(item)
		cursor += count * 2.0 + 3.5
	data["timeline"] = rounds
	data["duration"] = cursor * spb + 0.6
	data["seconds_per_beat"] = spb
	return data
