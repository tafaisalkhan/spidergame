extends CharacterBody2D
class_name Spider

const WALK_SHADER = preload("res://shaders/spider_walk.gdshader")
const HealthBarScript = preload("res://scripts/world_health_bar.gd")

signal moved(distance: float)

var owner_id := 1
var desired_direction := Vector2.ZERO
var speed := 265.0
var acceleration := 1250.0
var bounds := Rect2(65, 245, 950, 1375)
var arena_center := Vector2.ZERO
var arena_radius := 0.0
var visual: Sprite2D
var health_bar: WorldHealthBar
var bob := 0.0
var gait_phase := 0.0
var gait_strength := 0.0
var panic_level := 0.0
var walk_material: ShaderMaterial
var catch_tween: Tween
var catch_rest_scale := Vector2.ONE
var catching := false

func setup(texture: Texture2D, team: int) -> void:
	owner_id = team
	visual = Sprite2D.new()
	if texture is AtlasTexture:
		texture = ImageTexture.create_from_image(texture.get_image())
	visual.texture = texture
	visual.scale = Vector2(0.34, 0.34)
	walk_material = ShaderMaterial.new()
	walk_material.shader = WALK_SHADER
	visual.material = walk_material
	add_child(visual)
	health_bar = HealthBarScript.new()
	health_bar.name = "HealthBar"
	health_bar.fill_color = Color(0.33, 0.86, 1.0) if team == 1 else Color(1.0, 0.37, 0.35)
	add_child(health_bar)
	var shape := CircleShape2D.new()
	shape.radius = 32.0
	var collider := CollisionShape2D.new()
	collider.shape = shape
	add_child(collider)
	collision_layer = 2 if team == 1 else 4
	collision_mask = 1

func _process(_delta: float) -> void:
	if health_bar != null and visual != null:
		health_bar.position = Vector2(0.0, -visual.texture.get_height() * visual.scale.y * 0.5 - 20.0)
		var target_width := clampf(visual.texture.get_width() * visual.scale.x * 0.75, 54.0, 145.0)
		if not is_equal_approx(health_bar.bar_width, target_width):
			health_bar.bar_width = target_width
			health_bar.queue_redraw()

func set_health(value: float) -> void:
	if health_bar != null:
		health_bar.set_health(value)

func _physics_process(delta: float) -> void:
	velocity = velocity.move_toward(desired_direction.normalized() * speed, acceleration * delta)
	var before := global_position
	move_and_slide()
	global_position = global_position.clamp(bounds.position, bounds.end)
	if arena_radius > 0.0:
		var offset := global_position - arena_center
		if offset.length() > arena_radius:
			global_position = arena_center + offset.normalized() * arena_radius
			velocity -= offset.normalized() * maxf(0.0, velocity.dot(offset.normalized()))
	var distance := before.distance_to(global_position)
	if distance > 0.05:
		moved.emit(distance)
		face_motion(velocity, delta)
	animate_walk(delta, distance > 0.05)

func face_motion(direction: Vector2, _delta: float) -> void:
	if direction.length_squared() < 0.001:
		return
	# The painted spider's face points down in its unrotated texture.
	visual.rotation = direction.angle() - PI / 2.0

func play_catch() -> void:
	if catch_tween != null and catch_tween.is_running():
		catch_tween.kill()
	else:
		catch_rest_scale = visual.scale
	catching = true
	visual.scale = catch_rest_scale
	visual.modulate = Color.WHITE
	catch_tween = create_tween()
	catch_tween.tween_property(visual, "scale", catch_rest_scale * Vector2(1.24, 0.79), 0.12)
	catch_tween.parallel().tween_property(visual, "modulate", Color(1.33, 1.23, 0.86), 0.12)
	catch_tween.tween_property(visual, "scale", catch_rest_scale * Vector2(0.90, 1.14), 0.12)
	catch_tween.tween_property(visual, "scale", catch_rest_scale, 0.18)
	catch_tween.parallel().tween_property(visual, "modulate", Color.WHITE, 0.18)
	catch_tween.finished.connect(func() -> void: catching = false)

func start_eating() -> void:
	reset_catch()
	catch_rest_scale = visual.scale
	catching = true
	animate_walk(0.1, false)
	catch_tween = create_tween().set_loops()
	catch_tween.tween_property(visual, "scale", catch_rest_scale * Vector2(1.19, 0.82), 0.16).set_trans(Tween.TRANS_SINE)
	catch_tween.parallel().tween_property(visual, "modulate", Color(1.24, 1.17, 0.9), 0.16)
	catch_tween.tween_property(visual, "scale", catch_rest_scale * Vector2(0.94, 1.12), 0.16).set_trans(Tween.TRANS_SINE)
	catch_tween.parallel().tween_property(visual, "modulate", Color.WHITE, 0.16)

func finish_eating() -> void:
	reset_catch()

func reset_catch() -> void:
	if catch_tween != null and catch_tween.is_running():
		catch_tween.kill()
	if catching:
		visual.scale = catch_rest_scale
	visual.modulate = Color.WHITE
	catching = false

func set_panic(level: float) -> void:
	panic_level = clampf(level, 0.0, 1.0)

func animate_walk(delta: float, moving: bool) -> void:
	gait_strength = move_toward(gait_strength, 1.0 if moving else panic_level * 0.65, delta * 9.0)
	if moving or panic_level > 0.0:
		gait_phase += delta * (18.0 + panic_level * 14.0)
		bob += delta * (18.0 + panic_level * 14.0)
	visual.position.y = sin(bob * 2.0) * (2.5 + panic_level * 3.5) * gait_strength
	visual.position.x = sin(bob * (1.0 + panic_level * 0.4)) * (1.8 + panic_level * 4.0) * gait_strength
	walk_material.set_shader_parameter("gait_phase", gait_phase)
	walk_material.set_shader_parameter("gait_strength", gait_strength)

