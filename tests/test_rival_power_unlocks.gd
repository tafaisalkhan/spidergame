extends SceneTree

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	for level in range(2, 6):
		var game = load("res://scenes/first_hunt_%d.tscn" % level).instantiate()
		root.add_child(game)
		await process_frame
		if game.intro_reveal_active:
			game.finish_intro_reveal()
		assert(game.rival_active)
		assert(game.boost_charges == game.START_BOOST_CHARGES)
		assert(game.stun_charges == game.START_STUN_CHARGES)
		assert(game.cut_charges == game.START_CUT_CHARGES)
		assert(game.build_charges == game.START_BUILD_CHARGES)
		assert(game.rival_boost_charges == 0)
		assert(game.rival_cut_charges == 0)
		assert(game.rival_build_charges == 0)
		assert(game.rival_stun_charges == 0)
		for hunter in game.extra_rivals:
			assert(hunter.boost_charges == 0)
			assert(hunter.cut_charges == 0)
			assert(hunter.build_charges == 0)
			assert(hunter.stun_charges == 0)
		game.spider_node = 0
		game.spider_target = 3
		game.rival.position = game.spider.position + Vector2(200, 0)
		var edge: int = game.edge_index(0, 3)
		var rival_speed: float = game.rival.speed
		game.use_rival_ai_power()
		assert(game.edge_active[edge])
		assert(is_equal_approx(game.rival.speed, rival_speed))
		assert(game.player_stun_remaining == 0.0)
		for hunter in game.extra_rivals:
			hunter.spider.position = game.spider.position + Vector2(200, 0)
			var hunter_speed: float = hunter.spider.speed
			game.use_extra_rival_ai_power(hunter)
			assert(game.edge_active[edge])
			assert(is_equal_approx(hunter.spider.speed, hunter_speed))
			assert(game.player_stun_remaining == 0.0)
		game.free()
		await process_frame
	print("SPIDER_WARS_RIVAL_POWERS_PLAYER_ONLY_PASS")
	quit()
