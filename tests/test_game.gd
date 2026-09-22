extends SceneTree

const Loader = preload("res://scripts/stage_loader.gd")
const Score = preload("res://scripts/score_manager.gd")
const Rhythm = preload("res://scripts/rhythm_manager.gd")
var checks := 0
var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		printerr("FAIL: " + message)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var settings := Loader.read_json("res://data/settings.json")
	var score := Score.new(settings)
	for pair in [[0.0,"PERFECT"],[.09,"PERFECT"],[-.09,"PERFECT"],[.091,"GOOD"],[.18,"GOOD"],[.181,"OK"],[.28,"OK"],[.281,"MISS"]]:
		check(score.grade(pair[0]) == pair[1], "judgment boundary %s" % str(pair))
	var rhythm := Rhythm.new(score)
	rhythm.begin([{"target_time": 1.0, "channel": 1}, {"target_time": 1.5, "channel": 2}])
	rhythm.submit_task(1, 1.0)
	rhythm.submit_task(1, 1.0)
	check(score.score == 100 and score.misses == 1, "duplicate input cannot score twice")
	rhythm.submit_task(3, 1.5)
	check(score.misses == 2 and rhythm.resolved.size() == 2, "wrong channel consumes one matching-time note")
	rhythm.expire(3)
	check(score.misses == 2, "resolved notes cannot be missed twice")
	rhythm.begin([{"target_time": 4.0, "channel": 4}])
	rhythm.expire(4.281)
	check(score.misses == 3, "omission is automatically missed")
	rhythm.begin([{"target_time": 5.0, "channel": 1}])
	rhythm.offset_seconds = .1
	rhythm.submit_task(1, 5.1)
	check(score.counts.PERFECT == 2, "positive input latency compensation")
	score.task = 70
	check(score.cleared(), "70 percent clear boundary")
	score.task = 69.9
	check(not score.cleared(), "below 70 fails")
	var game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.test_mode = true
	for action in ["task_1", "task_2", "task_3", "task_4"]:
		check(InputMap.has_action(action), "keyboard mapping " + action)
	game.begin_stage(0)
	play_perfect(game)
	check(game.state == "practice_result" and game.seen_tutorial, "tutorial success unlocks main game")
	var note_count := 0
	for index in range(1,4):
		game.begin_stage(index)
		check(game.stage.duration >= 50 and game.stage.duration <= 60, "stage %d lasts 50-60 seconds" % index)
		for round_data in game.stage.timeline:
			for note in round_data.notes:
				check(note.channel >= 1 and note.channel <= 4, "valid channel")
				note_count += 1
		play_perfect(game)
		check(game.scoring.misses == 0, "full stage %d without unintended misses" % index)
	game._process(1.4)
	check(game.state == "clear", "three stages reach actual clear scene")
	check(game.scoring.score == note_count * 100, "full run total score")
	check(game.final_hit, "last channel four completes all screens")
	game.begin_stage(1)
	for round_data in game.stage.timeline:
		if game.state != "playing": break
		game.advance_game(round_data.demo_start)
		for note in round_data.notes:
			if game.state != "playing": break
			game.advance_game(note.target_time + .281)
	check(game.state == "fail" and game.scoring.misses == 15, "15 omissions reach fail scene")
	game.begin_stage(1)
	check(game.scoring.score == 0 and game.scoring.misses == 0, "retry resets run state")
	var first_round: Dictionary = game.stage.timeline[0]
	var first_note: Dictionary = first_round.notes[0]
	var cue_time: float = float(first_note.target_time) - float(game.stage.seconds_per_beat)
	game.ojt_mode = true
	game.advance_game(cue_time - .01)
	check(game.ojt_cue().is_empty(), "OJT stays hidden before its one-beat lead")
	game.advance_game(cue_time + .01)
	check(int(game.ojt_cue().channel) == int(first_note.channel), "OJT previews the correct next channel")
	game._process(0)
	check(game.panels[int(first_note.channel) - 1].hint, "OJT highlights the correct touch screen")
	game.advance_game(float(first_note.target_time) - .27)
	check(game.phase == "answer" and game.now < float(first_round.answer_start), "early input window keeps exact start time for countdown")
	check(game.scoring.score == 0 and game.scoring.misses == 0, "OJT does not score or change timing")
	game.ojt_mode = false
	check(game.ojt_cue().is_empty(), "OJT off hides guidance")
	game.pause_game()
	check(game.state == "paused", "pause opens")
	game.resume_game()
	check(game.state == "playing" and not game.audio.music.stream_paused, "resume restores playback")
	game.show_title()
	check(game.state == "title", "return to title")
	for player in game.audio.effects: player.stop()
	game.audio.music.stop()
	await create_timer(.25).timeout
	game.queue_free()
	await process_frame
	var summary := {"checks": checks, "failures": failures, "full_run_notes": note_count}
	var file := FileAccess.open("res://tests/artifacts/unit_integration.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(summary, "  "))
	print(JSON.stringify(summary))
	quit(0 if failures.is_empty() else 1)

func play_perfect(game) -> void:
	for round_data in game.stage.timeline:
		game.advance_game(round_data.demo_start)
		for note in round_data.notes:
			game.advance_game(note.target_time)
			game.submit_task(note.channel)
		game.advance_game(round_data.end - .001)
	game.advance_game(game.stage.duration)
