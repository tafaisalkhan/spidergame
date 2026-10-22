extends SceneTree

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	root.size = Vector2i(2400, 1080)
	await process_frame
	var manager = root.get_node("GameManager")
	var previous_points: Array[Vector2] = []
	var previous_spawns: Array[int] = []
	var previous_time_limit := INF
	for level in [1, 2, 3, 50, 1000]:
		manager.bugs_mode = true
		manager.advance_first_hunt(level, 0)
		await process_frame
		await process_frame
		var game = current_scene
		assert(game.bugs_mode and game.intro_level == level)
		assert(game.base_spider_speed == (175.0 if level == 1 else (185.0 if level <= 5 else 225.0)))
		var time_limit: float = game.bugs_mode_time_limit()
		assert(time_limit < previous_time_limit and time_limit > 10.0)
		previous_time_limit = time_limit
		var expected_bugs: int = {1: 4, 2: 5, 3: 5, 50: 12, 1000: 12}[level]
		assert(game.web_points.size() == {1: 12, 2: 20, 3: 30, 50: 72, 1000: 72}[level])
		assert(game.web_edges.size() == (20 if level == 1 else game.bugs_mode_initial_links))
		if level > 1:
			assert(game.web_edges.size() > 20)
		assert(game.bugs.size() == expected_bugs and game.bugs_mode_spawn_nodes.size() == expected_bugs)
		assert(game.intro_goal() == expected_bugs)
		var strong_bugs: Array = game.bugs.filter(func(bug): return bug.strong)
		assert(strong_bugs.size() == mini(3, expected_bugs - 4))
		for bug_index in game.bugs.size():
			var bug = game.bugs[bug_index]
			assert(bug.active and bug.stuck and bug.position == game.web_points[bug.route[0]])
			assert(bug.glue_duration == game.bugs_mode_release_time(game.bugs_mode_release_rank(bug.route[0])))
			assert(bug.release_timer_label.visible and not bug.health_bar.visible)
		var ranked_bugs: Array = game.bugs.duplicate()
		ranked_bugs.sort_custom(func(a, b): return a.position.distance_squared_to(game.spider.position) < b.position.distance_squared_to(game.spider.position))
		for rank in ranked_bugs.size():
			assert(ranked_bugs[rank].glue_duration == 20.0 + 5.0 * rank)
		if not previous_points.is_empty():
			assert(game.web_points != previous_points)
			assert(game.bugs_mode_spawn_nodes != previous_spawns or game.web_points.size() != previous_points.size())
		previous_points.assign(game.web_points)
		previous_spawns.assign(game.bugs_mode_spawn_nodes)
		var visible_size: Vector2 = game.get_viewport().get_visible_rect().size
		var bounds: Rect2 = game.hunt_bounds()
		assert(game.intro_reveal_active and game.camera.position == game.WEB_CENTER)
		assert(is_equal_approx(game.camera_zoom, 1.0 / game.bugs_mode_arena_scale()))
		for bug in game.bugs:
			assert(game.get_viewport().get_visible_rect().has_point(game.get_canvas_transform() * bug.position))
		assert(bounds.size.x > visible_size.x and bounds.size.y > visible_size.y)
		assert(game.rival_count_for_level() == 0 and not game.rival_active and not game.rival.visible)
		assert(game.rival_node == game.rival_mode_rival_start)
		game.finish_bugs_reveal()
		assert(is_equal_approx(game.camera_zoom, 1.0 / game.bugs_mode_arena_scale()))
		if level > 1:
			game.set_camera_zoom(0.01)
			assert(is_equal_approx(game.camera_zoom, 1.0 / game.bugs_mode_arena_scale()))
			if level == 2:
				var touch_a := InputEventScreenTouch.new()
				touch_a.index = 0
				touch_a.position = Vector2(500, 500)
				touch_a.pressed = true
				game._unhandled_input(touch_a)
				var touch_b := InputEventScreenTouch.new()
				touch_b.index = 1
				touch_b.position = Vector2(700, 500)
				touch_b.pressed = true
				game._unhandled_input(touch_b)
				var pinch_drag := InputEventScreenDrag.new()
				pinch_drag.index = 1
				pinch_drag.position = Vector2(800, 500)
				game._unhandled_input(pinch_drag)
				assert(game.camera_zoom > 1.0 / game.bugs_mode_arena_scale())
				touch_b.pressed = false
				game._unhandled_input(touch_b)
				touch_a.pressed = false
				game._unhandled_input(touch_a)
				assert(game.destination_node < 0 and game.tap_destination_edge < 0)
				game.set_camera_zoom(1.4)
				var camera_before_pan: Vector2 = game.camera.position
				touch_a.pressed = true
				touch_b.pressed = true
				touch_a.position = Vector2(500, 500)
				touch_b.position = Vector2(700, 500)
				game._unhandled_input(touch_a)
				game._unhandled_input(touch_b)
				pinch_drag.index = 0
				pinch_drag.position = Vector2(400, 500)
				game._unhandled_input(pinch_drag)
				pinch_drag.index = 1
				pinch_drag.position = Vector2(600, 500)
				game._unhandled_input(pinch_drag)
				assert(game.camera.position.x > camera_before_pan.x)
				var camera_after_pinch_pan: Vector2 = game.camera.position
				touch_a.pressed = false
				touch_b.pressed = false
				game._unhandled_input(touch_b)
				game._unhandled_input(touch_a)
				touch_a.pressed = true
				touch_a.position = Vector2(500, 500)
				game._unhandled_input(touch_a)
				pinch_drag.index = 0
				pinch_drag.position = Vector2(600, 500)
				game._unhandled_input(pinch_drag)
				assert(game.camera.position.x < camera_after_pinch_pan.x)
				touch_a.pressed = false
				game._unhandled_input(touch_a)
				assert(game.destination_node < 0 and game.tap_destination_edge < 0)
				game.change_camera_zoom(0.2)
				assert(game.bugs_camera_offset == Vector2.ZERO)
				game.bugs_camera_offset = Vector2(180.0, 0.0)
				game.update_camera_position()
				game.reset_camera_to_player()
				assert(is_equal_approx(game.camera_zoom, 1.0 / game.bugs_mode_arena_scale()))
				assert(game.bugs_camera_offset == Vector2.ZERO)
				game.set_camera_zoom(1.0 / game.bugs_mode_arena_scale())
				var bug_touch := InputEventScreenTouch.new()
				bug_touch.index = 0
				bug_touch.position = game.get_canvas_transform() * game.bugs[0].position
				bug_touch.pressed = true
				game._unhandled_input(bug_touch)
				bug_touch.pressed = false
				game._unhandled_input(bug_touch)
				assert(game.target_bug == game.bugs[0])
				game.cancel_auto_navigation()
			game.set_camera_zoom(1.0)
			game.spider.position = game.web_points[0]
			game.update_camera_position()
			var upper_left: Vector2 = game.camera.position
			game.spider.position = game.web_points[-1]
			game.update_camera_position()
			assert(game.camera.position.x > upper_left.x and game.camera.position.y > upper_left.y)
		var original_points: Array[Vector2] = []
		original_points.assign(game.web_points)
		var original_spawns: Array[int] = []
		original_spawns.assign(game.bugs_mode_spawn_nodes)
		game.restart()
		assert(game.web_points == original_points and game.bugs_mode_spawn_nodes == original_spawns)
		if game.intro_reveal_active:
			game.finish_bugs_reveal()
		if level == 2:
			var strong_bug = game.bugs.filter(func(bug): return bug.strong)[0]
			var normal_bug = game.bugs.filter(func(bug): return not bug.strong)[0]
			strong_bug._process(strong_bug.glue_duration + 0.1)
			assert(strong_bug.escaping_flight and normal_bug.stuck)
			game.caught_count = expected_bugs - 1
			game.escaped_count = 1
			game.check_round_complete()
			assert(game.finished and game.bugs_mode_star_count() == 2)
			assert(game.result_note.text.begins_with("Caught: 4 / 5"))
		if level == 1000:
			game.caught_count = expected_bugs
			game.check_round_complete()
			assert(game.finished and game.next_button.visible)
			assert(manager.bugs_next_level == 1001)
			game.next_button.pressed.emit()
			await process_frame
			await process_frame
			assert(current_scene.bugs_mode and current_scene.intro_level == 1001)
	manager.start_bugs_mode()
	await process_frame
	await process_frame
	assert(current_scene.bugs_mode and current_scene.intro_level == 1001 and manager.current_level == 1001)
	print("SPIDER_WARS_BUGS_LEVELS_PASS")
	quit()
