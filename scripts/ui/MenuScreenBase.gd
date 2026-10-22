extends Control

const ART = preload("res://assets/background/garden.png")
const STAR = preload("res://assets/ui/victory-star.png")
const COIN = preload("res://assets/ui/reward-coin.png")
const GameFont = preload("res://scripts/ui/GameFont.gd")

var design: Control
var backdrop_art: TextureRect
var backdrop_shade: ColorRect
var status_label: Label
var display_font: FontVariation

func _ready() -> void:
	display_font = GameFont.display_font()
	build_shell(screen_title())
	build_content()
	get_viewport().size_changed.connect(update_layout)
	update_layout()

func screen_title() -> String:
	return ""

func build_content() -> void:
	pass

func build_shell(heading_text: String) -> void:
	design = Control.new()
	design.name = "Design"
	design.size = Vector2(1920, 1080)
	add_child(design)
	backdrop_art = TextureRect.new()
	backdrop_art.texture = ART
	backdrop_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop_art.size = design.size
	backdrop_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	design.add_child(backdrop_art)
	backdrop_shade = ColorRect.new()
	backdrop_shade.color = Color(0.015, 0.055, 0.05, 0.66)
	backdrop_shade.size = design.size
	backdrop_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	design.add_child(backdrop_shade)
	var title := make_label("SPIDER TERRITORY", 83, Color(1.0, 0.84, 0.42))
	title.add_theme_font_override("font", GameFont.title_font())
	title.position = Vector2(70, 55)
	title.size = Vector2(1780, 160)
	design.add_child(title)
	var heading := make_label(heading_text, 48, Color(0.86, 1.0, 0.78))
	heading.add_theme_font_override("font", GameFont.title_font())
	heading.position = Vector2(85, 245)
	heading.size = Vector2(830, 75)
	design.add_child(heading)
	status_label = make_label("", 32, Color(1.0, 0.86, 0.52))
	status_label.position = Vector2(810, 880)
	status_label.size = Vector2(1000, 100)
	design.add_child(status_label)

func make_label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_font_override("font", display_font)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.01, 0.08, 0.07))
	label.add_theme_constant_override("outline_size", 7)
	label.add_theme_color_override("font_shadow_color", Color(0.005, 0.025, 0.02, 0.85))
	label.add_theme_constant_override("shadow_offset_y", 5)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func make_button(value: String, at: Vector2, height := 132.0, _icon: Texture2D = STAR) -> Button:
	var button := Button.new()
	button.text = value
	button.position = at
	button.size = Vector2(760, height)
	button.add_theme_font_size_override("font_size", 50)
	button.add_theme_font_override("font", GameFont.title_font())
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", Color(1.0, 0.91, 0.67))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color(0.67, 1.0, 0.73))
	button.add_theme_color_override("font_disabled_color", Color(0.65, 0.70, 0.63))
	button.add_theme_color_override("font_outline_color", Color(0.01, 0.08, 0.06))
	button.add_theme_constant_override("outline_size", 9)
	design.add_child(button)
	return button

func open_scene(path: String) -> void:
	get_node("/root/GameManager").show_scene(path)

func update_layout() -> void:
	var viewport_size := get_viewport_rect().size
	var factor: float = minf(viewport_size.x / 1920.0, viewport_size.y / 1080.0)
	design.scale = Vector2.ONE * factor
	design.position = (viewport_size - design.size * factor) * 0.5
	var background_width := maxf(1920.0, viewport_size.x / factor)
	for backdrop in [backdrop_art, backdrop_shade]:
		backdrop.position.x = (1920.0 - background_width) * 0.5
		backdrop.size = Vector2(background_width, 1080.0)
