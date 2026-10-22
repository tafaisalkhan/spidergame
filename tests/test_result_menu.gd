extends SceneTree

const FIRST_HUNT = preload("res://scenes/first_hunt.tscn")

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1600, 720)
	viewport.handle_input_locally = true
	root.add_child(viewport)
	var game = FIRST_HUNT.instantiate()
	viewport.add_child(game)
	await process_frame
	if game.intro_reveal_active:
		game.finish_intro_reveal()
	game.winner = 2
	game.finish_match()
	await create_timer(0.6).timeout
	assert(game.result_menu_button.visible)
	assert(game.result_menu_button.icon != null)
	var point: Vector2 = game.result_menu_button.get_global_rect().get_center()
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = point
	viewport.push_input(down, true)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.position = point
	viewport.push_input(up, true)
	await process_frame
	await process_frame
	assert(current_scene != null and current_scene.scene_file_path == "res://scenes/main_menu.tscn")
	print("SPIDER_WARS_RESULT_MENU_PASS")
	quit()
