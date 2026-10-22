extends Control

const ART = preload("res://assets/background/splash-spider-territory.png")
const ATLAS = preload("res://assets/player/spider_atlas.png")
const RED_SPIDER = preload("res://assets/rival/red_spider.png")
const SPLASH_BUG = preload("res://assets/bugs/web_midge_gold.svg")
const WALK_SHADER = preload("res://shaders/spider_walk.gdshader")
const GameFont = preload("res://scripts/ui/GameFont.gd")
const GAME_SCENE := "res://scenes/main_menu.tscn"

var starting := false
var walking := true
var spider_stage: Control
var blue_spider: Sprite2D
var red_spider: Sprite2D
var center_bug: Sprite2D
var walk_phase := 0.0

func _ready() -> void:
	var artwork := TextureRect.new()
	artwork.texture = ART
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	artwork.modulate = Color(0.72, 0.75, 0.72)
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(artwork)
	spider_stage = Control.new()
	spider_stage.name = "SpiderStage"
	spider_stage.size = Vector2(1920, 1080)
	spider_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(spider_stage)
	var title := Label.new()
	title.name = "SplashTitle"
	title.text = "SPIDER TERRITORY"
	title.position = Vector2(430, 300)
	title.size = Vector2(1060, 180)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 82)
	title.add_theme_font_override("font", GameFont.title_font())
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.54))
	title.add_theme_color_override("font_outline_color", Color(0.025, 0.12, 0.11, 0.98))
	title.add_theme_constant_override("outline_size", 11)
	title.add_theme_color_override("font_shadow_color", Color(0.01, 0.03, 0.025, 0.9))
	title.add_theme_constant_override("shadow_offset_x", 4)
	title.add_theme_constant_override("shadow_offset_y", 6)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spider_stage.add_child(title)
	title.modulate.a = 0.0
	create_tween().tween_property(title, "modulate:a", 1.0, 0.5)
	var blue_texture := AtlasTexture.new()
	blue_texture.atlas = ATLAS
	blue_texture.region = Rect2(12, 4, 565, 410)
	blue_spider = Sprite2D.new()
	blue_spider.name = "BlueSplashSpider"
	blue_spider.texture = ImageTexture.create_from_image(blue_texture.get_image())
	blue_spider.position = Vector2(420, 755)
	blue_spider.scale = Vector2.ONE * 0.42
	blue_spider.rotation = -PI / 2.0
	var blue_material := ShaderMaterial.new()
	blue_material.shader = WALK_SHADER
	blue_spider.material = blue_material
	spider_stage.add_child(blue_spider)
	var red_image := RED_SPIDER.get_image()
	red_image.resize(565, 410, Image.INTERPOLATE_LANCZOS)
	red_spider = Sprite2D.new()
	red_spider.name = "RedSplashSpider"
	red_spider.texture = ImageTexture.create_from_image(red_image)
	red_spider.position = Vector2(1500, 755)
	red_spider.scale = Vector2.ONE * 0.42
	red_spider.rotation = PI / 2.0
	var red_material := ShaderMaterial.new()
	red_material.shader = WALK_SHADER
	red_spider.material = red_material
	spider_stage.add_child(red_spider)
	center_bug = Sprite2D.new()
	center_bug.name = "SplashBug"
	center_bug.texture = SPLASH_BUG
	center_bug.position = Vector2(960, 665)
	center_bug.scale = Vector2.ONE * 0.42
	spider_stage.add_child(center_bug)
	var bug_flight := create_tween().set_loops()
	bug_flight.tween_property(center_bug, "position:y", 635.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bug_flight.tween_property(center_bug, "position:y", 665.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var approach := create_tween().set_parallel(true)
	approach.tween_property(blue_spider, "position", Vector2(840, 755), 2.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	approach.tween_property(red_spider, "position", Vector2(1080, 755), 2.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	approach.finished.connect(func() -> void: walking = false)
	get_viewport().size_changed.connect(update_layout)
	update_layout()
	get_tree().create_timer(2.8).timeout.connect(start_game)

func _process(delta: float) -> void:
	if not walking:
		return
	walk_phase += delta * 18.0
	for sprite in [blue_spider, red_spider]:
		if is_instance_valid(sprite):
			sprite.material.set_shader_parameter("gait_phase", walk_phase)
			sprite.material.set_shader_parameter("gait_strength", 1.0)
			sprite.offset.y = sin(walk_phase * 2.0) * 8.0

func update_layout() -> void:
	var viewport_size := get_viewport_rect().size
	var factor: float = minf(viewport_size.x / 1920.0, viewport_size.y / 1080.0)
	spider_stage.scale = Vector2.ONE * factor
	spider_stage.position = (viewport_size - spider_stage.size * factor) * 0.5

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		start_game()
	elif event is InputEventMouseButton and event.pressed:
		start_game()
	elif event is InputEventKey and event.pressed and not event.echo:
		start_game()

func start_game() -> void:
	if starting or not is_inside_tree():
		return
	starting = true
	walking = false
	get_node("/root/GameManager").show_scene(GAME_SCENE)
