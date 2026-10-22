extends "res://scripts/ui/MenuScreenBase.gd"

const BACK_ICON = preload("res://assets/ui/menu_back.svg")
const COIN_SOUND = preload("res://assets/sound/coin_sound.wav")
const POWER_ICONS = [
	preload("res://assets/ui/power_cut.svg"),
	preload("res://assets/ui/power_web.svg"),
	preload("res://assets/ui/power_speed.svg"),
	preload("res://assets/ui/power_freeze.svg"),
	preload("res://assets/ui/hud_clock.svg"),
	preload("res://assets/ui/power_cloak.svg")
]

var coins := 0
var coin_label: Label
var reward_button: Button
var coin_purchase_button: Button
var power_buttons: Array[Button] = []

func screen_title() -> String:
	return "POWERUP STORE"

func build_content() -> void:
	var hub := get_node("/root/SignalHub")
	hub.coins_changed.connect(refresh_from_manager.unbind(1))
	coin_label = make_label("", 42, Color(1.0, 0.86, 0.45))
	coin_label.position = Vector2(1430, 325)
	coin_label.size = Vector2(200, 50)
	coin_label.z_index = 1
	design.add_child(coin_label)
	var coin_icon := TextureRect.new()
	coin_icon.texture = COIN
	coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_icon.position = Vector2(1360, 320)
	coin_icon.size = Vector2(66, 66)
	coin_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	design.add_child(coin_icon)
	var manager := get_node("/root/GameManager")
	var powers_title := make_label("CHOOSE A POWERUP  •  1 CHARGE COSTS 5 COINS", 34, Color(0.86, 1.0, 0.78))
	powers_title.position = Vector2(70, 340)
	powers_title.size = Vector2(1120, 65)
	design.add_child(powers_title)
	var power_names := ["CUT WEB", "CREATE WEB", "SPEED", "FREEZE", "TIMER", "INVISIBLE"]
	for i in manager.POWER_KEYS.size():
		var button := make_button("", Vector2(70 + (i % 3) * 600, 435 + (i / 3) * 160), 130.0)
		button.name = "PowerPurchase%d" % i
		button.size.x = 550.0
		button.alignment = HORIZONTAL_ALIGNMENT_RIGHT
		button.add_theme_font_size_override("font_size", 27)
		button.pressed.connect(buy_power.bind(manager.POWER_KEYS[i]))
		button.set_meta("power_name", power_names[i])
		var icon := TextureRect.new()
		icon.texture = POWER_ICONS[i]
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.position = Vector2(10, 16)
		icon.size = Vector2(94, 94)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(icon)
		power_buttons.append(button)
	refresh_from_manager()
	reward_button = make_button("WATCH AD: +5 COINS", Vector2(70, 810), 100.0, COIN)
	reward_button.size.x = 790.0
	reward_button.add_theme_font_size_override("font_size", 32)
	reward_button.pressed.connect(watch_rewarded_ad)
	coin_purchase_button = make_button("", Vector2(930, 810), 100.0, COIN)
	coin_purchase_button.size.x = 790.0
	coin_purchase_button.add_theme_font_size_override("font_size", 34)
	coin_purchase_button.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.22, 0.16, 0.04, 0.94)
	box.border_color = Color(1.0, 0.79, 0.25)
	box.set_border_width_all(3)
	box.set_corner_radius_all(18)
	coin_purchase_button.add_theme_stylebox_override("normal", box)
	coin_purchase_button.add_theme_stylebox_override("hover", box)
	coin_purchase_button.add_theme_stylebox_override("pressed", box)
	var coin_box_icon := TextureRect.new()
	coin_box_icon.texture = COIN
	coin_box_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_box_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_box_icon.position = Vector2(10, 12)
	coin_box_icon.size = Vector2(78, 76)
	coin_box_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin_purchase_button.add_child(coin_box_icon)
	coin_purchase_button.pressed.connect(buy_coin_box)
	var billing := get_node("/root/BillingManager")
	billing.coin_price_changed.connect(update_coin_purchase_button.unbind(1))
	billing.coin_purchase_changed.connect(on_coin_purchase_owned.unbind(1))
	billing.billing_failed.connect(show_coin_purchase_error)
	update_coin_purchase_button()
	var ads := get_node("/root/AdsManager")
	ads.rewarded_ready_changed.connect(update_reward_button.unbind(1))
	ads.reward_granted.connect(on_reward_granted)
	ads.ad_load_failed.connect(on_ad_load_failed)
	update_reward_button()
	status_label.position = Vector2(70, 950)
	status_label.size = Vector2(1280, 70)
	status_label.text = "Buy one power charge for 5 coins."
	var back_button := make_button("BACK", Vector2(1450, 935), 100.0, BACK_ICON)
	back_button.size.x = 300.0
	back_button.pressed.connect(open_scene.bind("res://scenes/main_menu.tscn"))

func refresh_from_manager() -> void:
	var manager := get_node("/root/GameManager")
	coins = manager.coins
	coin_label.text = "%d" % coins
	for i in power_buttons.size():
		var key: String = manager.POWER_KEYS[i]
		power_buttons[i].text = "%s  +1\nOWNED: %d" % [power_buttons[i].get_meta("power_name"), manager.power_stock[key]]
		power_buttons[i].disabled = coins < manager.POWER_COST

func buy_power(key: String) -> void:
	var manager := get_node("/root/GameManager")
	if manager.purchase_power(key):
		status_label.text = "+1 %s CHARGE PURCHASED" % key.to_upper()
	else:
		status_label.text = "Need 5 coins. Complete a level or watch an ad."

func update_coin_purchase_button() -> void:
	var billing := get_node("/root/BillingManager")
	coin_purchase_button.text = "100 COINS  OWNED" if billing.coin_purchase_owned else "100 COINS  %s" % billing.coin_displayed_price
	coin_purchase_button.disabled = billing.coin_purchase_owned or billing.plugin == null

func buy_coin_box() -> void:
	if get_node("/root/BillingManager").purchase_coins():
		status_label.text = "Opening Google Play purchase for 100 coins..."

func on_coin_purchase_owned() -> void:
	update_coin_purchase_button()
	status_label.text = "100 COINS ADDED TO YOUR BALANCE"
	var sound := AudioStreamPlayer.new()
	sound.stream = COIN_SOUND
	sound.finished.connect(sound.queue_free)
	add_child(sound)
	sound.play()

func show_coin_purchase_error(message: String) -> void:
	status_label.text = message

func update_reward_button() -> void:
	reward_button.disabled = false
	reward_button.text = "WATCH AD: +5 COINS" if get_node("/root/AdsManager").is_rewarded_ready() else "AD LOADING..."

func on_ad_load_failed(format: String, _reason: String) -> void:
	if format == "rewarded":
		status_label.text = "Rewarded ad unavailable. Check connection and try again."

func watch_rewarded_ad() -> void:
	if get_node("/root/AdsManager").show_rewarded_coins():
		status_label.text = "Finish the ad to earn 5 coins."
	else:
		status_label.text = "Rewarded ad is loading."

func on_reward_granted(amount: int) -> void:
	var sound := AudioStreamPlayer.new()
	sound.stream = COIN_SOUND
	sound.finished.connect(sound.queue_free)
	add_child(sound)
	sound.play()
	status_label.text = "+%d COINS EARNED" % amount
