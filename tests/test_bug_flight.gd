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
	game.rival_active = false
	game.rival.hide()
	var escaping_bug: TrapBug = game.bugs[2]
	assert(escaping_bug.active and escaping_bug.stuck)
	assert(not escaping_bug.permanently_trapped and escaping_bug.flies_away_on_release)
	assert(is_equal_approx(escaping_bug.health_bar.health, 100.0))
	assert(escaping_bug.health_bar.fill_color != game.bugs[0].health_bar.fill_color)
	escaping_bug._process(escaping_bug.glue_duration * 0.5)
	assert(escaping_bug.health_bar.health > 40.0 and escaping_bug.health_bar.health < 60.0)
	assert(escaping_bug.stuck)
	escaping_bug._process(escaping_bug.glue_duration * 0.5 + 0.1)
	assert(is_zero_approx(escaping_bug.health_bar.health))
	assert(escaping_bug.active and escaping_bug.escaping_flight)
	assert(escaping_bug.free_voice_player.playing)
	assert(escaping_bug.free_voice_player.stream.loop)
	assert(is_equal_approx(escaping_bug.free_voice_player.stream.get_length(), 3.0))
	assert(escaping_bug.motion_style == TrapBug.MotionStyle.FLY)
	var release_position := escaping_bug.position
	escaping_bug._process(0.6)
	assert(escaping_bug.position.y < release_position.y)
	escaping_bug._process(0.7)
	assert(not escaping_bug.active and not escaping_bug.visible)
	assert(not escaping_bug.free_voice_player.playing)
	assert(game.escaped_count == 1 and not game.finished)
	var previous_count: int = game.bugs.size()
	game._process(2.6)
	assert(game.bugs.size() == previous_count + 1)
	var arriving_bug: TrapBug = game.bugs.back()
	assert(arriving_bug.arriving and not arriving_bug.active)
	assert(arriving_bug.motion_style == TrapBug.MotionStyle.FLY)
	var entry_position := arriving_bug.position
	arriving_bug._process(0.5)
	assert(arriving_bug.position.y > entry_position.y)
	arriving_bug._process(1.3)
	assert(not arriving_bug.arriving and arriving_bug.active and arriving_bug.stuck)
	assert(arriving_bug.landing_flash > 0.0 and arriving_bug.health_bar.visible)
	print("SPIDER_WARS_BUG_FLIGHT_PASS")
	quit()
