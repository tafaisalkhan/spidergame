extends SceneTree

const FIRST_HUNT = preload("res://scenes/first_hunt.tscn")

class FakeResultAds:
	extends RefCounted
	signal rewarded_loaded
	signal reward_earned
	signal rewarded_finished
	var banners_shown := 0
	var rewarded_shown := false
	var rewarded_ready := true

	func showBanner(_unit_id: String) -> void:
		banners_shown += 1

	func hideBanner() -> void:
		pass

	func isInterstitialReady() -> bool:
		return false

	func isRewardedReady() -> bool:
		return rewarded_ready

	func showRewarded() -> void:
		rewarded_shown = true
		rewarded_ready = false

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	var ads = root.get_node("AdsManager")
	var fake := FakeResultAds.new()
	ads.plugin = fake
	fake.rewarded_loaded.connect(ads._on_rewarded_loaded)
	fake.reward_earned.connect(ads._on_reward_earned)
	fake.rewarded_finished.connect(ads._on_rewarded_finished)
	fake.rewarded_loaded.emit()
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1600, 720)
	viewport.handle_input_locally = true
	root.add_child(viewport)
	var game = FIRST_HUNT.instantiate()
	viewport.add_child(game)
	await process_frame
	if game.intro_reveal_active:
		game.finish_intro_reveal()
	tap_button(viewport, game.power_toggle_button)
	await process_frame
	assert(not game.powers_expanded)
	tap_button(viewport, game.power_toggle_button)
	await process_frame
	assert(game.powers_expanded)
	var starting_zoom: float = game.camera.zoom.x
	touch(viewport, 0, Vector2(140, 360), true)
	touch(viewport, 1, Vector2(340, 360), true)
	drag_touch(viewport, 1, Vector2(540, 360))
	await process_frame
	assert(game.camera.zoom.x > starting_zoom)
	drag_touch(viewport, 1, Vector2(290, 360))
	await process_frame
	assert(game.camera.zoom.x < starting_zoom)
	touch(viewport, 1, Vector2(290, 360), false)
	touch(viewport, 0, Vector2(140, 360), false)
	game.winner = 2
	game.finish_match()
	var fail_sound_started := false
	for child in game.get_children():
		if child is AudioStreamPlayer and child.stream == game.LEVEL_FAIL_SOUND and child.playing:
			fail_sound_started = true
	assert(fail_sound_started)
	await create_timer(0.6).timeout
	assert(game.result_panel.visible and game.retry_button.visible)
	assert(game.result_panel.texture.resource_path == "res://assets/ui/result-failure.png")
	assert(game.retry_button.get_theme_stylebox("normal") is StyleBoxTexture)
	assert(game.result_menu_button.get_theme_stylebox("normal") is StyleBoxTexture)
	assert(game.retry_button.icon != null and game.result_menu_button.icon != null)
	assert(game.retry_button.text.is_empty() and game.result_menu_button.text.is_empty())
	assert(game.result_reward_ad_button.visible)
	assert(game.result_reward_ad_button.get_theme_color("font_color") == Color.WHITE)
	assert(game.result_reward_ad_button.get_theme_color("font_disabled_color") == Color.WHITE)
	assert(fake.banners_shown == 1 and not game.result_reward_ad_button.disabled)
	var coins_before_ad: int = root.get_node("GameManager").coins
	game.result_reward_ad_button.pressed.emit()
	assert(fake.rewarded_shown and root.get_node("GameManager").coins == coins_before_ad)
	fake.reward_earned.emit()
	assert(root.get_node("GameManager").coins == coins_before_ad + 5)
	fake.rewarded_finished.emit()
	assert(game.result_dimmer.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	tap_button(viewport, game.retry_button)
	await process_frame
	assert(not game.finished and not game.result_panel.visible)
	game.winner = 1
	game.finish_match()
	var complete_sound_started := false
	for child in game.get_children():
		if child is AudioStreamPlayer and child.stream == game.LEVEL_COMPLETE_SOUND and child.playing:
			complete_sound_started = true
	assert(complete_sound_started)
	await create_timer(0.6).timeout
	assert(game.next_button.visible)
	assert(fake.banners_shown == 2)
	assert(game.next_button.get_theme_stylebox("normal") is StyleBoxTexture)
	assert(game.next_button.icon != null)
	assert(game.next_button.text.is_empty())
	assert(game.result_panel.texture.resource_path == "res://assets/ui/result-victory.png")
	var star_sound_playing := false
	for child in game.get_children():
		if child is AudioStreamPlayer and child.stream == game.STAR_SOUND and child.playing:
			star_sound_playing = true
	assert(star_sound_playing)
	await create_timer(0.2).timeout
	var coin_sound_playing := false
	for child in game.get_children():
		if child is AudioStreamPlayer and child.stream == game.COIN_SOUND and child.playing:
			coin_sound_playing = true
	assert(coin_sound_playing)
	var pressed := [false]
	game.next_button.pressed.connect(func(): pressed[0] = true)
	tap_button(viewport, game.next_button)
	await process_frame
	assert(pressed[0])
	await process_frame
	assert(current_scene != null and current_scene.intro_level == 2)
	print("SPIDER_WARS_RESULT_BUTTONS_PASS")
	quit()

func tap_button(viewport: SubViewport, button: Button) -> void:
	var point := button.get_global_rect().get_center()
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = point
	viewport.push_input(down, true)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = point
	viewport.push_input(up, true)

func touch(viewport: SubViewport, index: int, at: Vector2, down: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = at
	event.pressed = down
	viewport.push_input(event, true)

func drag_touch(viewport: SubViewport, index: int, at: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = at
	viewport.push_input(event, true)
