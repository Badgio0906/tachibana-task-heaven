extends Control

const INK := Color("263448")
const PAPER := Color("fffdf3")
const CREAM := Color("f5f0df")
const TEAL := Color("79b5a6")
const ORANGE := Color("efa76c")
var game: Control
var font: Font
var characters: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = load("res://assets/fonts/NotoSansJP-Regular.otf")
	for name in ["tachibana_idle", "tachibana_success", "tachibana_miss", "tachibana_clear", "tachibana_fail", "tachibana_title", "boss_idle", "boss_talk", "boss_happy", "boss_angry", "boss_clap", "boss_clap2"]:
		characters[name] = load("res://assets/characters/" + name + ".svg")

func box(rect: Rect2, color: Color, radius := 16, border := 0) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = INK
	style.set_corner_radius_all(radius)
	style.set_border_width_all(border)
	draw_style_box(style, rect)

func txt(words: String, x: float, y: float, font_size := 24, color: Color = INK) -> void:
	draw_string(font, Vector2(x, y), words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func center(words: String, y: float, font_size := 24, color: Color = INK) -> void:
	txt(words, (1280 - font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x) * .5, y, font_size, color)

func character(name: String, rect: Rect2) -> void:
	draw_texture_rect(characters[name], rect, false)

func office() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), CREAM)
	draw_rect(Rect2(0, 159, 1280, 361), Color("e2eadd"))
	for x in [50, 367, 684]:
		box(Rect2(x, 174, 257, 116), PAPER, 14, 3)
		draw_rect(Rect2(x + 8, 182, 241, 100), Color("b9d6dd"))
		for j in range(5):
			draw_rect(Rect2(x + 16 + j * 44, 231 - (j % 3) * 12, 29, 51 + (j % 3) * 12), Color("93b4c5"))
		draw_line(Vector2(x + 130, 180), Vector2(x + 130, 286), INK, 3)
	box(Rect2(38, 527, 910, 39), Color("c28d69"), 9, 4)
	draw_rect(Rect2(61, 566, 864, 154), Color("dbb38c"))
	box(Rect2(994, 508, 236, 30), Color("c28d69"), 8, 3)
	draw_rect(Rect2(1015, 538, 190, 182), Color("dbb38c"))
	# Two ultrawide monitors, each containing two distinct task regions.
	box(Rect2(39, 292, 417, 233), INK, 17)
	box(Rect2(477, 292, 417, 233), INK, 17)
	for x in [214, 652]:
		draw_rect(Rect2(x, 520, 55, 14), INK)
		draw_line(Vector2(x - 25, 535), Vector2(x + 80, 535), INK, 5)
	for i in range(maxi(0, game.stage_index - 1) * 3):
		var x := 78 + (i % 3) * 89
		var y := 586 + (i / 3) * 21
		box(Rect2(x, y, 99, 15), PAPER, 2, 2)
		if i % 2 == 0: draw_rect(Rect2(x + 65, y - 5, 27, 15), Color("f2d376"))
	box(Rect2(819, 575, 68, 63), PAPER, 10, 3)
	draw_arc(Vector2(889, 604), 18, -1.6, 1.6, 15, INK, 4)
	txt("月曜", 829, 612, 17)
	var sway := sin(game.wall_time * 6) * minf(13, game.scoring.combo / 2.5)
	character("tachibana_" + game.tachibana_expression, Rect2(351 + sway, 509, 225, 253))
	character("boss_" + game.boss_expression, Rect2(986, 282, 242, 272))
	if game.tachibana_expression == "miss": txt("!?", 560, 597, 45, Color("da6859"))
	elif game.scoring.combo >= 10: txt("♪".repeat(mini(3, game.scoring.combo / 10)), 566, 613, 36, TEAL)
	elif game.stage_index >= 2: txt("汗".repeat(game.stage_index - 1), 565, 598, 22, Color("5b94bc"))
	box(Rect2(998, 189, 234, 86), PAPER, 20, 3)
	var boss_copy: String = game.instruction if game.phase == "demo" else ["今日もよろしく！", "いいペースですね", "まだまだあります！", "これ、全部お願い！"][game.stage_index]
	txt(boss_copy, 1011, 240, 19)

func hud() -> void:
	box(Rect2(25, 18, 1128, 108), PAPER, 20, 3)
	txt("SCORE", 47, 50, 16)
	txt("%06d" % game.scoring.score, 45, 96, 38)
	draw_line(Vector2(238, 34), Vector2(238, 106), Color("d8ddce"), 2)
	txt("TASK", 269, 51, 17)
	txt("%d%%" % roundi(game.scoring.task), 631, 53, 23)
	box(Rect2(269, 67, 426, 26), Color("e4e5d9"), 13)
	box(Rect2(269, 67, maxf(7, 426 * game.scoring.task / 100), 26), TEAL if game.scoring.task >= float(game.settings.clear_task) else ORANGE, 13)
	var goal_x := 269 + 426 * float(game.settings.clear_task) / 100.0
	draw_line(Vector2(goal_x, 63), Vector2(goal_x, 99), INK, 2)
	txt("%d%%" % int(game.settings.clear_task), goal_x - 18, 116, 12)
	txt("%d COMBO" % game.scoring.combo, 731, 71, 30)
	txt("MISS  %d / %d" % [game.scoring.misses, int(game.settings.miss_limit)], 732, 104, 17)
	txt("PRACTICE" if game.stage_index == 0 else "STAGE %02d / 03" % game.stage_index, 971, 54, 17)
	txt("%d BPM" % game.stage.bpm, 974, 91, 23)
	var phase_copy: String = {"intro": "お仕事、はじめます", "demo": "上司のお手本 • 覚えよう", "ready": "はい！ せーの！", "answer": "あなたの番 • 同じリズムで！", "reaction": game.instruction, "final": "FINAL TASK  •  深呼吸…"}.get(game.phase, "")
	box(Rect2(261, 142, 628, 66), INK if game.phase == "answer" else ORANGE, 26, 3)
	txt(phase_copy, 297, 186, 27, PAPER if game.phase == "answer" else INK)
	if game.phase == "demo":
		txt(game.instruction, 321, 264, 43)
	elif game.phase == "final":
		txt("FINAL TASK", 320, 263, 40)
	elif game.judge_text != "" and game.reaction > 0:
		var color := Color("d56858") if game.judge_text.begins_with("MISS") else Color("326a66")
		txt(game.judge_text, 347, 263, 43, color)
		if absf(game.judge_delta) > 1 and not game.judge_text.begins_with("MISS"):
			txt("%+d ms" % roundi(game.judge_delta), 713, 254, 19, color)
	else:
		var beat := maxi(0, int(floor(game.now / float(game.stage.seconds_per_beat))))
		for i in range(4):
			draw_circle(Vector2(443 + i * 80, 247), 13 if i == beat % 4 else 8, TEAL if i == beat % 4 else Color("a7beb4"))
	txt("%s  /  %d:%02d" % [game.stage.theme, int(maxf(0, game.stage.duration - game.now)) / 60, int(maxf(0, game.stage.duration - game.now)) % 60], 41, 698, 19)
	txt("数字キー 1・2・3・4  /  画面をタップ", 768, 697, 19)
	if game.round_index >= 0:
		var round_data: Dictionary = game.stage.timeline[game.round_index]
		var base: float = round_data.demo_start if game.phase == "demo" else round_data.answer_start
		var beat_position: float = (game.now - base) / float(game.stage.seconds_per_beat)
		if game.phase in ["demo", "answer", "ready"]:
			for i in range(int(round_data.length)):
				var point := Vector2(47 + i * 28, 655)
				draw_circle(point, 6, ORANGE if i == int(floor(beat_position)) else PAPER)

func title() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), CREAM)
	for x in range(0, 1280, 40): draw_line(Vector2(x, 0), Vector2(x, 720), Color("e9e4d5"), 1)
	box(Rect2(710, 32, 526, 652), TEAL, 36, 3)
	box(Rect2(52, 50, 279, 37), ORANGE, 18)
	txt("OFFICE RHYTHM COMEDY", 70, 76, 16)
	txt("立花さんの", 77, 205, 55)
	txt("タスク天国", 70, 303, 91)
	txt("仕事を、奏でよう。", 83, 369, 28)
	txt("上司の指示を覚えて、同じリズムでお仕事！", 84, 409, 19)
	txt("1 PLAY  約3分  •  キーボード / タッチ", 84, 650, 18)
	txt("BEST  %06d" % game.best_score, 84, 684, 16)
	box(Rect2(749, 110, 448, 241), INK, 19)
	for i in range(4):
		var x := 762 + (i % 2) * 213
		var y := 124 + (i / 2) * 105
		box(Rect2(x, y, 207, 99), TaskScreen.COLORS[i], 9)
		txt(str(i + 1) + "  " + TaskScreen.NAMES[i], x + 15, y + 43, 23)
		draw_line(Vector2(x + 17, y + 67), Vector2(x + 167, y + 67), PAPER, 7)
	box(Rect2(742, 364, 467, 39), Color("d6a180"), 9, 3)
	character("tachibana_title", Rect2(796, 343 + sin(game.wall_time * 2) * 3, 300, 337))
	character("boss_happy", Rect2(1034, 415, 174, 196))
	box(Rect2(951, 42, 249, 57), PAPER, 24, 3)
	txt("立花さん、お願い！", 968, 80, 23)
	txt("♪", 757, 523, 53, PAPER)
	txt("♪", 1153, 382, 48, PAPER)

func help() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), CREAM)
	box(Rect2(80, 53, 1120, 613), PAPER, 30, 3)
	txt("遊び方", 126, 118, 40)
	txt("上司の指示を覚えて、同じリズムでタスクを処理しよう！", 128, 171, 25)
	for i in range(4):
		box(Rect2(127 + i * 252, 206, 233, 88), TaskScreen.COLORS[i], 16, 2)
		txt("%d  %s" % [i + 1, TaskScreen.NAMES[i]], 146 + i * 252, 246, 25)
		txt(["タンバリン", "トライアングル", "シンバル", "バスドラム"][i], 146 + i * 252, 277, 17)
	txt("① お手本を聞く   →   ②「はい！」  →   ③ 同じ拍で 1〜4", 128, 343, 24)
	txt("スマートフォンは対応する画面を直接タップ。横向きで遊びます。", 128, 382, 20)
	txt("PERFECT ±%dms / GOOD ±%dms / OK ±%dms" % [roundi(float(game.settings.PERFECT_WINDOW) * 1000), roundi(float(game.settings.GOOD_WINDOW) * 1000), roundi(float(game.settings.OK_WINDOW) * 1000)], 128, 430, 18)
	txt("最後にTASK %d%%以上でクリア。" % int(game.settings.clear_task), 128, 468, 21)
	txt("%d MISSでカムチャッカ行き！" % int(game.settings.miss_limit), 128, 505, 21)
	txt("入力補正  %+d ms" % int(game.settings.input_offset_ms), 764, 488, 18)
	txt("音量  %d%%" % roundi(game.volume * 100), 791, 554, 20)
	txt("入力が遅れて判定される場合は + に調整", 605, 608, 16)

func result(clear: bool) -> void:
	draw_rect(Rect2(0, 0, 1280, 720), CREAM if clear else Color("bdcfdd"))
	if clear:
		for i in range(75):
			var p := Vector2(fmod(i * 113.0 + sin(i) * 20, 1280), fmod(i * 47.0 + game.wall_time * (20 + i % 18), 550))
			draw_rect(Rect2(p, Vector2(9, 15)), [TEAL, ORANGE, Color("edcd68"), Color("9ab6d4")][i % 4])
		center("仕事終了！", 77, 46)
		center("立花さんは見事タスクを処理しきり、褒められた", 128, 28)
		character("tachibana_clear", Rect2(436 + sin(game.wall_time * 4) * 8, 164, 299, 337))
		character("boss_clap" if sin(game.wall_time * 12) > 0 else "boss_clap2", Rect2(753, 238, 220, 248))
		var clap := sin(game.wall_time * 12) * 7
		draw_line(Vector2(795, 365), Vector2(776 - clap, 351), ORANGE, 4)
		draw_line(Vector2(796, 382), Vector2(771 - clap, 384), ORANGE, 4)
		txt("えへへ", 330, 309, 43, Color("c07560"))
	else:
		draw_colored_polygon(PackedVector2Array([Vector2(0, 438), Vector2(236, 207), Vector2(502, 449)]), Color("e9f1f4"))
		draw_colored_polygon(PackedVector2Array([Vector2(720, 448), Vector2(1000, 177), Vector2(1280, 456)]), Color("e9f1f4"))
		draw_rect(Rect2(0, 450, 1280, 270), Color("f0f5f6"))
		center("まさかの、人事異動。", 75, 42)
		center("立花さんはタスク処理が出来ず、", 124, 25)
		center("カムチャッカ半島第2オフィスへ左遷された", 163, 27)
		box(Rect2(139, 263, 309, 119), Color("d6b697"), 5, 4)
		txt("カムチャッカ半島", 157, 307, 27)
		txt("第2オフィス", 193, 352, 29)
		draw_line(Vector2(290, 383), Vector2(290, 480), INK, 9)
		character("tachibana_fail", Rect2(536, 190, 277, 312))
		for i in range(60):
			draw_circle(Vector2(fmod(i * 83.0 + game.wall_time * 13, 1280), fmod(i * 71.0 + game.wall_time * 34, 494)), 3 + i % 3, PAPER)
	box(Rect2(251, 503, 778, 87), PAPER, 21, 3)
	txt("SCORE  %06d" % game.scoring.score, 280, 542, 27)
	txt("BEST COMBO  %d" % game.scoring.best_combo, 590, 542, 24)
	txt("TASK  %d%%" % roundi(game.scoring.task), 846, 542, 22)
	txt("PERFECT %d    GOOD %d    OK %d    MISS %d" % [game.scoring.counts.PERFECT, game.scoring.counts.GOOD, game.scoring.counts.OK, game.scoring.counts.MISS], 372, 571, 18)

func _draw() -> void:
	if font == null: return
	match game.state:
		"title": title()
		"help": help()
		"loading":
			draw_rect(Rect2(0, 0, 1280, 720), CREAM)
			center("音を準備しています…", 349, 36)
			center("まもなくお仕事が始まります", 403, 22)
		"clear": result(true)
		"fail": result(false)
		_:
			office()
			hud()
			if game.state in ["between", "practice_result", "paused", "finishing"]:
				draw_rect(Rect2(0, 133, 1280, 587), Color(0.15, .2, .28, .62))
				box(Rect2(272, 235, 736, 315), PAPER, 29, 3)
				center("ひと休み" if game.state == "paused" else game.instruction, 311, 31)
				if game.state == "between": center("TASK %d%%  •  COMBO %d" % [roundi(game.scoring.task), game.scoring.combo], 363, 22)
