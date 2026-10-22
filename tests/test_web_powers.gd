extends SceneTree

const TrapScene = preload("res://scenes/web_trap.tscn")

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	var game = TrapScene.instantiate()
	root.add_child(game)
	await process_frame
	game.finish_construction()
	assert(game.cut_charges == 2 and game.build_charges == 2)
	var bug: TrapBug = game.bugs[0]
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = game.get_canvas_transform() * bug.position
	game._unhandled_input(touch)
	assert(game.target_bug == bug)
	var planned: Array[int] = game.plan_auto_path()
	assert(not planned.is_empty())
	var starting_distance: float = game.spider.position.distance_to(bug.position)
	for step in 180:
		game.move_spider_on_web(0.016)
	assert(game.spider.position.distance_to(bug.position) < starting_distance)
	Input.action_press("ui_right")
	game._process(0.016)
	Input.action_release("ui_right")
	assert(game.target_bug == null)

	game.restart()
	await process_frame
	game.finish_construction()
	var crossing: int = game.edge_index(0, 2)
	game.toggle_trail_cut()
	game.spider.desired_direction = Vector2.UP
	for step in 100:
		game.move_spider_on_web(0.016)
		if game.spider_node == 2:
			break
	assert(game.spider_node == 2)
	assert(not game.edge_active[crossing])
	assert(game.cut_charges == 1 and not game.cut_button.get_node("RewardAdButton").visible)
	game.cut_edge(0, 1)
	game.cut_edge(1, 1)
	assert(game.cut_charges == 0 and not game.trail_cut_enabled)
	assert(game.cut_button.get_node("RewardAdButton").visible)
	assert(not game.cut_edge(2, 1) and game.edge_active[2])

	game.restart()
	await process_frame
	game.finish_construction()
	game.cut_edge(crossing)
	game.toggle_weave_mode()
	var gap: Vector2 = game.web_position(0, 2, 0.5)
	var gap_touch := InputEventScreenTouch.new()
	gap_touch.pressed = true
	gap_touch.position = game.get_canvas_transform() * gap
	game._unhandled_input(gap_touch)
	assert(game.selected_repair_edge == crossing and not game.weave_mode)
	game.move_spider_on_web(0.016)
	assert(game.player_repair_edge == crossing and game.build_charges == 1)
	game.move_spider_on_web(game.REBUILD_TIME)
	assert(game.edge_active[crossing] and game.selected_repair_edge == -1)
	assert(game.build_charges == 1)

	game.restart()
	await process_frame
	game.finish_construction()
	for pair in [Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 3), Vector2i(2, 14)]:
		game.edge_active[game.edge_index(pair.x, pair.y)] = false
	game.destination_node = 2
	assert(game.plan_auto_path() == [0, 2])
	game.move_spider_on_web(0.016)
	assert(game.player_repair_edge == crossing and game.build_charges == 1)
	assert(not game.weave_button.get_node("RewardAdButton").visible)
	game.move_spider_on_web(game.REBUILD_TIME)
	assert(game.edge_active[crossing] and game.player_repair_edge == -1)
	for step in 180:
		game.move_spider_on_web(0.016)
		if game.spider_node == 2:
			break
	assert(game.spider_node == 2 and game.destination_node == 2)
	game.restart()
	await process_frame
	game.finish_construction()
	for pair in [Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 3), Vector2i(2, 14)]:
		game.cut_edge(game.edge_index(pair.x, pair.y))
	var unreachable_bug: TrapBug = game.bugs[0]
	unreachable_bug.route = [2, 14]
	unreachable_bug.position = game.web_points[2]
	game.target_bug = unreachable_bug
	game.build_charges = 0
	game.update_power_buttons()
	assert(game.plan_auto_path().is_empty())
	game.move_spider_on_web(0.016)
	assert(game.player_repair_edge == -1 and game.spider.position == game.WEB_CENTER)

	game.restart()
	await process_frame
	game.finish_construction()
	var new_from := -1
	var new_to := -1
	for a in range(1, 13):
		for b in range(13, 25):
			if game.valid_new_link(a, b):
				new_from = a
				new_to = b
				break
		if new_from >= 0:
			break
	assert(new_from >= 0 and game.edge_index(new_from, new_to) == -1)
	game.toggle_weave_mode()
	var first_tap := InputEventScreenTouch.new()
	first_tap.pressed = true
	first_tap.position = game.get_canvas_transform() * game.web_points[new_from]
	game._unhandled_input(first_tap)
	assert(game.weave_start_node == new_from)
	var second_tap := InputEventScreenTouch.new()
	second_tap.pressed = true
	second_tap.position = game.get_canvas_transform() * game.web_points[new_to]
	game._unhandled_input(second_tap)
	assert(game.selected_new_link == Vector2i(new_from, new_to))
	for step in 120:
		game.move_spider_on_web(0.016)
		if game.player_new_link_progress >= 0.0:
			break
	assert(game.player_new_link_progress >= 0.0 and game.build_charges == 1)
	game.move_spider_on_web(game.REBUILD_TIME)
	assert(game.edge_index(new_from, new_to) >= 0)
	assert(game.edge_active[game.edge_index(new_from, new_to)])
	game.restart()
	await process_frame
	assert(game.edge_index(new_from, new_to) == -1)
	print("SPIDER_WARS_WEB_POWERS_PASS")
	game.free()
	quit()
