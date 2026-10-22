extends RefCounted

const UI_FONT = preload("res://assets/fonts/Fredoka-Variable.ttf")
const TITLE_FONT = preload("res://assets/fonts/LuckiestGuy-Regular.ttf")

static func display_font() -> FontVariation:
	var font := FontVariation.new()
	font.base_font = UI_FONT
	font.variation_embolden = 0.35
	font.spacing_glyph = 2
	return font

static func title_font() -> FontVariation:
	var font := FontVariation.new()
	font.base_font = TITLE_FONT
	font.spacing_glyph = 2
	return font
