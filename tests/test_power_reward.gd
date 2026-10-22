extends SceneTree

const FIRST_LEVEL = preload("res://scenes/first_hunt.tscn")

class FakeRewardAds:
	extends RefCounted
	signal rewarded_loaded
	signal reward_earned
	signal rewarded_finished
	var ready := true
	var shown := false

	func isRewardedReady() -> bool:
		return ready

	func showRewarded() -> void:
		shown = true
		ready = false

	func hideBanner() -> void:
		pass

	func showBanner(_unit_id: String) -> void:
		pass

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	var ads = root.get_node("AdsManager")
	var fake := FakeRewardAds.new()
	ads.plugin = fake
	fake.rewarded_loaded.connect(ads._on_rewarded_loaded)
	fake.reward_earned.connect(ads._on_reward_earned)
	fake.rewarded_finished.connect(ads._on_rewarded_finished)
	fake.rewarded_loaded.emit()
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1600, 720)
	viewport.handle_input_locally = true
	root.add_child(viewport)
	var game = FIRST_LEVEL.instantiate()
	viewport.add_child(game)
	await process_frame
	game.finish_intro_reveal()
	var reward_button: Button = game.weave_button.get_node("RewardAdButton")
	assert(not reward_button.visible)
	game.build_charges = 1
	game.spider_target = game.spider_node
	var repair_edge: int = game.edge_index(game.spider_node, int(game.adjacency[game.spider_node][0]))
	game.edge_active[repair_edge] = false
	assert(game.begin_player_repair(repair_edge))
	var starting_charges: int = game.build_charges
	var power_icon: TextureRect = game.weave_button.get_node("PowerIcon")
	var charge_badge: Panel = game.weave_button.get_node("ChargeBadge")
	assert(reward_button.get_rect().intersects(power_icon.get_rect()))
	assert(power_icon.size.x >= 80.0 and power_icon.size.y >= 80.0)
	assert(charge_badge.visible)
	assert(reward_button.position == Vector2.ZERO and reward_button.size == game.weave_button.size)
	var video_icon: TextureRect = reward_button.get_node("VideoIcon")
	assert(video_icon.size.x >= 80.0 and video_icon.size.y >= 70.0)
	assert(game.weave_button.disabled and reward_button.visible)
	var press_point := reward_button.get_global_rect().get_center()
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = press_point
	viewport.push_input(down, true)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.position = press_point
	viewport.push_input(up, true)
	assert(paused and fake.shown and game.build_charges == starting_charges)
	fake.reward_earned.emit()
	assert(paused and game.build_charges == starting_charges + 2)
	fake.rewarded_finished.emit()
	assert(not paused and game.weave_button.get_node("Charge").text == "%d" % (starting_charges + 2))
	assert(not reward_button.visible)
	game.free()
	print("SPIDER_WARS_POWER_REWARD_PASS")
	quit()
