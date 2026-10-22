extends SceneTree

const SPLASH = preload("res://scenes/splash.tscn")

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	var splash = SPLASH.instantiate()
	root.add_child(splash)
	current_scene = splash
	splash.start_game()
	await process_frame
	await process_frame
	assert(current_scene != null and current_scene.name == "MainMenu")
	set_meta("first_hunt_level", 5)
	set_meta("first_hunt_spider_power", 12)
	root.get_node("GameManager").start_first_hunt()
	await process_frame
	var game = current_scene
	assert(game != null and game.intro_level == 1)
	assert(game.intro_reveal_active and game.rival_active and game.rival.visible)
	game.finish_intro_reveal()
	assert(not game.building)
	var start_position: Vector2 = game.spider.position
	Input.action_press("ui_up")
	await create_timer(0.8).timeout
	Input.action_release("ui_up")
	assert(game.spider.position.distance_to(start_position) > 1.0)
	print("SPIDER_TERRITORY_STARTUP_PLAYABLE_PASS")
	quit()
