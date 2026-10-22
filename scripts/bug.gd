extends Node2D
class_name GardenBug

const HealthBarScript = preload("res://scripts/world_health_bar.gd")

signal caught(bug: GardenBug, team: int)

var reward := 10
var kind := "Fly"
var active := true
var drift := Vector2.ZERO
var change_timer := 0.0
var home := Vector2.ZERO
var rng := RandomNumberGenerator.new()
var sprite: Sprite2D
var health_bar: WorldHealthBar

func setup(texture: Texture2D, bug_kind: String, silk_reward: int, seed_value: int) -> void:
	kind = bug_kind
	reward = silk_reward
	rng.seed = seed_value
	home = position
	sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2(0.15, 0.15) if kind != "Ladybug" else Vector2(0.12, 0.12)
	add_child(sprite)
	health_bar = HealthBarScript.new()
	health_bar.name = "HealthBar"
	health_bar.bar_width = 48.0
	health_bar.bar_height = 7.0
	health_bar.fill_color = Color(0.89, 0.94, 0.37)
	health_bar.position = Vector2(0.0, -34.0)
	add_child(health_bar)
	choose_drift()

func choose_drift() -> void:
	change_timer = rng.randf_range(0.7, 2.2)
	var low := 10.0 if kind == "Ladybug" else (28.0 if kind == "Butterfly" else 17.0)
	var high := 25.0 if kind == "Ladybug" else (64.0 if kind == "Butterfly" else 44.0)
	drift = Vector2.from_angle(rng.randf_range(0.0, TAU)) * rng.randf_range(low, high)

func _process(delta: float) -> void:
	if not active:
		return
	change_timer -= delta
	if change_timer <= 0.0:
		choose_drift()
	position += drift * delta
	if position.distance_to(home) > 105.0:
		drift = (home - position).normalized() * 42.0
	sprite.position.y = sin(Time.get_ticks_msec() * 0.006 + float(get_instance_id() % 10)) * 5.0

func try_catch(spider: Spider) -> bool:
	if active and position.distance_to(spider.position) < 57.0:
		health_bar.set_health(0.0)
		active = false
		visible = false
		caught.emit(self, spider.owner_id)
		return true
	return false

func respawn() -> void:
	position = home
	active = true
	visible = true
	health_bar.set_health(100.0)

