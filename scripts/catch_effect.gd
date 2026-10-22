extends Node2D
class_name SpiderCatchEffect

const DURATION := 0.68
const DOTS := 14

var age := 0.0
var color := Color(0.16, 0.61, 0.98)

func setup(team: int) -> void:
	color = Color(0.16, 0.61, 0.98) if team == 1 else Color(1.0, 0.29, 0.20)
	add_to_group("catch_effects")

func _process(delta: float) -> void:
	age += delta
	if age >= DURATION:
		queue_free()
	else:
		queue_redraw()

func _draw() -> void:
	var progress := clampf(age / DURATION, 0.0, 1.0)
	var fade := 1.0 - progress
	draw_circle(Vector2.ZERO, 38.0 + progress * 65.0, Color(color.r, color.g, color.b, 0.19 * fade))
	draw_arc(Vector2.ZERO, 29.0 + progress * 93.0, 0.0, TAU, 44, Color(0.99, 0.70, 0.20, 0.78 * fade), 3.4, true)
	for axis in [Vector2.RIGHT, Vector2.DOWN]:
		draw_line(-axis * (23.0 + progress * 15.0), axis * (23.0 + progress * 15.0), Color(1.0, 0.82, 0.27, 0.85 * fade), 4.0, true)
	for i in DOTS:
		var angle := TAU * float(i) / float(DOTS) + sin(float(i) * 2.3) * 0.15
		var direction := Vector2.RIGHT.rotated(angle)
		var distance := 35.0 + progress * (85.0 + float(i % 4) * 11.0)
		var at := direction * distance
		var radius := maxf(0.8, (9.2 - float(i % 3) * 1.1) * fade)
		draw_line(at - direction * 27.0 * fade, at, Color(color.r, color.g, color.b, 0.86 * fade), 4.2, true)
		draw_circle(at, radius * 1.85, Color(color.r, color.g, color.b, 0.32 * fade))
		draw_circle(at, radius, Color(1.0, 0.68, 0.15, 0.98 * fade))
		draw_circle(at + Vector2(-1.5, -1.5), radius * 0.35, Color(1.0, 1.0, 0.85, 0.96 * fade))
