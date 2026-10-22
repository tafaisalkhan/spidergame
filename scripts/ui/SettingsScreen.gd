extends "res://scripts/ui/MenuScreenBase.gd"

const MUSIC_ICON = preload("res://assets/ui/menu_music.svg")
const SFX_ICON = preload("res://assets/ui/menu_sfx.svg")
const ADS_ICON = preload("res://assets/ui/menu_ads.svg")
const BACK_ICON = preload("res://assets/ui/menu_back.svg")

var music_button: Button
var sfx_button: Button
var remove_ads_button: Button

func screen_title() -> String:
	return "SETTINGS"

func build_content() -> void:
	music_button = make_button("", Vector2(990, 290), 120.0, MUSIC_ICON)
	music_button.pressed.connect(toggle_music)
	sfx_button = make_button("", Vector2(990, 445), 120.0, SFX_ICON)
	sfx_button.pressed.connect(toggle_sfx)
	var hub := get_node("/root/SignalHub")
	hub.music_changed.connect(update_settings.unbind(1))
	hub.sfx_changed.connect(update_settings.unbind(1))
	update_settings()
	remove_ads_button = make_button("", Vector2(990, 600), 120.0, ADS_ICON)
	remove_ads_button.pressed.connect(buy_remove_ads)
	var billing := get_node("/root/BillingManager")
	billing.price_changed.connect(update_remove_ads_button.unbind(1))
	billing.purchase_changed.connect(update_remove_ads_button.unbind(1))
	billing.billing_failed.connect(show_billing_error)
	update_remove_ads_button()
	make_button("BACK", Vector2(990, 760), 110.0, BACK_ICON).pressed.connect(open_scene.bind("res://scenes/main_menu.tscn"))

func toggle_music() -> void:
	var settings := get_node("/root/AppSettings")
	settings.set_music_enabled(not settings.music_enabled)

func toggle_sfx() -> void:
	var settings := get_node("/root/AppSettings")
	settings.set_sfx_enabled(not settings.sfx_enabled)

func update_settings() -> void:
	var settings := get_node("/root/AppSettings")
	music_button.text = "MUSIC: ON" if settings.music_enabled else "MUSIC: OFF"
	sfx_button.text = "SFX: ON" if settings.sfx_enabled else "SFX: OFF"

func update_remove_ads_button() -> void:
	var billing := get_node("/root/BillingManager")
	remove_ads_button.text = "ADS REMOVED" if billing.remove_ads_owned else "REMOVE ADS  %s" % billing.displayed_price
	remove_ads_button.disabled = billing.remove_ads_owned or billing.plugin == null
	status_label.text = "Ads removed from this account." if billing.remove_ads_owned else ("Purchase through Google Play." if billing.plugin != null else "Purchase available from Google Play on Android.")

func buy_remove_ads() -> void:
	if get_node("/root/BillingManager").purchase_remove_ads():
		status_label.text = "Opening Google Play purchase..."

func show_billing_error(message: String) -> void:
	status_label.text = message
