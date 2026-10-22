extends Node2D

var radius := 55.0
var remaining := 3.0
var pulse := 0.0

func _ready() -> void:
	name = "FreezeEffect"
	z_index = 12

func _process(delta: float) -> void:
	remaining -= delta
	pulse += delta * 3.4
	if remaining <= 0.0:
		queue_free()
	else:
		queue_redraw()

func _draw() -> void:
	var shimmer := 0.5 + 0.5 * sin(pulse * 2.0)
	draw_circle(Vector2.ZERO, radius * 0.84, Color(0.36, 0.80, 1.0, 0.13 + shimmer * 0.07))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 44, Color(0.68, 0.94, 1.0, 0.78), 5.0, true)
	for i in 8:
		var angle := TAU * float(i) / 8.0 + pulse * 0.16
		var direction := Vector2.from_angle(angle)
		var tip := direction * radius * (0.96 + 0.06 * shimmer)
		var base := direction * radius * 0.56
		var side := Vector2(-direction.y, direction.x) * 9.0
		draw_colored_polygon(PackedVector2Array([base - side, tip, base + side]), Color(0.72, 0.95, 1.0, 0.78))
		draw_line(base, tip, Color.WHITE, 2.0, true)
	for i in 5:
		var sparkle_angle := TAU * float(i) / 5.0 - pulse * 0.28
		var sparkle := Vector2.from_angle(sparkle_angle) * radius * 1.16
		draw_circle(sparkle, 3.5 + 2.0 * shimmer, Color(0.90, 1.0, 1.0, 0.75))
