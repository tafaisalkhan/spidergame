extends SceneTree

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	root.size = Vector2i(2400, 1080)
	await process_frame
	var manager = root.get_node("GameManager")
	manager.start_bugs_mode()
	await process_frame
	await process_frame
	var game = current_scene
	assert(game.bugs_mode and game.intro_level == 1)
	assert(game.intro_goal() == 4 and game.bugs.size() == 4)
	assert(game.web_edges.size() == 20 and game.web_points.size() == 12)
	assert(game.intro_reveal_active and game.camera.zoom == Vector2.ONE / game.bugs_mode_arena_scale())
	game.finish_bugs_reveal()
	assert(game.camera.zoom == Vector2.ONE / game.bugs_mode_arena_scale())
	var settings = root.get_node("AppSettings")
	assert(settings.music_player.stream is AudioStreamMP3 and settings.music_player.stream.loop)
	assert(settings.music_player.stream.get_length() > 90.0)
	assert(game.walking_audio.stream.get_length() > 12.0)
	game.set_spider_walking_sound(true)
	assert(game.walking_audio.playing)
	game.set_spider_walking_sound(false)
	assert(not game.walking_audio.playing)
	settings.set_sfx_enabled(false)
	game.set_spider_walking_sound(true)
	assert(not game.walking_audio.playing)
	settings.set_sfx_enabled(true)
	game.set_camera_zoom(1.0 / game.bugs_mode_arena_scale())
	assert(game.all_active_rivals().is_empty() and not game.rival.visible)
	assert(not game.spider.health_bar.visible)
	assert(game.spider.visual.texture.get_size() == Vector2(565, 410))
	assert(game.spider.speed == 175.0)
	assert(game.cut_charges == 2 and game.build_charges == 2 and game.boost_charges == 2 and game.timer_charges == 2 and game.stun_charges == 2 and game.cloak_charges == 2)
	assert(game.bugs_pause_button.visible and game.bugs_item_rail.visible and game.bugs_focus_button.visible)
	assert(game.timer_button.visible and game.boost_button.visible and game.weave_button.visible)
	for power_button in [game.timer_button, game.boost_button, game.weave_button]:
		assert(power_button.get_node_or_null("RewardAdButton") is Button)
	for hidden_power in [game.cut_button, game.cancel_button, game.stun_button, game.cloak_button]:
		assert(not hidden_power.visible)
	game.toggle_power_hud()
	assert(not game.bugs_item_rail.visible and not game.timer_button.visible and not game.boost_button.visible and not game.weave_button.visible and not game.bugs_focus_button.visible)
	assert(game.power_toggle_button.visible and game.bugs_pause_button.visible)
	game.toggle_power_hud()
	assert(game.bugs_item_rail.visible and game.timer_button.visible and game.boost_button.visible and game.weave_button.visible and game.bugs_focus_button.visible)
	game.toggle_bugs_pause()
	assert(paused and game.bugs_pause_panel.visible)
	game.toggle_bugs_pause()
	assert(not paused and not game.bugs_pause_panel.visible)
	assert(game.camera.zoom == Vector2.ONE / game.bugs_mode_arena_scale())
	var viewport_box: Rect2 = game.get_viewport().get_visible_rect()
	var web_box := Rect2(game.get_canvas_transform() * game.web_points[0], Vector2.ZERO)
	for point in game.web_points:
		var screen_point: Vector2 = game.get_canvas_transform() * point
		assert(viewport_box.has_point(screen_point))
		web_box = web_box.expand(screen_point)
	assert(web_box.size.x > viewport_box.size.x * 0.78)
	assert(web_box.size.y > viewport_box.size.y * 0.70)
	assert(game.spider_step_is_clear(game.spider, game.web_points[11]))
	for bug_index in game.bugs.size():
		var bug = game.bugs[bug_index]
		assert(bug.active and bug.stuck and bug.flies_away_on_release)
		assert(bug.glue_duration == game.bugs_mode_release_time(game.bugs_mode_release_rank(bug.route[0])) and bug.release_timer_label.visible)
		assert(not bug.health_bar.visible and bug.release_timer_label.text == "%d" % ceili(bug.glue_duration))
		assert(viewport_box.has_point(game.get_canvas_transform() * bug.position))
		var screen_position: Vector2 = game.get_canvas_transform() * bug.position
		var half_bug_width: float = bug.sprite.texture.get_width() * bug.sprite.scale.x * game.get_canvas_transform().get_scale().x * 0.5
		var rail_left: float = game.ui_design.position.x + game.bugs_item_rail.position.x * game.ui_design.scale.x
		assert(screen_position.x + half_bug_width < rail_left)
	assert(game.bugs[0].size_factor < game.bugs[2].size_factor)
	assert(game.bugs[2].size_factor < game.bugs[1].size_factor)
	var ranked_bugs: Array = game.bugs.duplicate()
	ranked_bugs.sort_custom(func(a, b): return a.position.distance_squared_to(game.spider.position) < b.position.distance_squared_to(game.spider.position))
	for rank in ranked_bugs.size():
		assert(ranked_bugs[rank].glue_duration == 20.0 + 5.0 * rank)
	game.bugs[0]._process(1.1)
	assert(game.bugs[0].release_timer_label.text == "%d" % ceili(game.bugs[0].glue_duration - 1.1))
	game.bugs[0].glue_remaining = game.bugs[0].glue_duration
	game.bugs[0].refresh_trap_bar()
	var original_durations: Array[float] = []
	for bug in game.bugs:
		original_durations.append(bug.glue_duration)
	game.use_timer_power()
	assert(game.timer_charges == 1 and game.timer_button.get_node("Charge").text == "1")
	assert(not game.timer_button.get_node("RewardAdButton").visible)
	for bug_index in game.bugs.size():
		assert(game.bugs[bug_index].glue_duration == original_durations[bug_index] + 5.0)
		assert(game.bugs[bug_index].glue_remaining == original_durations[bug_index] + 5.0)
	game.use_timer_power()
	assert(game.timer_charges == 0 and game.timer_button.disabled)
	assert(game.timer_button.get_node("RewardAdButton").visible)
	game.use_timer_power()
	assert(game.timer_charges == 0)
	restart_ready(game)
	assert(game.timer_charges == game.START_TIMER_CHARGES)
	game.finish_construction()
	var chased_bug: TrapBug = game.bugs[1]
	var calm_bug: TrapBug = game.bugs[0]
	game.target_bug = chased_bug
	game.spider.position = chased_bug.position + Vector2(-220.0, 0.0)
	game._process(0.01)
	assert(chased_bug.escape_panic_goal > 0.9 and calm_bug.escape_panic_goal == 0.0)
	assert(chased_bug.approach_panic_played and not calm_bug.approach_panic_played)
	var panic_sound_playing := false
	for child in game.get_children():
		if child is AudioStreamPlayer and child.stream == game.PANIC_BUG_SOUND and child.playing:
			panic_sound_playing = true
	assert(panic_sound_playing)
	var chased_phase := chased_bug.phase
	var calm_phase := calm_bug.phase
	var chased_glue := chased_bug.glue_remaining
	var calm_glue := calm_bug.glue_remaining
	chased_bug._process(0.5)
	calm_bug._process(0.5)
	assert(chased_bug.phase - chased_phase > (calm_bug.phase - calm_phase) * 2.0)
	assert(chased_glue - chased_bug.glue_remaining > calm_glue - calm_bug.glue_remaining)
	chased_bug.release_glue()
	calm_bug.release_glue()
	assert(not chased_bug.release_timer_label.visible and not calm_bug.release_timer_label.visible)
	chased_bug._process(0.3)
	calm_bug._process(0.3)
	assert(chased_bug.flight_progress > calm_bug.flight_progress)
	assert(chased_bug.flight_audio != null and chased_bug.flight_audio.playing)
	game.finish_bug_escape_focus()
	game.cancel_auto_navigation()
	game._process(0.01)
	assert(chased_bug.escape_panic_goal == 0.0)
	restart_ready(game)
	var untapped_bug: TrapBug = game.bugs[1]
	game.finish_construction()
	game.target_bug = null
	game.spider.position = untapped_bug.position + Vector2(-220.0, 0.0)
	game.player_heading = Vector2.RIGHT
	game._process(0.01)
	assert(untapped_bug.escape_panic_goal > 0.9 and untapped_bug.approach_panic_played)
	restart_ready(game)
	var approaching_bug: TrapBug = game.bugs[1]
	game.target_bug = approaching_bug
	for frame in 180:
		game._process(1.0 / 60.0)
		approaching_bug._process(1.0 / 60.0)
		game._physics_process(1.0 / 60.0)
		if approaching_bug.web_cuts_done > 0:
			break
	assert(approaching_bug.web_cuts_done == 1 and approaching_bug.active)
	restart_ready(game)
	var early_bug: TrapBug = game.bugs[1]
	var early_node: int = early_bug.route[0]
	var preceding_node: int = game.adjacency[early_node][0]
	var early_edge: int = game.edge_index(preceding_node, early_node)
	game.target_bug = early_bug
	game.spider_node = preceding_node
	game.spider_target = early_node
	game.spider_progress = 0.5
	game.spider.position = game.web_position(preceding_node, early_node, 0.5)
	game.on_bug_web_cut_requested(early_bug)
	assert(game.edge_active[early_edge] and early_bug.web_cuts_done == 1)
	game.spider_target = preceding_node
	game.spider_progress = 0.0
	game.spider.position = game.web_points[preceding_node]
	game._physics_process(1.0 / 60.0)
	assert(not game.edge_active[early_edge] and early_bug.web_cuts_done == 2)
	assert(game.spider_target == preceding_node and is_zero_approx(game.spider_progress))
	restart_ready(game)
	var cutting_bug: TrapBug = game.bugs[1]
	var untouched_bug: TrapBug = game.bugs[0]
	assert(cutting_bug.repeat_web_cuts and cutting_bug.web_cut_limit == game.BUGS_MODE_WEB_LIMIT)
	game.target_bug = cutting_bug
	game.spider.position = cutting_bug.position + Vector2(-220.0, 0.0)
	game._process(0.01)
	var approach_path: Array = game.route_to_node(cutting_bug.route[0])["path"]
	assert(approach_path.size() >= 2)
	var approach_edge: int = game.edge_index(int(approach_path[-2]), cutting_bug.route[0])
	cutting_bug.route[1] = int(approach_path[-2])
	untouched_bug.web_cut_remaining = 0.0
	untouched_bug._process(0.1)
	assert(untouched_bug.web_cuts_done == 0 and untouched_bug.web_cut_remaining == 0.0)
	cutting_bug.web_cut_remaining = 0.0
	cutting_bug._process(0.1)
	assert(cutting_bug.web_cuts_done == 1 and cutting_bug.web_cut_edges.size() == 1)
	assert(cutting_bug.web_cut_edges[0] == approach_edge and not game.edge_active[approach_edge])
	game._process(0.01)
	assert(cutting_bug.active and game.escaped_count == 0)
	assert(cutting_bug.cut_flash_remaining > 0.0 and cutting_bug.sprite.modulate.a < 1.0)
	var cut_cooldown: float = cutting_bug.web_cut_remaining
	assert(cut_cooldown >= 3.0 and cut_cooldown <= 5.0)
	cutting_bug.glue_remaining = 20.0 # Keep this bug trapped while testing repeat cuts.
	cutting_bug._process(cut_cooldown - 0.05)
	assert(cutting_bug.web_cuts_done == 1)
	game.restore_edge(approach_edge, 1)
	cutting_bug._process(0.06)
	assert(cutting_bug.web_cuts_done == 2 and cutting_bug.web_cut_edges.size() == 2 and not game.edge_active[approach_edge])
	assert(untouched_bug.web_cuts_done == 0)
	game.finish_construction()
	game.spider.position = cutting_bug.position + Vector2(80.0, 0.0)
	game._process(0.01)
	assert(game.player_eat_bug == cutting_bug and game.player_eat_remaining > 0.0)
	assert(not cutting_bug.active)
	restart_ready(game)
	var isolating_bug: TrapBug = game.bugs[1]
	var isolated_node: int = isolating_bug.route[0]
	var neighbor_node: int = game.adjacency[isolated_node][0]
	game.spider_node = neighbor_node
	game.spider_target = neighbor_node
	game.spider.position = game.web_points[neighbor_node]
	game.target_bug = isolating_bug
	var connecting_links: Array[int] = []
	for neighbor in game.adjacency[isolated_node]:
		connecting_links.append(game.edge_index(isolated_node, neighbor))
	for cut_number in connecting_links.size():
		isolating_bug.web_cut_remaining = 0.0
		isolating_bug.set_escape_panic(1.0)
		isolating_bug._process(0.01)
		assert(isolating_bug.web_cuts_done == cut_number + 1)
		assert(isolating_bug.web_cut_remaining >= 3.0 and isolating_bug.web_cut_remaining <= 5.0)
	for link in connecting_links:
		assert(not game.edge_active[link])
	assert(not game.route_to_node(isolated_node)["path"].is_empty())
	var charges_before_isolation: int = game.build_charges
	game._physics_process(0.05)
	assert(game.build_charges == charges_before_isolation - 1 and game.player_repair_edge >= 0)
	restart_ready(game)
	game.build_charges = 1
	game.silk_refill_remaining = 0.1
	game.update_power_buttons()
	game._process(8.1)
	assert(game.build_charges == 1 and game.silk_refill_remaining == 0.1)
	assert(game.weave_button.get_node("Charge").text == "1")
	restart_ready(game)
	game.set_camera_zoom(1.0 / game.bugs_mode_arena_scale())
	game.spider.position = game.web_points[0]
	game.update_camera_position()
	assert(game.camera.position == game.WEB_CENTER)
	assert(game.bugs_zoom_in_button.visible and game.bugs_zoom_out_button.visible)
	game.set_camera_zoom(2.0)
	assert(game.camera.zoom == Vector2.ONE * 2.0 and game.camera.position == game.spider.position)
	game.bugs_zoom_out_button.pressed.emit()
	assert(game.camera_zoom < 2.0)
	game.set_camera_zoom(1.0)
	assert(not game.valid_new_link(0, 11))
	game.finish_construction()
	game.spider.position = game.web_points[game.spider_node]
	var tap_edge := -1
	var tap_point := Vector2.ZERO
	for index in game.web_edges.size():
		var edge: Vector2i = game.web_edges[index]
		var occupied := false
		for bug in game.bugs:
			occupied = occupied or game.edge_index(bug.route[0], bug.route[1]) == index
		var middle: Vector2 = game.web_points[edge.x].lerp(game.web_points[edge.y], 0.5)
		if not occupied and game.nearest_bug_at(middle) == null and game.nearest_anchor_at(middle, 70.0) < 0 and game.nearest_edge_at(middle, true) == index:
			tap_edge = index
			tap_point = middle
			break
	assert(tap_edge >= 0)
	var web_tap := InputEventMouseButton.new()
	web_tap.button_index = MOUSE_BUTTON_LEFT
	web_tap.pressed = true
	web_tap.position = game.get_canvas_transform() * tap_point
	var old_cut_charges: int = game.cut_charges
	game._unhandled_input(web_tap)
	assert(game.edge_active[tap_edge] and game.cut_charges == old_cut_charges and game.tap_destination_edge == tap_edge)
	var tapped_link: Vector2i = game.web_edges[tap_edge]
	var tapped_position: Vector2 = game.web_position(tapped_link.x, tapped_link.y, game.edge_tap_progress(tap_edge, tap_point))
	for step in 300:
		if game.tap_destination_edge < 0:
			break
		game._physics_process(0.05)
	assert(game.tap_destination_edge < 0 and game.spider.position.distance_to(tapped_position) < 8.0)
	game.toggle_trail_cut()
	web_tap.position = game.get_canvas_transform() * tap_point
	game._unhandled_input(web_tap)
	assert(not game.edge_active[tap_edge] and game.cut_charges == old_cut_charges - 1 and not game.trail_cut_enabled)
	restart_ready(game)
	# Keep the route and repair check focused on web navigation; passing bugs are covered separately.
	for bug in game.bugs:
		bug.active = false
	var repair_from: int = game.spider_node
	var repair_to: int = game.adjacency[repair_from][0]
	var repair_link: int = game.edge_index(repair_from, repair_to)
	game.edge_active[repair_link] = false
	var initial_build_charges: int = game.build_charges
	game.destination_node = repair_to
	var detour: Array = game.route_to_node(repair_to)["path"]
	assert(not detour.is_empty())
	for step in 160:
		game._physics_process(0.05)
	assert(game.edge_active[repair_link] and game.build_charges == initial_build_charges - 1)
	assert(game.spider_node == repair_to)
	restart_ready(game)
	var local_from: int = game.spider_node
	var first_local: int = game.edge_index(local_from, game.adjacency[local_from][0])
	var second_local: int = game.edge_index(local_from, game.adjacency[local_from][1])
	game.edge_active[first_local] = false
	game.edge_active[second_local] = false
	var distant_link := -1
	for index in game.web_edges.size():
		var link: Vector2i = game.web_edges[index]
		if link.x != local_from and link.y != local_from:
			distant_link = index
			break
	assert(distant_link >= 0)
	game.edge_active[distant_link] = false
	var local_charges: int = game.build_charges
	game.toggle_weave_mode()
	assert(game.weave_mode and game.bugs_available_repair_edges.size() == 2)
	assert(not game.bugs_available_repair_edges.has(distant_link))
	var repair_tap := InputEventMouseButton.new()
	repair_tap.button_index = MOUSE_BUTTON_LEFT
	repair_tap.pressed = true
	var distant: Vector2i = game.web_edges[distant_link]
	repair_tap.position = game.get_canvas_transform() * game.web_position(distant.x, distant.y, 0.5)
	game._unhandled_input(repair_tap)
	assert(game.weave_mode and game.build_charges == local_charges and game.player_repair_edge < 0)
	var first_link: Vector2i = game.web_edges[first_local]
	repair_tap.position = game.get_canvas_transform() * game.web_position(first_link.x, first_link.y, 0.5)
	game._unhandled_input(repair_tap)
	assert(game.player_repair_edge == first_local and game.build_charges == local_charges - 1)
	for step in 160:
		game._physics_process(0.05)
		if game.edge_active[first_local]:
			break
	assert(game.edge_active[first_local] and not game.edge_active[distant_link])
	restart_ready(game)
	var broken_from: int = game.spider_node
	var broken_to: int = game.adjacency[broken_from][0]
	var broken_under_spider: int = game.edge_index(broken_from, broken_to)
	game.spider_target = broken_to
	game.spider_progress = 0.4
	game.spider.position = game.web_position(broken_from, broken_to, 0.4)
	game.edge_active[broken_under_spider] = false
	game.spider_retreating = true
	var retreat_charges: int = game.build_charges
	game.toggle_weave_mode()
	assert(game.selected_repair_edge == broken_under_spider and game.build_charges == retreat_charges)
	for step in 160:
		game._physics_process(0.05)
		if game.edge_active[broken_under_spider]:
			break
	assert(game.edge_active[broken_under_spider] and game.build_charges == retreat_charges - 1)
	restart_ready(game)
	var free_edge := -1
	for index in game.web_edges.size():
		var occupied := false
		for bug in game.bugs:
			occupied = occupied or game.edge_index(bug.route[0], bug.route[1]) == index
		if not occupied:
			free_edge = index
			break
	assert(free_edge >= 0 and game.cut_edge(free_edge, 1) and not game.edge_active[free_edge])
	game._process(game.bugs_mode_time_limit())
	assert(game.finished and game.winner == 2 and game.result_title.text == "LEVEL FAILED")
	restart_ready(game)
	var escaping_bug: TrapBug = game.bugs[0]
	var camera_before_escape: Vector2 = game.camera.position
	var zoom_before_escape: Vector2 = game.camera.zoom
	var time_before_escape: float = game.elapsed_seconds
	var spider_before_escape: Vector2 = game.spider.position
	escaping_bug._process(escaping_bug.glue_duration + 0.1)
	assert(escaping_bug.escaping_flight and game.intro_reveal_active)
	assert(game.camera.zoom.x > zoom_before_escape.x and not game.bugs[1].is_processing())
	game._process(3.0)
	game._physics_process(3.0)
	assert(game.elapsed_seconds == time_before_escape and game.spider.position == spider_before_escape)
	escaping_bug._process(1.2)
	assert(not game.finished and game.escaped_count == 1 and game.escape_focus_returning)
	await create_timer(0.8).timeout
	assert(not game.intro_reveal_active and game.camera.zoom == zoom_before_escape)
	assert(game.camera.position == camera_before_escape and game.bugs[1].is_processing())
	for bug in game.bugs:
		if bug.active:
			bug.active = false
			game.on_bug_escaped(bug)
	assert(game.finished and game.winner == 2 and game.escaped_count == 4)
	assert(game.bugs_mode_star_count() == 0 and game.bugs_mode_coin_reward() == 0)
	assert(game.result_title.text == "LEVEL FAILED" and game.result_reward.text == "NO COINS")
	for caught_total in [1, 2, 3]:
		restart_ready(game)
		var balance_before: int = game.coins
		game.caught_count = caught_total
		game.escaped_count = 4 - caught_total
		game.check_round_complete()
		var expected_stars := 2 if caught_total == 3 else 1
		var expected_coins := 5
		assert(game.finished and game.winner == 1)
		assert(game.bugs_mode_star_count() == expected_stars)
		assert(game.coins == balance_before + expected_coins)
		assert(game.result_reward.text == "+%d COIN%s" % [expected_coins, "" if expected_coins == 1 else "S"])
		for index in expected_stars:
			assert(game.result_stars.get_child(index).get_child(0).scale.length() < 0.02)
		await create_timer(1.2).timeout
		var visible_flying_coins := 0
		for child in game.ui_root.get_children():
			if child is TextureRect and child.texture == game.REWARD_COIN and child.modulate.a > 0.0:
				visible_flying_coins += 1
		assert(visible_flying_coins > 0)
		for index in game.result_stars.get_child_count():
			assert(game.result_stars.get_child(index).get_child(0).modulate == (Color.WHITE if index < expected_stars else Color(0.24, 0.24, 0.24, 0.28)))
	restart_ready(game)
	assert(game.rival_caught_count == 0 and not game.rival_active)
	assert(game.status_label.text == "0/4")
	game.caught_count = 1
	game.escaped_count = 3
	game.check_round_complete()
	assert(game.finished and game.winner == 1 and game.result_note.text.begins_with("Caught: 1 / 4"))
	restart_ready(game)
	var full_clear_balance: int = game.coins
	var fixed_size: Vector2 = game.spider.visual.scale
	game.elapsed_seconds = 20.0
	for bug in game.bugs:
		game.catch_bug(bug, 1)
		game.player_eat_remaining = 0.0
		game.finish_eating(1)
		assert(game.spider.visual.scale == fixed_size)
	assert(game.elapsed_seconds == 0.0)
	assert(game.finished and game.winner == 1 and game.caught_count == 4)
	assert(game.bugs_mode_star_count() == 3 and game.coins == full_clear_balance + 5)
	assert(game.result_reward.text == "+5 COINS")
	root.size = Vector2i(2400, 1080)
	await process_frame
	game.update_mobile_layout()
	for button in [game.timer_button, game.boost_button, game.weave_button, game.bugs_zoom_in_button, game.bugs_zoom_out_button, game.bugs_focus_button, game.bugs_pause_button, game.power_toggle_button]:
		var button_right: float = game.ui_design.position.x + (button.position.x + button.size.x) * game.ui_design.scale.x
		assert(button_right <= 2400.5)
	game.result_menu_button.pressed.emit()
	await process_frame
	assert(current_scene.scene_file_path == "res://scenes/main_menu.tscn")
	root.size = Vector2i(2400, 1080)
	await process_frame
	var menu = current_scene
	menu.update_layout()
	var menu_left: float = menu.design.position.x + menu.backdrop_art.position.x * menu.design.scale.x
	var menu_right: float = menu_left + menu.backdrop_art.size.x * menu.design.scale.x
	assert(menu_left <= 0.5 and menu_right >= 2399.5)
	print("SPIDER_WARS_BUGS_MODE_PASS")
	quit()

func restart_ready(game) -> void:
	game.restart()
	game.finish_bugs_reveal()
