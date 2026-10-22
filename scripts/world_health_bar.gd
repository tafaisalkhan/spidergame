extends Node2D
class_name WorldHealthBar

var bar_width := 76.0
var bar_height := 10.0
var health := 100.0
var fill_color := Color(0.35, 0.91, 0.49)

func _ready() -> void:
	z_index = 20
	queue_redraw()

func set_health(value: float) -> void:
	health = clampf(value, 0.0, 100.0)
	queue_redraw()

func _draw() -> void:
	var frame := Rect2(-bar_width * 0.5, -bar_height * 0.5, bar_width, bar_height)
	draw_rect(frame.grow(2.0), Color(0.02, 0.06, 0.06, 0.90), true)
	draw_rect(frame, Color(0.20, 0.24, 0.22, 0.92), true)
	if health > 0.0:
		draw_rect(Rect2(frame.position, Vector2(bar_width * health / 100.0, bar_height)), fill_color, true)
	draw_rect(frame.grow(2.0), Color(0.94, 0.95, 0.86, 0.92), false, 2.0)
