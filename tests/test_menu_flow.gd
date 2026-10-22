extends SceneTree

const MAIN = preload("res://scenes/main_menu.tscn")
const SETTINGS = preload("res://scenes/settings.tscn")
const SHOP = preload("res://scenes/shop.tscn")
const SOUND = preload("res://scripts/sound.gd")

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	var music_loop: AudioStreamWAV = SOUND.make_music_loop()
	assert(music_loop.loop_end > 0)
	assert(music_loop.data.size() >= (music_loop.loop_end + 4) * 2)
	var app_settings = root.get_node("AppSettings")
	var manager = root.get_node("GameManager")
	var hub = root.get_node("SignalHub")
	var balances: Array[int] = []
	var music_events: Array[bool] = []
	var sfx_events: Array[bool] = []
	hub.coins_changed.connect(func(balance: int) -> void: balances.append(balance))
	hub.music_changed.connect(func(enabled: bool) -> void: music_events.append(enabled))
	hub.sfx_changed.connect(func(enabled: bool) -> void: sfx_events.append(enabled))
	var menu = MAIN.instantiate()
	root.add_child(menu)
	await process_frame
	assert(menu.design != null)
	var play_button: Button
	for child in menu.design.get_children():
		assert(not child is Panel)
		if child is Button and play_button == null:
			play_button = child
	assert(play_button != null)
	var store_button := menu.design.get_node("StoreButton") as Button
	assert(store_button.visible and store_button.text == "STORE")
	assert(store_button.get_child_count() == 1 and store_button.get_child(0).texture == menu.STORE_ICON)
	assert(play_button.get_theme_stylebox("normal") is StyleBoxEmpty)
	assert(play_button.get_node_or_null("Emblem") == null)
	menu.queue_free()
	await process_frame
	var settings = SETTINGS.instantiate()
	root.add_child(settings)
	await process_frame
	var original_music: bool = app_settings.music_enabled
	var original_sfx: bool = app_settings.sfx_enabled
	settings.toggle_music()
	settings.toggle_sfx()
	assert(app_settings.music_enabled != original_music)
	assert(app_settings.sfx_enabled != original_sfx)
	assert(settings.music_button.text.contains("OFF") == original_music)
	assert(settings.remove_ads_button.text == "REMOVE ADS  $4.99")
	assert(settings.remove_ads_button.disabled)
	assert(music_events.back() == app_settings.music_enabled)
	assert(sfx_events.back() == app_settings.sfx_enabled)
	app_settings.set_music_enabled(original_music)
	app_settings.set_sfx_enabled(original_sfx)
	settings.queue_free()
	await process_frame
	var shop = SHOP.instantiate()
	root.add_child(shop)
	await process_frame
	manager.set_coins(0)
	assert(shop.coins == 0 and shop.screen_title() == "POWERUP STORE")
	for button in shop.power_buttons:
		assert(button.disabled)
	manager.set_coins(100)
	var boost_stock_before: int = manager.power_stock["boost"]
	shop.buy_power("boost")
	assert(manager.coins == 95 and manager.power_stock["boost"] == boost_stock_before + 1)
	assert(balances == [0, 100, 95])
	assert(shop.power_buttons.size() == manager.POWER_KEYS.size() and shop.coin_purchase_button.disabled)
	assert(shop.coin_purchase_button.text.contains("$2.00"))
	assert(root.get_node("BillingManager").COIN_PRODUCT_ID == "coins1")
	assert(root.get_node("BillingManager").COIN_PURCHASE_REWARD == 100)
	var hunt_game = load("res://scenes/first_hunt.tscn").instantiate()
	root.add_child(hunt_game)
	await process_frame
	assert(hunt_game.boost_charges == hunt_game.START_BOOST_CHARGES + boost_stock_before + 1)
	assert(manager.power_stock["boost"] == 0)
	var ids := ConfigFile.new()
	assert(ids.load("res://config/admob_test.cfg") == OK)
	assert(str(ids.get_value("android", "app_id")).contains("~"))
	assert(str(ids.get_value("android", "rewarded_unit_id")).contains("/"))
	print("SPIDER_TERRITORY_MENU_PASS")
	quit()
