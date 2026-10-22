extends Control
class_name SpiderJoystick

signal direction_changed(direction: Vector2)

var pointer_id := -2
var direction := Vector2.ZERO
var center := Vector2(145, 145)
var radius := 105.0

func _ready() -> void:
	custom_minimum_size = Vector2(290, 290)
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()

func _draw() -> void:
	draw_circle(center, 118.0, Color(0.08, 0.21, 0.25, 0.46))
	draw_arc(center, 106.0, 0.0, TAU, 64, Color(0.70, 0.92, 0.95, 0.75), 5.0, true)
	draw_circle(center + direction * 70.0, 53.0, Color(0.15, 0.55, 0.90, 0.88))
	draw_arc(center + direction * 70.0, 49.0, 0.0, TAU, 40, Color.WHITE, 4.0, true)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and pointer_id == -2:
			pointer_id = event.index
			set_direction(event.position)
		elif not event.pressed and pointer_id == event.index:
			release()
	elif event is InputEventScreenDrag and event.index == pointer_id:
		set_direction(event.position)
	elif event is InputEventMouseButton:
		if event.pressed:
			pointer_id = -1
			set_direction(event.position)
		elif pointer_id == -1:
			release()
	elif event is InputEventMouseMotion and pointer_id == -1:
		set_direction(event.position)

func set_direction(local_point: Vector2) -> void:
	direction = (local_point - center).limit_length(radius) / radius
	direction_changed.emit(direction)
	queue_redraw()

func release() -> void:
	pointer_id = -2
	direction = Vector2.ZERO
	direction_changed.emit(direction)
	queue_redraw()
