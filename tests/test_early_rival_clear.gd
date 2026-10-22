extends SceneTree

const FIRST_HUNT = preload("res://scenes/first_hunt.tscn")

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	for level in range(1, 6):
		set_meta("first_hunt_level", level)
		set_meta("first_hunt_rival_levels", true)
		var game = FIRST_HUNT.instantiate()
		root.add_child(game)
		await process_frame
		if game.intro_reveal_active:
			game.finish_intro_reveal()
		assert(not game.rivals_can_respawn())
		game.player_power = 100
		var opponents = game.all_active_rivals()
		assert(opponents.size() == game.rival_count_for_level())
		for opponent in opponents:
			if opponent == game.rival:
				game.resolve_solo_collision()
			else:
				game.resolve_player_rival_collision(opponent)
			assert(game.player_rival_eat_remaining > 0.0)
			game._physics_process(game.RIVAL_EAT_DURATION + 0.01)
		assert(game.all_active_rivals().is_empty())
		assert(not game.finished and game.caught_count < game.intro_goal())
		game._process(15.0)
		assert(game.all_active_rivals().is_empty())
		assert(game.rival_respawn_remaining < 0.0)
		for hunter in game.extra_rivals:
			assert(hunter.respawn_remaining < 0.0)
		assert(not game.finished)
		game.caught_count = game.intro_goal()
		game.check_round_complete()
		assert(game.finished and game.winner == 1)
		game.free()
		await process_frame
	set_meta("first_hunt_level", 6)
	set_meta("first_hunt_rival_levels", false)
	var later_game = FIRST_HUNT.instantiate()
	root.add_child(later_game)
	await process_frame
	assert(later_game.rivals_can_respawn())
	later_game.player_power = 100
	later_game.resolve_solo_collision()
	later_game._physics_process(later_game.RIVAL_EAT_DURATION + 0.01)
	assert(not later_game.rival_active and later_game.rival_respawn_remaining > 0.0)
	later_game._process(4.1)
	assert(later_game.rival_active)
	print("SPIDER_WARS_EARLY_RIVAL_CLEAR_PASS")
	quit()
