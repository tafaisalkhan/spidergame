extends SceneTree

const TrapScene = preload("res://scenes/web_trap.tscn")

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	var game = TrapScene.instantiate()
	root.add_child(game)
	await process_frame
	assert(game.bugs.size() == 6)
	assert(game.rival != null and game.rival.owner_id == 2)
	assert(game.rival.position == game.web_points[44])
	game.spider.face_motion(Vector2.RIGHT, 1.0)
	assert(absf(wrapf(game.spider.visual.rotation + PI / 2.0, -PI, PI)) < 0.001)
	game.spider.face_motion(Vector2.DOWN, 1.0)
	assert(absf(game.spider.visual.rotation) < 0.001)
	game.spider.face_motion(Vector2.LEFT, 0.016)
	assert(Vector2.DOWN.rotated(game.spider.visual.rotation).dot(Vector2.LEFT) > 0.999)
	assert(game.web_points.size() == 122)
	assert(game.web_edges.size() == 259)
	assert(game.upper_nodes.size() == 5)
	assert(game.bugs[4].position.y < 0.0 and game.bugs[5].position.y < 0.0)
	assert(game.camera.position == game.WEB_CENTER)
	for bug in game.bugs:
		assert(bug.stuck and bug.progress == 0.0)
		for route_step in bug.route.size() - 1:
			assert(game.edge_index(bug.route[route_step], bug.route[route_step + 1]) >= 0)
	assert(game.edge_kind.size() == game.web_edges.size())
	assert(game.edge_kind[0] == 0 and game.edge_kind[1] == 1)
	assert(game.edge_kind.has(2))
	for a in game.web_edges.size():
		var first: Vector2i = game.web_edges[a]
		for b in range(a + 1, game.web_edges.size()):
			var second: Vector2i = game.web_edges[b]
			if first.x == second.x or first.x == second.y or first.y == second.x or first.y == second.y:
				continue
			assert(Geometry2D.segment_intersects_segment(game.web_points[first.x], game.web_points[first.y], game.web_points[second.x], game.web_points[second.y]) == null)
	assert(game.web_points[85].x < 100.0)
	assert(game.web_points[86].y < 100.0)
	assert(game.web_points[91].x > 980.0)
	assert(game.web_points[92].y > 1800.0)
	for bug in game.bugs:
		assert(game.web_points.has(bug.position))
	assert(game.building)
	var start: Vector2 = game.spider.position
	var rival_start: Vector2 = game.rival.position
	game.spider.desired_direction = Vector2.RIGHT
	game._physics_process(0.1)
	assert(game.spider.position == start)
	assert(game.rival.position == rival_start)
	game.finish_construction()
	var strong_bug: TrapBug = game.bugs[5]
	var weak_bug: TrapBug = game.bugs[1]
	assert(strong_bug.strong and strong_bug.glue_duration < weak_bug.glue_duration)
	strong_bug._process(strong_bug.glue_duration + 0.01)
	weak_bug._process(strong_bug.glue_duration + 0.01)
	assert(not strong_bug.stuck and weak_bug.stuck)
	assert(strong_bug.progress == 0.0 and weak_bug.progress == 0.0)
	strong_bug._process(0.5)
	assert(strong_bug.progress > 0.0)
	game.spider_node = game.upper_nodes[0][1]
	game.spider_target = game.spider_node
	game.spider.position = game.web_points[game.spider_node]
	game.spider.desired_direction = Vector2.ZERO
	game._physics_process(0.016)
	assert(game.camera.position.y < 0.0)
	game.spider_node = 0
	game.spider_target = 0
	game.spider.position = game.WEB_CENTER
	game.camera.position = game.WEB_CENTER
	game.spider.desired_direction = Vector2.UP
	for step in 650:
		game.move_spider_on_web(0.016)
		if game.spider.position.y < -300.0:
			break
	assert(game.spider.position.y < -300.0)
	game.spider_node = 0
	game.spider_target = 0
	game.spider_progress = 0.0
	game.spider.position = game.WEB_CENTER
	game.spider.desired_direction = Vector2.RIGHT
	for bug in game.bugs:
		assert(bug.motion_style == TrapBug.MotionStyle.CRAWL)
		bug._process(0.1)
		assert(bug.position.distance_to(game.web_position(bug.route[0], bug.route[1], bug.progress)) < 0.1)
		assert(bug.motion_material.get_shader_parameter("motion_phase") > 0.0)
		assert(bug.sprite.position != Vector2.ZERO)
	for i in 60:
		var blue_before: Vector2 = game.spider.position
		var red_before: Vector2 = game.rival.position
		game.move_spider_on_web(0.016)
		game.move_rival_on_web(0.016)
		if game.spider.position.distance_to(blue_before) > 0.01:
			assert(Vector2.DOWN.rotated(game.spider.visual.rotation).dot((game.spider.position - blue_before).normalized()) > 0.995)
		if game.rival.position.distance_to(red_before) > 0.01:
			assert(Vector2.DOWN.rotated(game.rival.visual.rotation).dot((game.rival.position - red_before).normalized()) > 0.995)
		assert(game.spider.position.distance_to(game.web_position(game.spider_node, game.spider_target, game.spider_progress)) < 0.1)
		assert(game.rival.position.distance_to(game.web_position(game.rival_node, game.rival_target, game.rival_progress)) < 0.1)
	assert(game.rival.position != rival_start)
	assert(game.spider.gait_phase > 0.0 and game.spider.gait_strength > 0.0)
	assert(game.rival.gait_phase > 0.0 and game.rival.gait_strength > 0.0)
	var idle_phase: float = game.spider.gait_phase
	game.spider.desired_direction = Vector2.ZERO
	game.move_spider_on_web(0.1)
	assert(game.spider.gait_phase == idle_phase)
	var cut_index: int = game.edge_index(game.spider_node, game.spider_target)
	assert(cut_index >= 0 and game.spider_progress > 0.0)
	game.cut_edge(cut_index)
	assert(not game.edge_active[cut_index] and game.spider_retreating)
	for i in 100:
		game.move_spider_on_web(0.016)
	assert(not game.spider_retreating)
	assert(game.spider.position == game.web_points[game.spider_node])
	# Move the player away so the rival can reach and repair the cut endpoint.
	game.spider_node = 96
	game.spider_target = 96
	game.spider_progress = 0.0
	game.spider.position = game.web_points[96]
	for i in 2500:
		game.move_rival_on_web(0.016)
		if game.edge_active[cut_index]:
			break
	assert(game.edge_active[cut_index])
	var bug_edge: int = game.edge_index(game.bugs[0].route[0], game.bugs[0].route[1])
	game.cut_edge(bug_edge)
	assert(not game.bugs[0].active and game.escaped_count == 1)
	game.restart()
	await process_frame
	game.finish_construction()
	assert(game.bugs[5].sprite.scale.x > game.bugs[0].sprite.scale.x)
	assert(game.bugs[5].eat_duration > game.bugs[0].eat_duration)
	game.catch_bug(game.bugs[0], 1)
	assert(game.spider.catching and game.player_eat_remaining > 0.0)
	assert(game.caught_count == 0)
	var eating_position: Vector2 = game.spider.position
	game._physics_process(game.bugs[0].eat_duration * 0.5)
	assert(game.spider.position == eating_position and game.caught_count == 0)
	game._physics_process(game.bugs[0].eat_duration * 0.6)
	assert(game.caught_count == 1 and not game.spider.catching)
	assert(get_nodes_in_group("catch_effects").size() > 0)
	for i in range(1, game.bugs.size()):
		game.catch_bug(game.bugs[i], 1 if i < 4 else 2)
		assert(game.bugs[i].active == false)
		if i == 4:
			var rival_eating_position: Vector2 = game.rival.position
			game._physics_process(game.bugs[i].eat_duration * 0.5)
			assert(game.rival.position == rival_eating_position and game.rival_caught_count == 0)
			game._physics_process(game.bugs[i].eat_duration * 0.6)
		else:
			game._physics_process(game.bugs[i].eat_duration)
	assert(game.caught_count == 4)
	assert(game.rival_caught_count == 2)
	assert(game.finished)
	assert(game.winner == 1)
	assert(game.escaped_count == 0)
	game.restart()
	await process_frame
	assert(not game.finished)
	game.finish_construction()
	game.on_bug_escaped(game.bugs[0])
	assert(not game.finished and game.escaped_count == 1)
	for i in range(1, game.bugs.size()):
		game.catch_bug(game.bugs[i], 1 if i == 1 else 2)
		game._physics_process(game.bugs[i].eat_duration)
	assert(game.finished and game.winner == 2)
	assert(game.rival_caught_count == 4)
	assert(game.result_panel.visible and game.result_dimmer.visible)
	assert(game.result_title.text == "LEVEL FAILED")
	assert(game.result_reward.text == "NO BONUS COINS")
	game.restart()
	await process_frame
	game.finish_construction()
	game.last_cut_msec = -1000
	var tapped_index: int = game.edge_index(0, 2)
	var tapped_edge: Vector2i = game.web_edges[tapped_index]
	var tap_point: Vector2 = game.web_position(tapped_edge.x, tapped_edge.y, 0.5)
	var tap := InputEventScreenTouch.new()
	tap.pressed = true
	tap.position = game.get_canvas_transform() * tap_point
	game._unhandled_input(tap)
	assert(not game.edge_active[tapped_index])
	game.restart()
	await process_frame
	game.finish_construction()
	var upper_cut_index: int = game.edge_index(game.upper_nodes[0][1], game.upper_nodes[1][1])
	var upper_edge: Vector2i = game.web_edges[upper_cut_index]
	var upper_world_point: Vector2 = game.web_position(upper_edge.x, upper_edge.y, 0.5)
	game.camera.position = Vector2(540, upper_world_point.y)
	game.camera.reset_smoothing()
	game.camera.force_update_scroll()
	var upper_screen_point: Vector2 = game.get_canvas_transform() * upper_world_point
	assert(upper_screen_point.y > 0.0 and upper_screen_point.y < 1920.0)
	var upper_tap := InputEventScreenTouch.new()
	upper_tap.pressed = true
	upper_tap.position = upper_screen_point
	game.last_cut_msec = -1000
	game._unhandled_input(upper_tap)
	assert(not game.edge_active[upper_cut_index])
	game.restart()
	await process_frame
	game.finish_construction()
	game.spider_node = 0
	game.spider_target = 2
	game.spider_progress = 0.0
	game.spider.position = game.web_points[0]
	game.spider.desired_direction = Vector2.UP
	game.rival_node = 2
	game.rival_target = 0
	game.rival_progress = 0.0
	game.rival.position = game.web_points[2]
	for step in 120:
		game.move_spider_on_web(0.016)
		game.move_rival_on_web(0.016)
		assert(game.spider.position.distance_to(game.rival.position) >= game.SPIDER_SEPARATION - 0.1)
		assert(game.spider.position.y > game.rival.position.y)
	assert(game.spider_progress > 0.0 and game.rival_progress > 0.0)
	assert(not game.spider_step_is_clear(game.spider, game.rival.position))
	game.restart()
	await process_frame
	game.finish_construction()
	for i in game.bugs.size():
		game.catch_bug(game.bugs[i], 1 if i < 3 else 2)
		game._physics_process(game.bugs[i].eat_duration)
	assert(game.finished and game.winner == 0)
	game.restart()
	await process_frame
	game.finish_construction()
	for tick in 3000:
		for bug in game.bugs:
			if bug.active:
				bug._process(0.016)
		game._physics_process(0.016)
		game._process(0.016)
		if game.finished:
			break
	assert(game.finished)
	assert(game.rival_caught_count > 0)
	assert(game.escaped_count > 0)
	assert(game.caught_count + game.rival_caught_count + game.escaped_count == game.bugs.size())
	print("SPIDER_WARS_WEB_TRAP_PASS")
	game.free()
	quit()
