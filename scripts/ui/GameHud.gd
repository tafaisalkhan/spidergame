extends Control

const COIN = preload("res://assets/ui/reward-coin.png")
const CLOCK = preload("res://assets/ui/hud_clock.svg")
const COIN_PLAQUE = preload("res://assets/ui/hud_coin_plaque.svg")
const BUG_PLAQUE = preload("res://assets/ui/hud_bug_plaque.svg")
const TIME_PLAQUE = preload("res://assets/ui/hud_time_plaque.svg")
const BUG_ATLAS = preload("res://assets/player/spider_atlas.png")
const GameFont = preload("res://scripts/ui/GameFont.gd")

var level := 1
var campaign := true
var coins_label: Label
var level_label: Label
var bugs_label: Label
var timer_label: Label
var health_bar: ProgressBar
var instruction_label: Label
var display_font: FontVariation

func _ready() -> void:
	position = Vector2(35, 36)
	size = Vector2(1010, 110)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	display_font = GameFont.display_font()
	add_section("CoinPanel", Vector2.ZERO, Vector2(220, 110), COIN_PLAQUE)
	add_section("BugPanel", Vector2(505, 0), Vector2(220, 110), BUG_PLAQUE)
	add_section("TimerPanel", Vector2(750, 0), Vector2(260, 110), TIME_PLAQUE)
	var level_font_size := (62 if level < 10 else (49 if level < 100 else 36)) if campaign else 45
	level_label = make_label("LEVEL %d" % level if campaign else "WEB TRAP", level_font_size, Color(1.0, 0.79, 0.24))
	level_label.add_theme_font_override("font", GameFont.title_font())
	level_label.add_theme_color_override("font_outline_color", Color(0.18, 0.055, 0.005))
	level_label.add_theme_constant_override("outline_size", 9)
	level_label.position = Vector2(220, 8)
	level_label.size = Vector2(280, 95)
	add_child(level_label)
	var coin_icon := TextureRect.new()
	coin_icon.texture = COIN
	coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_icon.position = Vector2(29, 25)
	coin_icon.size = Vector2(60, 60)
	coin_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(coin_icon)
	coins_label = make_label("0", 33, Color(1.0, 0.87, 0.42))
	coins_label.add_theme_font_override("font", GameFont.title_font())
	coins_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.30))
	coins_label.add_theme_font_size_override("font_size", 38)
	coins_label.position = Vector2(91, 29)
	coins_label.size = Vector2(112, 52)
	add_child(coins_label)
	var bug_icon := TextureRect.new()
	bug_icon.name = "BugIcon"
	var bug_texture := AtlasTexture.new()
	bug_texture.atlas = BUG_ATLAS
	bug_texture.region = Rect2(425, 485, 350, 270)
	bug_icon.texture = bug_texture
	bug_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bug_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bug_icon.position = Vector2(516, 25)
	bug_icon.size = Vector2(70, 60)
	bug_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bug_icon)
	bugs_label = make_label("0/20", 32, Color(1.0, 0.91, 0.73))
	bugs_label.add_theme_font_override("font", GameFont.title_font())
	bugs_label.position = Vector2(581, 26)
	bugs_label.size = Vector2(132, 60)
	add_child(bugs_label)
	var clock_icon := TextureRect.new()
	clock_icon.name = "ClockIcon"
	clock_icon.texture = CLOCK
	clock_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	clock_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	clock_icon.position = Vector2(765, 25)
	clock_icon.size = Vector2(60, 60)
	clock_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(clock_icon)
	timer_label = make_label("00:00", 37, Color(0.74, 0.91, 1.0))
	timer_label.add_theme_font_override("font", GameFont.title_font())
	timer_label.add_theme_color_override("font_color", Color(0.78, 0.97, 1.0))
	timer_label.position = Vector2(828, 22)
	timer_label.size = Vector2(165, 65)
	add_child(timer_label)
	health_bar = ProgressBar.new()
	health_bar.visible = false
	health_bar.min_value = 0
	health_bar.max_value = 100
	health_bar.value = 100
	health_bar.show_percentage = false
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.15, 0.22, 0.19)
	background.border_color = Color(0.78, 0.91, 0.70)
	background.set_border_width_all(3)
	background.set_corner_radius_all(14)
	health_bar.add_theme_stylebox_override("background", background)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.37, 0.83, 0.39)
	fill.set_corner_radius_all(12)
	health_bar.add_theme_stylebox_override("fill", fill)
	add_child(health_bar)
	instruction_label = make_label("", 25, Color(0.91, 0.99, 0.90))
	instruction_label.visible = false
	add_child(instruction_label)

func add_section(section_name: String, at: Vector2, dimensions: Vector2, texture: Texture2D) -> void:
	var panel := TextureRect.new()
	panel.name = section_name
	panel.position = at
	panel.size = dimensions
	panel.texture = texture
	panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel.stretch_mode = TextureRect.STRETCH_SCALE
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

func make_label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", display_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.06, 0.05))
	label.add_theme_constant_override("outline_size", 5)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func set_elapsed(seconds: float) -> void:
	var total := maxi(0, int(seconds))
	timer_label.text = "%02d:%02d" % [int(total / 60), total % 60]

func set_health(health: float) -> void:
	health_bar.value = clampf(health, 0.0, 100.0)
