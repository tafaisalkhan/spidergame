extends SceneTree

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	root.size = Vector2i(2400, 1080)
	await process_frame
	root.get_node("GameManager").start_bugs_mode()
	await process_frame
	await process_frame
	var game = current_scene
	game.finish_bugs_reveal()
	game.toggle_bugs_pause()
	assert(paused and game.bugs_pause_panel.visible)
	var menu_button: Button = game.bugs_pause_panel.get_child(0).get_node("MainMenuButton")
	var pressed := [false]
	menu_button.pressed.connect(func(): pressed[0] = true)
	var tap := InputEventScreenTouch.new()
	tap.position = menu_button.get_global_rect().get_center()
	tap.pressed = true
	root.push_input(tap, true)
	tap = InputEventScreenTouch.new()
	tap.position = menu_button.get_global_rect().get_center()
	tap.pressed = false
	root.push_input(tap, true)
	await process_frame
	assert(pressed[0], "Pause Main Menu button did not receive touch input")
	await process_frame
	assert(not paused and current_scene.scene_file_path == "res://scenes/main_menu.tscn")
	print("SPIDER_WARS_PAUSE_MENU_PASS")
	quit()
