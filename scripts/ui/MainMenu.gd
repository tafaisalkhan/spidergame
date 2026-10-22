extends "res://scripts/ui/MenuScreenBase.gd"

const PLAY_ICON = preload("res://assets/ui/menu_play.svg")
const RIVAL_ICON = preload("res://assets/ui/menu_rival.svg")
const SETTINGS_ICON = preload("res://assets/ui/menu_settings.svg")
const STORE_ICON = preload("res://assets/ui/reward-coin.png")

func screen_title() -> String:
	return "CHOOSE YOUR HUNT"

func build_content() -> void:
	var bugs_button := make_button("BUGS MODE", Vector2(990, 265), 128.0, PLAY_ICON)
	bugs_button.name = "BugsModeButton"
	bugs_button.pressed.connect(get_node("/root/GameManager").start_bugs_mode)
	var rival_button := make_button("RIVAL MODE", Vector2(990, 420), 128.0, RIVAL_ICON)
	rival_button.name = "RivalLevelsButton"
	rival_button.pressed.connect(get_node("/root/GameManager").start_rival_levels)
	var store_button := make_button("STORE", Vector2(990, 575), 128.0, STORE_ICON)
	store_button.name = "StoreButton"
	store_button.pressed.connect(open_scene.bind("res://scenes/shop.tscn"))
	var store_icon := TextureRect.new()
	store_icon.texture = STORE_ICON
	store_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	store_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	store_icon.position = Vector2(30, 27)
	store_icon.size = Vector2(74, 74)
	store_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	store_button.add_child(store_icon)
	make_button("SETTINGS", Vector2(990, 730), 128.0, SETTINGS_ICON).pressed.connect(open_scene.bind("res://scenes/settings.tscn"))
	status_label.text = "Hunt bugs or face rival spiders."
