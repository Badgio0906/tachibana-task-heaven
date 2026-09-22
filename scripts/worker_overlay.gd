extends Control

var game: Control
var sprites: Dictionary = {}

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for expression in ["idle", "success", "miss"]:
		sprites[expression] = load("res://assets/characters/tachibana_%s.svg" % expression)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if game.state != "playing": return
	var texture: Texture2D = sprites[game.tachibana_expression]
	var sway: float = sin(game.wall_time * 6.0) * minf(9.0, game.scoring.combo / 3.0)
	# Foreground at a raised rear-quarter desk angle. The lower screen edges may sit behind the worker.
	var rect := Rect2(320 + sway, 453, 304, 405)
	var factor := minf(rect.size.x / texture.get_width(), rect.size.y / texture.get_height())
	var drawn_size := texture.get_size() * factor
	var origin := rect.position + Vector2((rect.size.x - drawn_size.x) * .5, rect.size.y - drawn_size.y)
	draw_texture_rect(texture, Rect2(origin.round(), drawn_size), false)
