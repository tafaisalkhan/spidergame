extends SceneTree

const MAIN = preload("res://scenes/main_menu.tscn")

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	var manager = root.get_node("GameManager")
	var mobile_viewport := SubViewport.new()
	mobile_viewport.size = Vector2i(1600, 720)
	root.add_child(mobile_viewport)
	var mobile_menu = MAIN.instantiate()
	mobile_viewport.add_child(mobile_menu)
	await process_frame
	var visible_buttons := 0
	for item in mobile_menu.design.get_children():
		if item is Button:
			visible_buttons += 1
			var box := Rect2(item.global_position, item.size * item.get_global_transform().get_scale())
			assert(mobile_viewport.get_visible_rect().encloses(box))
	assert(visible_buttons == 4)
	mobile_viewport.free()
	var menu = MAIN.instantiate()
	root.add_child(menu)
	await process_frame
	var rival_button: Button = menu.design.get_node("RivalLevelsButton")
	assert(rival_button.text == "RIVAL MODE")
	rival_button.pressed.emit()
	menu.queue_free()
	await process_frame
	await process_frame
	assert(manager.rival_levels)
	var rival_level_one_points: Array[Vector2] = []
	var rival_level_one_edges: Array[Vector2i] = []
	for level in range(1, 8):
		var game = current_scene
		assert(game != null and game.intro_mode and game.rival_levels)
		assert(game.intro_level == level)
		assert(is_equal_approx(game.camera_zoom, 1.0 / game.bugs_mode_arena_scale()))
		var expected_rivals: int = mini(4, 1 + (level - 1) / 2)
		assert(game.rival_count_for_level() == expected_rivals)
		assert(game.intro_initial_bug_count() == mini(14, 3 + level))
		assert(game.rival_active and game.all_active_rivals().size() == expected_rivals)
		assert(not game.spider.health_bar.visible and not game.rival.health_bar.visible)
		for hunter in game.extra_rivals:
			assert(not hunter.spider.health_bar.visible)
		assert(game.rival_boost_charges == 0)
		assert(game.rival_cut_charges == 0)
		assert(game.rival_stun_charges == 0)
		assert(game.spider.visual.scale == game.rival.visual.scale)
		assert(game.spider.visual.scale.x >= 0.30)
		assert(game.spider.get_node("BugCountLabel").text == "0")
		assert(game.rival.get_node("BugCountLabel").text == "0")
		assert(game.spider.position.y > game.rival.position.y)
		assert(game.rival_ready_audio != null and game.rival_ready_audio.stream == game.RIVAL_READY_SOUND)
		assert(game.player_ready_audio != null and game.player_ready_audio.stream == game.PLAYER_READY_SOUND)
		assert(game.rival_walking_audio != null and game.rival_walking_audio.stream == game.SPIDER_WALKING_SOUND)
		assert(game.bugs_item_rail != null and game.timer_button != null and game.bugs_pause_button != null)
		assert(game.timer_button.visible and game.cut_button.visible and game.weave_button.visible and game.stun_button.visible and game.boost_button.visible)
		for power_button in [game.cut_button, game.weave_button, game.timer_button, game.stun_button, game.boost_button]:
			var ad_button: Button = power_button.get_node("RewardAdButton")
			assert(ad_button.get_rect() == Rect2(Vector2.ZERO, power_button.size))
			assert(Rect2(Vector2.ZERO, power_button.size).encloses(ad_button.get_rect()))
		assert(game.camera.position.is_equal_approx(game.rival.position))
		var dark_backdrops := 0
		for child in game.get_children():
			if child is Sprite2D and child.z_index == -10:
				assert(child.material is ShaderMaterial and child.material.shader == game.DARK_GARDEN_SHADER)
				dark_backdrops += 1
		assert(dark_backdrops > 0)
		assert(game.bugs.size() > 0)
		for bug in game.bugs:
			assert(bug.arriving and not bug.active and bug.flight_sounds_enabled)
			assert(bug.sprite.texture == game.BUGS_MODE_TEXTURES[bug.species_id])
		assert(game.web_points.size() == game.generated_grid_columns * game.generated_grid_rows)
		assert(game.hunt_bounds().size.is_equal_approx(game.get_viewport().get_visible_rect().size * game.bugs_mode_arena_scale()))
		assert(game.spider_node == game.rival_mode_spider_start)
		assert(game.rival_node == game.rival_mode_rival_start)
		for hunter in game.extra_rivals:
			assert(hunter.home >= 0 and hunter.home < game.web_points.size())
			assert(game.hunt_bounds().has_point(hunter.spider.position))
		if level == 1:
			rival_level_one_points.assign(game.web_points)
			rival_level_one_edges.assign(game.web_edges)
		if game.intro_reveal_active:
			if level == 1:
				await create_timer(0.9).timeout
				assert(not game.rival_ready_audio.playing)
			game.finish_intro_reveal()
			assert(game.player_ready_audio.playing)
			assert(game.camera.position.is_equal_approx(game.spider.position))
		if level == 1:
			game.set_camera_zoom(1.0)
			game.reset_camera_to_player()
			assert(is_equal_approx(game.camera_zoom, 1.1 / game.bugs_mode_arena_scale()))
			game.set_camera_zoom(1.0 / game.bugs_mode_arena_scale())
		if level == 1:
			game.rival_caught_count = 1
			game.update_status()
			assert(game.rival_ready_audio.playing)
			game.rival_caught_count = 0
			game.update_status()
			assert(not game.rival_ready_audio.playing)
		if level == 6:
			assert(game.rival_count_battle() and not game.rivals_can_respawn())
			assert(game.spider.get_node("BugCountLabel").text == "0")
			assert(game.rival.get_node("BugCountLabel").text == "0")
			var fixed_size: Vector2 = game.spider.visual.scale
			var landed_bug: TrapBug = game.bugs[0]
			landed_bug._process(1.8)
			game.catch_bug(landed_bug, 1)
			game.player_eat_remaining = 0.0
			game.finish_eating(1)
			assert(game.caught_count == 1 and game.spider.visual.scale == fixed_size)
			assert(game.spider.get_node("BugCountLabel").text == "1")
			var fixed_rival_size: Vector2 = game.rival.visual.scale
			var rival_bug: TrapBug = game.bugs[1]
			rival_bug._process(1.8)
			game.catch_bug(rival_bug, 2)
			game.rival_eat_remaining = 0.0
			game.finish_eating(2)
			assert(game.rival_caught_count == 1 and game.rival.visual.scale == fixed_rival_size)
			var hunter = game.extra_rivals[0]
			var fixed_hunter_size: Vector2 = hunter.spider.visual.scale
			game.extra_rival_catch_bug(hunter, game.bugs[2])
			assert(hunter.bugs_eaten == 1 and hunter.spider.visual.scale == fixed_hunter_size)
			assert(hunter.spider.get_node("BugCountLabel").text == "1")
			game.rival_caught_count = 2
			game.update_status()
			assert(game.rival.get_node("BugCountLabel").text == "2")
			assert(game.rival_can_eat_player(game.rival) and not game.player_can_eat_rival(game.rival))
			game.rival_caught_count = 1
			assert(not game.rival_can_eat_player(game.rival) and not game.player_can_eat_rival(game.rival))
			game.set_rival_walking_sound(true)
			assert(game.rival_walking_audio.playing)
			game.set_rival_walking_sound(false)
			assert(not game.rival_walking_audio.playing)
			game.rival_caught_count = 2
			game.resolve_solo_collision()
			assert(game.finished and game.winner == 2 and not game.player_active)
			game.restart()
			game.finish_intro_reveal()
			var fight_size: Vector2 = game.spider.visual.scale
			game.caught_count = 2
			game.rival_caught_count = 1
			game.player_ready_audio.stop()
			game.resolve_solo_collision()
			assert(not game.rival_active and game.spider.visual.scale == fight_size)
			assert(game.player_rival_eat_remaining > 0.0 and not game.player_ready_audio.playing)
			game._physics_process(game.RIVAL_EAT_DURATION + 0.01)
			assert(game.player_ready_audio.playing)
			assert(not game.finished and not game.rivals_can_respawn())
			game.restart()
			game.finish_intro_reveal()
		if level == 1:
			var strand_tap_edge := -1
			var strand_tap_point := Vector2.ZERO
			for index in game.web_edges.size():
				var edge: Vector2i = game.web_edges[index]
				var midpoint: Vector2 = game.web_position(edge.x, edge.y, 0.5)
				if game.nearest_bug_at(midpoint) == null and game.nearest_anchor_at(midpoint, 70.0) < 0 and game.nearest_edge_at(midpoint, true) == index:
					strand_tap_edge = index
					strand_tap_point = midpoint
					break
			assert(strand_tap_edge >= 0)
			var strand_tap := InputEventMouseButton.new()
			strand_tap.button_index = MOUSE_BUTTON_LEFT
			strand_tap.pressed = true
			strand_tap.position = game.get_canvas_transform() * strand_tap_point
			var cut_charges_before: int = game.cut_charges
			game._unhandled_input(strand_tap)
			assert(game.edge_active[strand_tap_edge] and game.cut_charges == cut_charges_before)
			assert(game.tap_destination_edge == strand_tap_edge)
			game.cancel_auto_navigation()
			game.toggle_trail_cut()
			game._unhandled_input(strand_tap)
			assert(not game.edge_active[strand_tap_edge] and game.cut_charges == cut_charges_before - 1)
			assert(not game.trail_cut_enabled)
			var touch_one := InputEventScreenTouch.new()
			touch_one.index = 0
			touch_one.position = Vector2(600, 450)
			touch_one.pressed = true
			game._unhandled_input(touch_one)
			var touch_two := InputEventScreenTouch.new()
			touch_two.index = 1
			touch_two.position = Vector2(800, 450)
			touch_two.pressed = true
			game._unhandled_input(touch_two)
			var pinch := InputEventScreenDrag.new()
			pinch.index = 1
			pinch.position = Vector2(700, 450)
			game._unhandled_input(pinch)
			assert(is_equal_approx(game.camera_zoom, 1.0 / game.bugs_mode_arena_scale()))
			pinch.position = Vector2(1000, 450)
			game._unhandled_input(pinch)
			assert(game.camera_zoom > 1.0 / game.bugs_mode_arena_scale())
			touch_one.pressed = false
			game._unhandled_input(touch_one)
			touch_two.pressed = false
			game._unhandled_input(touch_two)
			var landing_bug: TrapBug = game.bugs[0]
			game.target_bug = landing_bug
			assert(game.plan_auto_path().back() == landing_bug.route[0])
			game._process(0.01)
			assert(game.target_bug == landing_bug)
			landing_bug._process(0.5)
			assert(landing_bug.flight_audio != null and landing_bug.flight_audio.playing)
			landing_bug._process(1.3)
			assert(landing_bug.active and landing_bug.stuck and not landing_bug.arriving)
			assert(landing_bug.visible and landing_bug.motion_style == TrapBug.MotionStyle.CRAWL)
			assert(not landing_bug.flight_audio.playing)
			assert(landing_bug.stuck_audio != null and landing_bug.stuck_audio.playing)
			var timed_bug: TrapBug = game.bugs[2]
			timed_bug._process(1.8)
			var previous_time := timed_bug.glue_remaining
			var previous_charges: int = game.timer_charges
			game.use_timer_power()
			assert(is_equal_approx(timed_bug.glue_remaining, previous_time + 5.0))
			assert(game.timer_charges == previous_charges - 1)
			var player_size: float = game.spider.visual.scale.x
			game.catch_bug(landing_bug, 1)
			game.player_eat_remaining = 0.0
			game.finish_eating(1)
			assert(game.spider.visual.scale.x > player_size)
			assert(game.spider.get_node("BugCountLabel").text == "1")
			var rival_bug: TrapBug = game.bugs[1]
			rival_bug._process(1.8)
			var rival_size: float = game.rival.visual.scale.x
			game.catch_bug(rival_bug, 2)
			game.rival_eat_remaining = 0.0
			game.finish_eating(2)
			assert(game.rival.visual.scale.x > rival_size)
			assert(game.rival.get_node("BugCountLabel").text == "1")
		if level < 7:
			game.player_power = level * 3
			game.caught_count = game.intro_goal()
			game.check_round_complete()
			assert(game.finished and game.rival_active)
			assert(game.next_button.visible)
			game.next_button.pressed.emit()
			await process_frame
			await process_frame
			assert(current_scene.player_power == level * 3)
	manager.advance_first_hunt(1000, 0)
	await process_frame
	await process_frame
	assert(manager.current_level == 1000 and current_scene.rival_levels)
	assert(current_scene.intro_goal() <= 16)
	assert(current_scene.web_points.size() == 72)
	assert(current_scene.rival_count_for_level() == 4)
	assert(current_scene.rival_count_battle())
	current_scene.rival_caught_count = current_scene.intro_goal()
	current_scene.check_round_complete()
	assert(current_scene.finished and current_scene.winner == 2)
	manager.advance_first_hunt(1000, 0)
	await process_frame
	await process_frame
	for actor in current_scene.all_active_rivals():
		if actor == current_scene.rival:
			current_scene.rival_active = false
		else:
			for hunter in current_scene.extra_rivals:
				if hunter.spider == actor:
					hunter.active = false
	current_scene.check_round_complete()
	assert(current_scene.finished and current_scene.winner == 1)
	assert(current_scene.next_button.visible and manager.rival_next_level == 1001)
	manager.advance_first_hunt(1001, 0)
	await process_frame
	await process_frame
	assert(manager.current_level == 1001 and current_scene.intro_level == 1001)
	manager.start_rival_levels()
	await process_frame
	await process_frame
	assert(manager.current_level == 1001 and current_scene.intro_level == 1001)
	manager.start_first_hunt()
	await process_frame
	await process_frame
	assert(not manager.rival_levels)
	assert(current_scene.intro_level == 1 and current_scene.rival_active)
	assert(current_scene.rival_count_for_level() == 1)
	manager.start_bugs_mode()
	await process_frame
	await process_frame
	assert(manager.bugs_mode and current_scene.bugs_mode)
	assert(current_scene.web_edges == rival_level_one_edges)
	assert(current_scene.web_points.size() == rival_level_one_points.size())
	for node in current_scene.web_points.size():
		assert(rival_level_one_points[node].is_equal_approx(current_scene.web_points[node]))
	assert(current_scene.rival_count_for_level() == 0)
	assert(current_scene.all_active_rivals().is_empty())
	assert(current_scene.bugs.size() >= 3)
	for species in 3:
		assert(current_scene.bugs[species].species_id == species)
		assert(current_scene.bugs[species].sprite.texture == current_scene.BUGS_MODE_TEXTURES[species])
	for a in current_scene.web_edges.size():
		var first: Vector2i = current_scene.web_edges[a]
		for b in range(a + 1, current_scene.web_edges.size()):
			var second: Vector2i = current_scene.web_edges[b]
			if first.x == second.x or first.x == second.y or first.y == second.x or first.y == second.y:
				continue
			assert(Geometry2D.segment_intersects_segment(current_scene.web_points[first.x], current_scene.web_points[first.y], current_scene.web_points[second.x], current_scene.web_points[second.y]) == null)
	print("SPIDER_WARS_RIVAL_LEVELS_PASS")
	quit()
