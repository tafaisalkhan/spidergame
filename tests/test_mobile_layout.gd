extends SceneTree

const FIRST_HUNT = preload("res://scenes/first_hunt.tscn")

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	for dimensions in [Vector2i(2400, 1080), Vector2i(1600, 720)]:
		var viewport := SubViewport.new()
		viewport.size = dimensions
		root.add_child(viewport)
		var game = FIRST_HUNT.instantiate()
		viewport.add_child(game)
		await process_frame
		game.finish_intro_reveal()
		var screen := viewport.get_visible_rect()
		assert(game.ui_design.global_position.x >= 0.0)
		assert(not game.shop_button.visible)
		assert(visible_inside(screen, game.cut_button))
		assert(visible_inside(screen, game.weave_button))
		assert(visible_inside(screen, game.power_toggle_button))
		assert(is_equal_approx(game.game_hud.global_position.y, game.HUD_TOP_MARGIN * game.ui_design.scale.y))
		assert(game.cut_button.position.x == 24.0 and game.weave_button.position.x == 24.0)
		assert(game.cut_button.position.y < game.weave_button.position.y)
		assert(game.power_toggle_button.position.y < game.boost_button.position.y)
		assert(game.power_toggle_button.text == "")
		assert(game.game_hud.get_node("BugPanel") is TextureRect)
		assert(game.game_hud.get_node("TimerPanel") is TextureRect)
		assert(game.game_hud.level_label.get_theme_font_size("font_size") == 62)
		assert(game.ui_design.get_node_or_null("ZoomInButton") == null)
		assert(game.ui_design.get_node_or_null("ZoomOutButton") == null)
		assert(is_equal_approx(game.camera.zoom.x, game.COMPACT_CAMERA_ZOOM))
		game.change_camera_zoom(game.CAMERA_ZOOM_STEP)
		assert(game.camera.zoom.x > game.COMPACT_CAMERA_ZOOM)
		game.change_camera_zoom(-game.CAMERA_ZOOM_STEP)
		game.toggle_power_hud()
		assert(visible_inside(screen, game.power_toggle_button))
		assert(is_equal_approx(game.power_toggle_button.position.y + game.power_toggle_button.size.y * 0.5, 540.0))
		assert(game.power_toggle_icon.texture == game.POWERS_SHOW_ICON)
		game.toggle_power_hud()
		game.winner = 1
		game.finish_match()
		assert(visible_inside(screen, game.result_panel))
		assert(game.result_dimmer.size == screen.size)
		viewport.free()
	print("SPIDER_WARS_MOBILE_LAYOUT_PASS")
	quit()

func visible_inside(screen: Rect2, control: Control) -> bool:
	var area := Rect2(control.global_position, control.size * control.get_global_transform().get_scale())
	return screen.encloses(area)
