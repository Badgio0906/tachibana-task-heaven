class_name TaskScreen
extends Control

signal submitted(channel: int)
const INK := Color("263448")
const COLORS := [Color("83c4e9"), Color("87c7b0"), Color("b9d695"), Color("efb06c")]
const NAMES := ["チャット", "LINE", "Excel", "打刻"]
var task_id := 1
var flash := 0.0
var bad := false
var complete := false
var notifications := 1
var font: Font
var elapsed := 0.0

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	font = load("res://assets/fonts/NotoSansJP-Regular.otf")
	gui_input.connect(_input_panel)

func _input_panel(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		submitted.emit(task_id)
		accept_event()

func activate() -> void:
	flash = .15
	bad = false

func success() -> void:
	activate()

func miss() -> void:
	flash = .18
	bad = true

func _process(delta: float) -> void:
	elapsed += delta
	flash = maxf(0.0, flash - delta)
	pivot_offset = size * .5
	scale = Vector2.ONE * (1.0 + .07 * flash / .18)
	rotation = sin(elapsed * 110.0) * .025 * flash / .18 if bad else 0.0
	queue_redraw()

func box(rect: Rect2, color: Color, radius: int = 12, border: int = 0) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.border_color = INK
	style.set_border_width_all(border)
	draw_style_box(style, rect)

func text_at(words: String, point: Vector2, font_size: int, color: Color = INK) -> void:
	draw_string(font, point, words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw() -> void:
	var tint: Color = COLORS[task_id - 1]
	box(Rect2(Vector2.ZERO, size), Color("fffdf5"), 12, 3)
	box(Rect2(3, 3, size.x - 6, 57), tint, 9)
	text_at(str(task_id), Vector2(15, 42), 32)
	text_at(NAMES[task_id - 1], Vector2(54, 39), 23)
	if complete:
		text_at("TASK", Vector2(35, 110), 26)
		text_at("COMPLETE", Vector2(13, 146), 23)
	else:
		match task_id:
			1:
				for i in range(3):
					draw_circle(Vector2(24, 86 + i * 33), 9, tint)
					box(Rect2(42, 75 + i * 33, 129, 24), Color("e9f2f7"), 6)
				text_at("資料、お願いします", Vector2(49, 92), 12)
				text_at("対応しました！", Vector2(49, 125), 12)
				text_at("立花さん、急ぎで", Vector2(49, 158), 12)
			2:
				box(Rect2(13, 75, 147, 31), Color("e3f0e9"), 11)
				box(Rect2(54, 116, 125, 31), tint, 11)
				text_at("例の件、どう？", Vector2(23, 96), 14)
				text_at("すぐやります！", Vector2(62, 137), 13)
				text_at("既読", Vector2(22, 140), 11)
			3:
				for i in range(4):
					draw_line(Vector2(14, 76 + i * 24), Vector2(179, 76 + i * 24), Color("b1c5ae"), 1.5)
				for x in [14, 76, 124, 179]:
					draw_line(Vector2(x, 76), Vector2(x, 148), Color("b1c5ae"), 1.5)
				text_at("氏名    件数   状況", Vector2(18, 94), 12)
				text_at("山田     12    完了", Vector2(18, 119), 12)
				text_at("佐藤       8    対応", Vector2(18, 143), 12)
			4:
				text_at("09:01", Vector2(38, 110), 31)
				box(Rect2(14, 124, 76, 30), tint, 7)
				box(Rect2(100, 124, 77, 30), Color("eae6dc"), 7)
				text_at("出勤", Vector2(31, 145), 15)
				text_at("退勤", Vector2(117, 145), 15)
		if notifications > 1:
			draw_circle(Vector2(size.x - 12, 7), 14, Color("e27465"))
			text_at(str(notifications * 3), Vector2(size.x - 20, 12), 14, Color.WHITE)
	text_at(["タン！", "チーン！", "シャーン！", "ドン！"][task_id - 1], Vector2(49, 193), 18)
	if flash > 0.0:
		box(Rect2(Vector2.ZERO, size), Color(1.0, .2 if bad else 1.0, .15 if bad else 1.0, flash * 2.8), 12)
