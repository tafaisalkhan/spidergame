extends SceneTree

const TrapScene = preload("res://scenes/web_trap.tscn")

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	var game = TrapScene.instantiate()
	root.add_child(game)
	await process_frame
	assert(game.building)
	assert(game.ui_design.get_node_or_null("SpiderJoystick") == null)
	var bug: TrapBug = game.bugs[0]
	var tap := InputEventScreenTouch.new()
	tap.index = 0
	tap.pressed = true
	tap.position = game.get_canvas_transform() * bug.position
	game._unhandled_input(tap)
	var tap_release := InputEventScreenTouch.new()
	tap_release.index = 0
	tap_release.position = tap.position
	tap_release.pressed = false
	game._unhandled_input(tap_release)
	await process_frame
	assert(not game.building)
	assert(game.target_bug == bug)
	var starting_position: Vector2 = game.spider.position
	await create_timer(0.35).timeout
	assert(game.spider.position.distance_to(starting_position) > 30.0)
	var destination := 11
	var joint_tap := InputEventScreenTouch.new()
	joint_tap.index = 1
	joint_tap.pressed = true
	joint_tap.position = game.get_canvas_transform() * game.web_points[destination]
	game._unhandled_input(joint_tap)
	assert(game.destination_node == destination and game.target_bug == null)
	assert(game.plan_auto_path().back() == destination)
	var snack: TrapBug
	for candidate in game.bugs:
		if candidate.active:
			snack = candidate
			break
	assert(snack != null)
	snack.position = game.spider.position + Vector2(10, 0)
	game._process(0.016)
	assert(not snack.active and game.player_eat_remaining > 0.0)
	assert(game.destination_node == destination)
	game.clear_eating()
	var travel_start: Vector2 = game.spider.position
	for candidate in game.bugs:
		if candidate.active:
			candidate.position = Vector2(-10000, -10000)
			snack = candidate
	assert(snack.active)
	snack.position = travel_start + Vector2(240, 0)
	snack.sprite.position = Vector2(0, -16)
	snack.web_cut_edges.append(0)
	game.edge_active[0] = false
	assert(game.required_bug_repair_edge(snack) == 0)
	var travel_end := travel_start + Vector2(480, 0)
	assert(travel_end.distance_to(snack.position) > game.player_catch_radius())
	game.catch_bug_passed_on_way(travel_start, travel_end)
	assert(not snack.active and game.player_eat_remaining > 0.0)
	assert(game.destination_node == destination)
	print("SPIDER_WARS_PLAYER_INPUT_PASS")
	game.free()
	quit()
