extends Control

const Loader = preload("res://scripts/stage_loader.gd")
const Score = preload("res://scripts/score_manager.gd")
const Rhythm = preload("res://scripts/rhythm_manager.gd")
const Audio = preload("res://scripts/audio_manager.gd")
const Screen = preload("res://scripts/task_screen.gd")
const Board = preload("res://scripts/office_view.gd")
var state := "title"
var previous_state := "title"
var settings: Dictionary
var stage: Dictionary = {}
var stage_index := 0
var round_index := -1
var phase := ""
var instruction := "今日も、いい仕事を。"
var judge_text := ""
var judge_delta := 0.0
var reaction := 0.0
var boss_expression := "idle"
var tachibana_expression := "idle"
var now := 0.0
var wall_time := 0.0
var demo_seen: Dictionary = {}
var rest_seen: Dictionary = {}
var scoring: ScoreManager
var rhythm: RhythmManager
var audio: TaskAudioManager
var board: Control
var panels: Array = []
var buttons: Array = []
var font: Font
var seen_tutorial := false
var best_score := 0
var volume := .75
var pending_stage := 0
var final_hit := false
var finish_started := 0.0
var pause_usec := 0
var test_mode := false
var portrait: Panel
var status_elapsed := 0.0

func _ready() -> void:
	settings = Loader.read_json("res://data/settings.json")
	font = load("res://assets/fonts/NotoSansJP-Regular.otf")
	test_mode = OS.is_debug_build() and "--verify" in OS.get_cmdline_user_args()
	if not test_mode: load_preferences()
	for i in range(1, 5):
		var action := "task_%d" % i
		if not InputMap.has_action(action): InputMap.add_action(action)
		var key := InputEventKey.new()
		key.physical_keycode = KEY_1 + i - 1
		InputMap.action_add_event(action, key)
	scoring = Score.new(settings)
	audio = Audio.new()
	add_child(audio)
	board = Board.new()
	board.game = self
	board.size = Vector2(1280, 720)
	add_child(board)
	for i in range(4):
		var panel := Screen.new()
		panel.task_id = i + 1
		panel.position = Vector2(53 + i * 208 + (22 if i > 1 else 0), 307)
		panel.size = Vector2(192, 207)
		panel.submitted.connect(submit_task)
		board.add_child(panel)
		panels.append(panel)
	portrait = Panel.new()
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("263448")
	portrait.add_theme_stylebox_override("panel", style)
	add_child(portrait)
	var label := Label.new()
	label.text = "画面を横向きに\nしてください\n\n4つの業務画面をタップ！"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 28)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait.add_child(label)
	resized.connect(fit_board)
	fit_board()
	show_title()
	if OS.is_debug_build():
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--capture="):
				capture_state.call_deferred(arg.trim_prefix("--capture="))

func fit_board() -> void:
	if not is_instance_valid(board): return
	var factor := minf(size.x / 1280.0, size.y / 720.0)
	board.scale = Vector2.ONE * factor
	board.position = (size - Vector2(1280, 720) * factor) * .5
	portrait.visible = size.y > size.x
	if portrait.get_child_count() > 0:
		portrait.get_child(0).add_theme_font_size_override("font_size", roundi(size.x / 390.0 * 22.0))
	if portrait.visible and state == "playing": pause_game()

func load_preferences() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://task_heaven.cfg") == OK:
		seen_tutorial = cfg.get_value("game", "tutorial", false)
		best_score = cfg.get_value("game", "best", 0)
		settings.input_offset_ms = cfg.get_value("audio", "offset_ms", 0)
		volume = cfg.get_value("audio", "volume", .75)

func save_preferences() -> void:
	if test_mode: return
	var cfg := ConfigFile.new()
	cfg.set_value("game", "tutorial", seen_tutorial)
	cfg.set_value("game", "best", best_score)
	cfg.set_value("audio", "offset_ms", settings.input_offset_ms)
	cfg.set_value("audio", "volume", volume)
	cfg.save("user://task_heaven.cfg")

func clear_buttons() -> void:
	for button in buttons:
		button.queue_free()
	buttons.clear()

func button(label: String, rect: Rect2, callback: Callable, primary := false) -> void:
	var node := Button.new()
	node.text = label
	node.position = rect.position
	node.size = rect.size
	node.add_theme_font_override("font", font)
	node.add_theme_font_size_override("font_size", 22)
	node.add_theme_color_override("font_color", Color("fffdf3") if primary else Color("263448"))
	node.add_theme_color_override("font_hover_color", Color("fffdf3") if primary else Color("263448"))
	for style_name in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("263448") if primary else Color("fffdf3")
		if style_name == "hover": style.bg_color = Color("426a78") if primary else Color("f9df98")
		if style_name == "pressed": style.bg_color = Color("638496") if primary else Color("efb06c")
		style.border_color = Color("263448")
		style.set_border_width_all(3)
		style.set_corner_radius_all(15)
		node.add_theme_stylebox_override(style_name, style)
	node.pressed.connect(callback)
	board.add_child(node)
	buttons.append(node)

func show_title() -> void:
	audio.stop()
	state = "title"
	judge_text = ""
	clear_buttons()
	button("START   →", Rect2(83, 454, 310, 68), start_run, true)
	button("遊び方 / 音の調整", Rect2(83, 537, 310, 56), show_help)

func show_help() -> void:
	state = "help"
	clear_buttons()
	button("練習してはじめる", Rect2(130, 566, 330, 64), func(): request_start(0), true)
	button("TITLE", Rect2(950, 566, 180, 64), show_title)
	button("−20 ms", Rect2(605, 456, 145, 48), func(): adjust_offset(-20))
	button("+20 ms", Rect2(935, 456, 145, 48), func(): adjust_offset(20))
	button("音量 −", Rect2(605, 522, 145, 48), func(): adjust_volume(-.15))
	button("音量 +", Rect2(935, 522, 145, 48), func(): adjust_volume(.15))

func adjust_offset(amount: int) -> void:
	settings.input_offset_ms = clampi(int(settings.input_offset_ms) + amount, -200, 200)
	save_preferences()

func adjust_volume(amount: float) -> void:
	audio.unlock()
	volume = clampf(volume + amount, 0.0, 1.0)
	audio.set_volume(volume)
	audio.play_effect("triangle")
	save_preferences()

func start_run() -> void:
	if seen_tutorial:
		request_start(1)
	else:
		audio.unlock()
		show_help()

func request_start(index: int) -> void:
	audio.unlock()
	pending_stage = index
	state = "loading"
	clear_buttons()

func begin_stage(index: int) -> void:
	stage_index = index
	stage = Loader.load_stage(index)
	if index <= 1: scoring = Score.new(settings)
	rhythm = Rhythm.new(scoring)
	rhythm.offset_seconds = float(settings.input_offset_ms) / 1000.0
	rhythm.judged.connect(on_judged)
	round_index = -1
	demo_seen.clear()
	rest_seen.clear()
	state = "playing"
	phase = "intro"
	instruction = "まずは、上司のお手本！"
	judge_text = ""
	final_hit = false
	for panel in panels:
		panel.complete = false
		panel.notifications = maxi(1, index)
	clear_buttons()
	button("Ⅱ", Rect2(1178, 23, 60, 48), pause_game)
	audio.set_volume(volume)
	audio.start_track(index)

func _process(delta: float) -> void:
	wall_time += delta
	reaction = maxf(0.0, reaction - delta)
	if reaction <= 0.0:
		boss_expression = "idle"
		tachibana_expression = "idle"
	if state == "loading" and audio.ready_to_play(): begin_stage(pending_stage)
	if state == "playing" and not test_mode:
		advance_game(audio.clock_seconds())
	if state == "finishing" and wall_time - finish_started > 1.3:
		show_result(scoring.cleared())
	for panel in panels:
		panel.visible = state == "playing"
		panel.mouse_filter = Control.MOUSE_FILTER_STOP if state == "playing" else Control.MOUSE_FILTER_IGNORE
	board.queue_redraw()
	status_elapsed += delta
	if audio.is_web and status_elapsed > .1:
		status_elapsed = 0.0
		var status := {"state": state, "stage": stage_index, "phase": phase, "round": round_index,
			"score": scoring.score, "combo": scoring.combo, "misses": scoring.misses,
			"task": scoring.task, "counts": scoring.counts, "portrait": portrait.visible}
		JavaScriptBridge.eval("window.TaskHeavenStatus = " + JSON.stringify(status), true)

func advance_game(time_value: float) -> void:
	if state != "playing": return
	now = time_value
	var timeline: Array = stage.timeline
	for r in range(timeline.size()):
		var round_data: Dictionary = timeline[r]
		if now >= float(round_data.demo_start) and now < float(round_data.end):
			if round_index != r:
				round_index = r
				rhythm.begin(round_data.notes)
				rhythm.active = false
				judge_text = ""
			var demo_end := float(round_data.answer_start) - 2.0 * float(stage.seconds_per_beat)
			if now < demo_end:
				phase = "demo"
				for n in range(round_data.notes.size()):
					var note: Dictionary = round_data.notes[n]
					var key := "%d/%d" % [r, n]
					if now >= float(note.demo_time) and not demo_seen.has(key):
						demo_seen[key] = true
						instruction = Screen.NAMES[int(note.channel) - 1] + "！"
						panels[int(note.channel) - 1].activate()
						boss_expression = "talk"
						reaction = .22
				for rest in round_data.rests:
					var key := "%d/rest/%s" % [r, str(rest)]
					if now >= float(round_data.demo_start) + float(rest) * float(stage.seconds_per_beat) and not rest_seen.has(key):
						rest_seen[key] = true
						if now < float(round_data.demo_start) + (float(rest) + .65) * float(stage.seconds_per_beat): instruction = "（ひと休み）"
			elif now < float(round_data.answer_start) - float(settings.OK_WINDOW) + rhythm.offset_seconds:
				phase = "ready"
				instruction = "はい！　せーの！"
			else:
				phase = "answer"
				instruction = "あなたの番！"
				var input_end := float(round_data.answer_start) + float(round_data.length) * float(stage.seconds_per_beat) + float(settings.OK_WINDOW) + rhythm.offset_seconds
				rhythm.active = now <= input_end
				if rhythm.active: rhythm.expire(now)
				if now > input_end:
					phase = "reaction"
					instruction = "その調子！" if scoring.combo > 0 else "次、いきますよ！"
			break
		elif r == timeline.size() - 1 and now >= float(round_data.end):
			finish_stage()
			return
		elif round_data.get("final", false) and now >= float(round_data.demo_start) - 4.0 * float(stage.seconds_per_beat) and now < float(round_data.demo_start):
			phase = "final"
			instruction = "FINAL TASK"
			rhythm.active = false
	if stage_index > 0 and scoring.misses >= int(settings.miss_limit): show_result(false)

func submit_task(channel: int) -> void:
	if state != "playing" or phase != "answer": return
	rhythm.submit_task(channel, now if test_mode else audio.clock_seconds())
	if stage_index > 0 and scoring.misses >= int(settings.miss_limit): show_result(false)

func on_judged(channel: int, grade_name: String, delta: float, omitted: bool) -> void:
	judge_text = grade_name + ("!" if grade_name != "MISS" else "...")
	judge_delta = delta
	reaction = .45
	if grade_name == "MISS":
		panels[channel - 1].miss()
		audio.play_effect("omit" if omitted else "error")
		boss_expression = "angry"
		tachibana_expression = "miss"
	else:
		panels[channel - 1].success()
		audio.task_sound(channel)
		boss_expression = "happy"
		tachibana_expression = "success"
		if stage_index == 3 and round_index == stage.timeline.size() - 1:
			if rhythm.resolved.size() == rhythm.notes.size() and channel == 4:
				final_hit = true
				for panel in panels: panel.complete = true

func finish_stage() -> void:
	rhythm.active = false
	audio.stop()
	clear_buttons()
	if stage_index == 0:
		state = "practice_result"
		if scoring.misses == 0:
			seen_tutorial = true
			save_preferences()
			instruction = "練習完了！ いいリズムです。"
			button("お仕事スタート →", Rect2(440, 383, 400, 66), func(): request_start(1), true)
		else:
			instruction = "もう一度、1 → 2 → 3 → 4"
			button("もう一度練習", Rect2(440, 383, 400, 66), func(): request_start(0), true)
		button("TITLE", Rect2(541, 466, 200, 50), show_title)
	elif stage_index < 3:
		state = "between"
		instruction = "一区切り。次の業務へ！"
		button("STAGE %d へ →" % (stage_index + 1), Rect2(440, 397, 400, 66), func(): request_start(stage_index + 1), true)
	else:
		state = "finishing"
		finish_started = wall_time
		instruction = "仕事終了！" if scoring.cleared() else "業務査定中…"

func show_result(clear: bool) -> void:
	audio.stop()
	state = "clear" if clear else "fail"
	best_score = maxi(best_score, scoring.score)
	save_preferences()
	audio.play_effect("clear" if clear else "fail")
	if not clear: audio.play_effect("wind")
	clear_buttons()
	button("もう一度 / RETRY", Rect2(376, 615, 302, 61), func(): request_start(1), true)
	button("TITLE", Rect2(699, 615, 205, 61), show_title)

func pause_game() -> void:
	if state != "playing": return
	state = "paused"
	pause_usec = Time.get_ticks_usec()
	if audio.is_web: JavaScriptBridge.eval("window.TaskAudio.context.suspend()", true)
	else: audio.music.stream_paused = true
	clear_buttons()
	button("続ける →", Rect2(441, 345, 399, 65), resume_game, true)
	button("TITLE", Rect2(541, 438, 200, 56), show_title)

func resume_game() -> void:
	if portrait.visible: return
	if audio.is_web: JavaScriptBridge.eval("window.TaskAudio.context.resume()", true)
	else:
		audio.started_usec += Time.get_ticks_usec() - pause_usec
		audio.music.stream_paused = false
	state = "playing"
	clear_buttons()
	button("Ⅱ", Rect2(1178, 23, 60, 48), pause_game)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == "playing": pause_game()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo: return
	for i in range(1, 5):
		if event.is_action_pressed("task_%d" % i):
			submit_task(i)
			get_viewport().set_input_as_handled()
	if event.is_action_pressed("ui_cancel") and state == "playing": pause_game()

func capture_state(which: String) -> void:
	if which == "title": return
	begin_stage(3 if which == "stage3" else 1)
	if which == "clear":
		scoring.task = 100
		scoring.score = 12340
		scoring.best_combo = 84
		show_result(true)
	elif which == "fail": show_result(false)
