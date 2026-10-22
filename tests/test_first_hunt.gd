extends SceneTree

const FIRST_LEVEL = preload("res://scenes/first_hunt.tscn")

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	var carried_power := 0
	for level in range(1, 6):
		if level > 1:
			set_meta("first_hunt_spider_power", carried_power)
		var path := "res://scenes/first_hunt_%d.tscn" % level
		var scene: PackedScene = FIRST_LEVEL if level == 1 else load(path)
		var game = scene.instantiate()
		root.add_child(game)
		await process_frame
		assert(game.intro_mode and game.intro_level == level)
		assert(not game.economy_enabled)
		assert(not game.building and game.web_progress == 1.0)
		assert(game.rival != null and game.rival_active)
		assert(game.extra_rivals.is_empty())
		assert(game.rival_count_for_level() == 1)
		assert(game.compact_hunt())
		assert(game.intro_initial_bug_count() == mini(5, level + 2))
		assert(is_equal_approx(game.camera_zoom, game.COMPACT_CAMERA_ZOOM))
		if level == 5 and game.selected_style == 0:
			assert(game.spider.visual.self_modulate.g > game.spider.visual.self_modulate.r)
		assert(game.spider.position.y > game.rival.position.y)
		assert(game.FIRST_HUNT_BOUNDS.has_point(game.spider.position))
		assert(game.FIRST_HUNT_BOUNDS.has_point(game.rival.position))
		assert(not game.spider_step_is_clear(game.spider, game.FIRST_HUNT_BOUNDS.position - Vector2.ONE))
		assert(not game.spider_step_is_clear(game.rival, game.FIRST_HUNT_BOUNDS.end + Vector2.ONE))
		assert(game.spider.visual.scale == game.rival.visual.scale)
		assert(game.spider.health_bar.health == 100.0)
		assert(game.rival.health_bar.health == 100.0)
		if level == 1:
			assert(is_equal_approx(game.base_spider_speed, 175.0))
			assert(is_equal_approx(game.rival.speed, 170.0))
			assert(game.rival.visible and game.intro_reveal_active)
		assert(game.spider.visual.texture.get_size() == game.rival.visual.texture.get_size())
		assert(game.spider_step_is_clear(game.spider, game.rival.position))
		assert(game.spider_step_is_clear(game.rival, game.spider.position))
		for hunter in game.extra_rivals:
			assert(hunter.spider.visual.texture.get_size() == game.spider.visual.texture.get_size())
			assert(hunter.spider.visual.scale == game.spider.visual.scale)
			assert(hunter.spider.health_bar.health == 100.0)
		assert(game.player_power == carried_power)
		assert(game.bugs.size() == game.intro_initial_bug_count())
		assert(game.intro_goal() == 5 + (level - 1) * 5)
		assert(game.cut_button.visible and game.weave_button.visible)
		assert(game.boost_button.visible and game.stun_button.visible)
		assert(game.cut_button.text.is_empty() and game.weave_button.text.is_empty())
		assert(game.cut_button.get_node("PowerIcon") is TextureRect)
		assert(game.stun_button.get_node("PowerIcon") is TextureRect)
		assert(game.cut_button.get_node("Charge").text == "2")
		assert(game.game_hud.coins_label == game.coins_label)
		assert(game.game_hud.level_label.text == "LEVEL %d" % level)
		assert(game.game_hud.get_node_or_null("LevelPanel") == null)
		assert(game.game_hud.get_node("CoinPanel").position.x < game.game_hud.level_label.position.x)
		assert(game.game_hud.level_label.position.x < game.game_hud.get_node("TimerPanel").position.x)
		assert(game.game_hud.get_node("ClockIcon") is TextureRect)
		assert(game.game_hud.get_node("BugIcon") is TextureRect)
		assert(game.game_hud.get_node("CoinPanel") is TextureRect)
		assert(game.game_hud.bugs_label.visible)
		assert(game.game_hud.bugs_label.text == "0/%d" % game.intro_goal())
		assert(not game.shop_button.visible)
		assert(not game.game_hud.health_bar.visible)
		assert(not game.game_hud.instruction_label.visible)
		assert(game.game_hud.health_bar.value == 100)
		assert(game.game_hud.timer_label.text == "00:00")
		assert(game.ui_design.get_node_or_null("TopHudBand") == null)
		assert(game.ui_design.get_node_or_null("BottomHudBand") == null)
		assert(game.boost_button.position.y < game.stun_button.position.y)
		assert(game.stun_button.position.y < game.cut_button.position.y)
		assert(game.cut_button.position.y < game.weave_button.position.y)
		assert(game.weave_button.position.y < game.cancel_button.position.y)
		assert(game.boost_button.position.x == game.cut_button.position.x)
		assert(game.cut_button.get_node("ChargeBadge") is Panel)
		game.toggle_power_hud()
		assert(not game.powers_expanded and not game.cut_button.visible and not game.weave_button.visible)
		assert(game.power_toggle_button.visible and game.power_toggle_button.text == "")
		assert(game.power_toggle_icon.texture == game.POWERS_SHOW_ICON)
		game.toggle_power_hud()
		assert(game.powers_expanded and game.cut_button.visible and game.weave_button.visible)
		var occupied_nodes := {}
		var small := false
		var big := false
		for bug in game.bugs:
			assert(bug.active and bug.stuck and bug.permanently_trapped == (game.bugs.find(bug) % 3 != 2))
			assert(bug.health_bar.health == 100.0 if bug.permanently_trapped else bug.health_bar.health > 0.0 and bug.health_bar.health <= 100.0)
			assert(game.FIRST_HUNT_BOUNDS.has_point(bug.position))
			assert(not occupied_nodes.has(bug.route[0]))
			occupied_nodes[bug.route[0]] = true
			small = small or bug.size_factor < 1.0
			big = big or bug.size_factor > 1.0
		assert(small and big)
		game.bugs[0]._process(10000.0)
		assert(game.bugs[0].active and game.bugs[0].stuck)
		if level == 1:
			assert(game.intro_reveal_active)
			game.finish_intro_reveal()
			assert(not game.intro_reveal_active)
			var starting_position: Vector2 = game.spider.position
			game.spider.position = game.web_points[89]
			game.update_camera_position()
			if game.get_viewport().get_visible_rect().size.x / game.camera.zoom.x < game.FIRST_HUNT_BOUNDS.size.x:
				assert(game.camera.position.x < game.WEB_CENTER.x)
			else:
				assert(is_equal_approx(game.camera.position.x, game.FIRST_HUNT_BOUNDS.get_center().x))
			game.spider.position = game.web_points[86]
			game.update_camera_position()
			assert(game.camera.position.y < game.WEB_CENTER.y)
			game.spider.position = starting_position
			game.update_camera_position()
			game.rival_power = game.player_power + 1
			assert(game.rival_travel_speed(game.rival.speed, 1.3) <= game.base_spider_speed * 0.9)
			game._process(0.016)
			assert(game.threat_warning_active and game.threat_warning_panel.visible)
			await create_timer(0.85).timeout
			assert(game.camera.position.distance_to(game.warning_camera_position(game.rival.position)) < 12.0)
			assert(game.camera.get_screen_center_position().distance_to(game.rival.position) < 12.0)
			var warning_position: Vector2 = game.spider.position
			game._physics_process(0.5)
			assert(game.spider.position == warning_position)
			game.finish_threat_warning()
			assert(not game.threat_warning_active and not game.threat_warning_panel.visible)
			game.rival.position = game.spider.position + Vector2(300, 0)
			game.update_player_panic()
			assert(game.spider.panic_level > 0.4 and game.player_panic_audio.playing)
			game.rival.position = game.web_points[game.rival_node]
			game.rival_power = game.player_power
			game.update_player_panic()
			assert(game.spider.panic_level == 0.0)
			game.rival_power = game.player_power + 1
			assert(game.choose_rival_next_node() != game.rival_node)
			var chasing_from: Vector2 = game.rival.position
			game._physics_process(0.1)
			assert(game.rival.position != chasing_from)
			game.rival_power = game.player_power
			game._process(0.016)
			var rival_tap := InputEventScreenTouch.new()
			rival_tap.pressed = true
			rival_tap.position = game.get_canvas_transform() * game.rival.position
			game._unhandled_input(rival_tap)
			assert(game.chase_rival)
			var chase_position: Vector2 = game.spider.position
			game.spider.position = game.rival.position + Vector2(-300, 0)
			game.player_heading = Vector2.RIGHT
			game.update_rival_panic()
			assert(game.rival.panic_level > 0.4 and game.rival_panic_audio.playing)
			var panic_gait: float = game.rival.gait_phase
			game.rival.animate_walk(0.1, true)
			assert(game.rival.gait_phase - panic_gait > 1.8)
			game.spider.position = chase_position
			game.player_heading = Vector2.ZERO
			game.rival.set_panic(0.0)
			game.rival_panic_audio.stop()
			game.panicking_rivals.clear()
			game.cancel_auto_navigation()
			game.coins = 100
			game.toggle_shop()
			assert(game.shop_open and game.shop_panel.visible)
			var paused_position: Vector2 = game.spider.position
			game._physics_process(0.5)
			assert(game.spider.position == paused_position)
			game.choose_spider_style(1)
			assert(game.selected_style == 1 and game.coins == 70)
			assert(game.base_spider_speed > 175.0)
			game.choose_spider_style(2)
			assert(game.selected_style == 2 and game.cloak_button.visible)
			assert(game.cloak_button.get_node_or_null("RewardAdButton") is Button)
			game.toggle_shop()
			game.use_cloak()
			game.rival_power = 1
			game.rival.position = game.spider.position + Vector2(100, 0)
			game.resolve_solo_collision()
			assert(game.player_active and game.cloak_remaining > 0.0)
			game.cloak_remaining = 0.0
			game.rival_power = 0
			game.rival.position = game.web_points[game.SOLO_RIVAL_START]
			game.coins = 100
			game.choose_spider_style(3)
			assert(game.selected_style == 3 and game.player_catch_radius() > 100.0)
			var start_size: float = game.spider.visual.scale.x
			game.use_speed_boost()
			assert(game.spider.speed > game.base_spider_speed and game.boost_charges == 1)
			game.use_rival_stun()
			assert(game.rival_stun_remaining > 0.0 and game.stun_charges == 1)
			assert(game.rival.get_node_or_null("FreezeEffect") != null)
			var cut_index: int = game.edge_index(0, 28)
			assert(game.cut_edge(cut_index, 1))
			assert(not game.edge_active[cut_index] and game.cut_charges == 1)
			game.spider_node = 0
			game.spider_target = 29
			game.rival.position = game.spider.position + Vector2(200, 0)
			var rival_cut_index: int = game.edge_index(0, 29)
			game.rival_stun_remaining = 0.0
			game.use_rival_ai_power()
			assert(game.edge_active[rival_cut_index] and game.rival_cut_charges == 0)
			assert(game.player_stun_remaining == 0.0 and game.rival_stun_charges == 0)
			assert(is_equal_approx(game.rival.speed, game.base_rival_speed()) and game.rival_boost_charges == 0)
			game.spider_node = game.SOLO_PLAYER_START
			game.spider_target = game.spider_node
			game.spider_retreating = false
			for torn_index in game.bugs[0].web_cut_edges:
				game.restore_edge(torn_index, 1)
			game.catch_bug(game.bugs[0], 1)
			assert(game.bugs[0].health_bar.health == 0.0)
			game.player_eat_remaining = 0.0
			game.finish_eating(1)
			assert(game.spider.visual.scale.x > start_size)
			var flying_coins := 0
			for item in game.ui_root.get_children():
				if item is TextureRect and item.texture == game.REWARD_COIN:
					flying_coins += 1
			assert(flying_coins == 0)
			var spawned_before: int = game.bugs.size()
			game.rival_active = false
			game._process(2.6)
			assert(game.bugs.size() == spawned_before + 1)
			var arriving_bug: TrapBug = game.bugs.back()
			assert(arriving_bug.arriving and not arriving_bug.active and not arriving_bug.stuck)
			assert(arriving_bug.position.y < arriving_bug.arrival_target.y)
			arriving_bug._process(0.8)
			assert(arriving_bug.arriving and not arriving_bug.active)
			arriving_bug._process(0.9)
			assert(not arriving_bug.arriving and arriving_bug.active and arriving_bug.stuck)
			game.rival_active = true
			game.rival_caught_count = 5
			game.rival_power = 0
			game.rival.position = game.spider.position + Vector2(100, 0)
			game.resolve_solo_collision()
			assert(not game.rival_active and game.caught_count == 1)
			assert(game.player_rival_eat_remaining > 0.0)
			game._physics_process(game.RIVAL_EAT_DURATION + 0.01)
			assert(game.caught_count == 3)
			game.respawn_solo_rival()
			assert(game.rival_active and game.rival.visual.scale == game.spider.visual.scale)
			game.rival_power = game.player_power + 1
			game.rival.position = game.spider.position + Vector2(100, 0)
			game.resolve_solo_collision()
			assert(not game.player_active and game.finished and game.winner == 2)
			assert(game.game_hud.health_bar.value == 0)
			assert(game.spider.health_bar.health == 0.0)
			assert(game.result_panel.visible and game.result_dimmer.visible)
			assert(game.result_title.text == "GAME OVER")
			assert(game.retry_button.visible and not game.next_button.visible)
			game._process(5.0)
			assert(not game.player_active and game.finished)
			game.restart()
			assert(game.player_active and not game.finished)
			assert(game.rival_active and game.rival.visible)
			assert(game.game_hud.health_bar.value == 100)
			assert(game.spider.health_bar.health == 100.0)
			assert(not game.result_panel.visible and not game.result_dimmer.visible)
			assert(game.caught_count == 0)
			while game.caught_count < game.intro_goal():
				var target: TrapBug
				for bug in game.bugs:
					if bug.active:
						target = bug
						break
				if target == null:
					game.spawn_solo_bug()
					target = game.bugs.back()
					target._process(1.7)
				game.catch_bug(target, 1)
				game.player_eat_remaining = 0.0
				game.finish_eating(1)
			assert(game.finished and game.winner == 1)
			assert(game.caught_count == 5 and game.next_button.visible)
			assert(game.result_panel.visible and game.result_dimmer.visible)
			assert(game.result_panel.texture == game.RESULT_VICTORY)
			assert(game.result_stars.get_child_count() == 3)
			assert(game.result_reward.text == "+5 COINS")
			assert(game.escaped_count == 0)
			for bug in game.bugs:
				assert(not bug.visible)
			carried_power = game.player_power
		else:
			game.restart()
			assert(game.player_power == carried_power)
			assert(game.spider.visual.scale == game.rival.visual.scale)
		assert(ResourceLoader.exists(game.next_scene_path()))
		game.free()
	set_meta("first_hunt_spider_power", carried_power)
	set_meta("first_hunt_level", 6)
	var next_level = FIRST_LEVEL.instantiate()
	root.add_child(next_level)
	await process_frame
	assert(next_level.intro_level == 6 and next_level.intro_goal() == 30)
	assert(is_equal_approx(next_level.spider.visual.scale.x, next_level.solo_scale_for_power(carried_power)))
	assert(next_level.next_scene_path() == "res://scenes/first_hunt.tscn")
	assert(not next_level.compact_hunt() and not next_level.extra_rivals.is_empty())
	var hunter = next_level.extra_rivals[0]
	var hunter_start_power: int = hunter.power
	var hunter_start_bugs: int = hunter.bugs_eaten
	next_level.extra_rival_catch_bug(hunter, next_level.bugs[0])
	assert(hunter.power == hunter_start_power + 1 and hunter.bugs_eaten == hunter_start_bugs + 1)
	assert(next_level.threat_warning_active)
	next_level.finish_threat_warning()
	assert(next_level.next_step_from(hunter.home, next_level.SOLO_PLAYER_START) != hunter.home)
	hunter.power = next_level.rival_power + 1
	hunter.bugs_eaten = 4
	hunter.spider.position = next_level.rival.position + Vector2(80, 0)
	next_level.resolve_rival_duels()
	assert(not next_level.rival_active and hunter.power > next_level.player_power)
	assert(hunter.bugs_eaten == 5)
	next_level.respawn_solo_rival()
	assert(next_level.rival_active)
	next_level.rival_power = hunter.power + 1
	next_level.rival.position = hunter.spider.position + Vector2(80, 0)
	next_level.resolve_rival_duels()
	assert(not hunter.active and next_level.rival_power > next_level.player_power)
	next_level.respawn_extra_rival(hunter)
	assert(hunter.active)
	hunter.power = next_level.player_power + 1
	hunter.spider.position = next_level.spider.position + Vector2(90, 0)
	next_level.resolve_player_rival_collision(hunter.spider)
	assert(not next_level.player_active and next_level.finished and next_level.winner == 2)
	next_level.free()
	print("SPIDER_WARS_FIVE_SOLO_LEVELS_PASS")
	quit()
