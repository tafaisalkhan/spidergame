extends SceneTree

const FIRST_HUNT = preload("res://scenes/first_hunt.tscn")

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	set_meta("first_hunt_level", 6)
	set_meta("first_hunt_rival_levels", true)
	var game = FIRST_HUNT.instantiate()
	root.add_child(game)
	await process_frame
	game.finish_intro_reveal()
	for hunter in game.extra_rivals:
		hunter.active = false
	game.caught_count = 2
	game.rival_caught_count = 1
	game.player_ready_audio.stop()
	game.resolve_solo_collision()
	assert(not game.finished and not game.player_ready_audio.playing)
	game._physics_process(game.RIVAL_EAT_DURATION + 0.01)
	assert(game.finished and game.winner == 1)
	assert(game.player_ready_audio.playing)
	print("SPIDER_WARS_RIVAL_FINISH_SOUND_PASS")
	quit()
