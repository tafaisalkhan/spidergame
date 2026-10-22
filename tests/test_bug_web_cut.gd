extends SceneTree

const FIRST_HUNT = preload("res://scenes/first_hunt.tscn")

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	var game = FIRST_HUNT.instantiate()
	root.add_child(game)
	await process_frame
	if game.intro_reveal_active:
		game.finish_intro_reveal()
	assert(game.intro_goal() == 5 and game.bugs.size() == 3)
	assert(game.rival_active)
	var occupied_edge: Vector2i = game.web_edges[0]
	game.spider_node = occupied_edge.x
	game.spider_target = occupied_edge.y
	game.spider_progress = 0.5
	assert(not game.cut_edge(0, 4) and game.edge_active[0])
	game.spider_target = game.spider_node
	game.spider_progress = 0.0
	assert(game.bugs[0].web_cut_limit == 1)
	assert(game.bugs[2].size_factor < 1.0 and game.bugs[2].web_cut_limit == 1)
	var bug: TrapBug = game.bugs[1]
	assert(bug.size_factor > 1.0 and bug.web_cut_limit == 2)
	for expected in [1, 2]:
		bug.web_cut_remaining = 0.0
		bug._process(0.1)
		assert(bug.web_cuts_done == expected)
		assert(game.required_bug_repair_edge(bug) >= 0)
		assert(bug.web_needs_repair)
		assert(bug.active and bug.stuck)
	assert(bug.web_cut_edges.size() == 2)
	game.target_bug = bug
	var charges_before_manual_repair: int = game.build_charges
	game.move_spider_on_web(0.016)
	assert(game.build_charges == charges_before_manual_repair)
	assert(game.required_bug_repair_edge(bug) >= 0)
	bug.web_cut_remaining = 0.0
	bug._process(0.1)
	assert(bug.web_cuts_done == 2)
	game.catch_bug(bug, 1)
	assert(bug.active and game.player_eat_bug == null)
	for torn_index in bug.web_cut_edges:
		var endpoint: int = game.web_edges[torn_index].x
		game.spider_node = endpoint
		game.spider_target = endpoint
		game.spider.position = game.web_points[endpoint]
		assert(game.begin_player_repair(torn_index))
		game.restore_edge(torn_index, 1)
	assert(game.required_bug_repair_edge(bug) == -1)
	assert(not bug.web_needs_repair)
	game.catch_bug(bug, 1)
	assert(not bug.active and game.player_eat_bug == bug)
	game.player_eat_remaining = 0.0
	game.finish_eating(1)
	assert(game.caught_count == 1 and not game.finished)
	game.caught_count = game.intro_goal() - 1
	game.catch_bug(game.bugs[0], 1)
	game.player_eat_remaining = 0.0
	game.finish_eating(1)
	assert(game.finished and game.winner == 1 and game.rival_active)
	print("SPIDER_WARS_BUG_WEB_CUT_PASS")
	quit()
