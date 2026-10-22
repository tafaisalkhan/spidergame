extends Node

const SAVE_PATH := "user://spider_wars_progress.cfg"
const STYLE_NAMES := ["CLASSIC", "SWIFT", "SHADE", "HUNTER", "GIANT"]
const STYLE_COSTS := [0, 30, 45, 60, 75]
const POWER_KEYS := ["cut", "weave", "boost", "stun", "timer", "cloak"]
const POWER_COST := 5

var coins := 0
var unlocked_styles: Array[bool] = [true, false, false, false, false]
var selected_style := 0
var power_stock := {"cut": 0, "weave": 0, "boost": 0, "stun": 0, "timer": 0, "cloak": 0}
var current_level := 1
var bugs_next_level := 1
var rival_next_level := 1
var rival_levels := false
var bugs_mode := false

func _ready() -> void:
	load_progress()

func load_progress() -> void:
	if OS.get_cmdline_args().has("--script"):
		return
	var save := ConfigFile.new()
	if save.load(SAVE_PATH) != OK:
		return
	coins = maxi(0, int(save.get_value("shop", "coins", 0)))
	bugs_next_level = maxi(1, int(save.get_value("levels", "bugs_next", 1)))
	rival_next_level = maxi(1, int(save.get_value("levels", "rival_next", 1)))
	for key in POWER_KEYS:
		power_stock[key] = maxi(0, int(save.get_value("shop", "power_%s" % key, 0)))
	if save.has_section("bugs_mode"):
		save.erase_section("bugs_mode")
		save.save(SAVE_PATH)
	for i in range(1, STYLE_NAMES.size()):
		unlocked_styles[i] = bool(save.get_value("shop", "unlocked_%d" % i, false))
	selected_style = clampi(int(save.get_value("shop", "selected", 0)), 0, STYLE_NAMES.size() - 1)
	if not unlocked_styles[selected_style]:
		selected_style = 0

func save_progress() -> void:
	if OS.get_cmdline_args().has("--script"):
		return
	var save := ConfigFile.new()
	save.load(SAVE_PATH)
	save.set_value("shop", "coins", coins)
	save.set_value("levels", "bugs_next", bugs_next_level)
	save.set_value("levels", "rival_next", rival_next_level)
	for key in POWER_KEYS:
		save.set_value("shop", "power_%s" % key, power_stock[key])
	if save.has_section("bugs_mode"):
		save.erase_section("bugs_mode")
	save.set_value("shop", "selected", selected_style)
	for i in range(1, STYLE_NAMES.size()):
		save.set_value("shop", "unlocked_%d" % i, unlocked_styles[i])
	save.save(SAVE_PATH)

func set_coins(value: int) -> void:
	coins = maxi(0, value)
	save_progress()
	get_node("/root/SignalHub").coins_changed.emit(coins)

func add_coins(amount: int) -> void:
	if amount > 0:
		set_coins(coins + amount)

func purchase_power(key: String) -> bool:
	if not POWER_KEYS.has(key) or coins < POWER_COST:
		return false
	power_stock[key] += 1
	set_coins(coins - POWER_COST)
	return true

func take_power_stock(key: String) -> int:
	if not POWER_KEYS.has(key):
		return 0
	var amount: int = power_stock[key]
	if amount > 0:
		power_stock[key] = 0
		save_progress()
	return amount

func purchase_or_select_style(index: int) -> bool:
	if index < 0 or index >= STYLE_NAMES.size():
		return false
	if not unlocked_styles[index]:
		if coins < STYLE_COSTS[index]:
			return false
		coins -= STYLE_COSTS[index]
		unlocked_styles[index] = true
		get_node("/root/SignalHub").coins_changed.emit(coins)
	selected_style = index
	save_progress()
	get_node("/root/SignalHub").spider_selected.emit(index)
	return true

func sync_from_campaign(balance: int, unlocks: Array[bool], style: int) -> void:
	coins = maxi(0, balance)
	for i in STYLE_NAMES.size():
		unlocked_styles[i] = unlocks[i]
	selected_style = clampi(style, 0, STYLE_NAMES.size() - 1)
	save_progress()
	get_node("/root/SignalHub").coins_changed.emit(coins)
	get_node("/root/SignalHub").spider_selected.emit(selected_style)

func show_scene(path: String) -> void:
	if path in ["res://scenes/main_menu.tscn", "res://scenes/shop.tscn", "res://scenes/settings.tscn"]:
		get_node("/root/AdsManager").show_banner()
	else:
		get_node("/root/AdsManager").hide_banner()
	get_node("/root/SignalHub").screen_changed.emit(path)
	get_tree().change_scene_to_file(path)

func start_first_hunt(as_bugs := false) -> void:
	rival_levels = false
	bugs_mode = as_bugs
	current_level = bugs_next_level if as_bugs else 1
	if get_tree().has_meta("first_hunt_level"):
		get_tree().remove_meta("first_hunt_level")
	if get_tree().has_meta("first_hunt_spider_power"):
		get_tree().remove_meta("first_hunt_spider_power")
	if get_tree().has_meta("first_hunt_rival_levels"):
		get_tree().remove_meta("first_hunt_rival_levels")
	if as_bugs:
		get_tree().set_meta("first_hunt_level", current_level)
	get_tree().set_meta("first_hunt_bugs_mode", bugs_mode)
	show_scene("res://scenes/first_hunt.tscn")

func start_bugs_mode() -> void:
	start_first_hunt(true)

func start_rival_levels() -> void:
	rival_levels = true
	bugs_mode = false
	current_level = rival_next_level
	if get_tree().has_meta("first_hunt_level"):
		get_tree().remove_meta("first_hunt_level")
	get_tree().set_meta("first_hunt_level", current_level)
	if get_tree().has_meta("first_hunt_spider_power"):
		get_tree().remove_meta("first_hunt_spider_power")
	get_tree().set_meta("first_hunt_rival_levels", true)
	if get_tree().has_meta("first_hunt_bugs_mode"):
		get_tree().remove_meta("first_hunt_bugs_mode")
	show_scene("res://scenes/first_hunt.tscn")

func advance_first_hunt(level: int, power: int) -> void:
	current_level = maxi(1, level)
	get_tree().set_meta("first_hunt_level", current_level)
	get_tree().set_meta("first_hunt_spider_power", maxi(0, power))
	get_tree().set_meta("first_hunt_rival_levels", rival_levels)
	get_tree().set_meta("first_hunt_bugs_mode", bugs_mode)
	show_scene("res://scenes/first_hunt.tscn")

func notify_level_completed(level: int, bug_count: int) -> void:
	current_level = level
	if bugs_mode:
		bugs_next_level = maxi(bugs_next_level, level + 1)
	elif rival_levels:
		rival_next_level = maxi(rival_next_level, level + 1)
	save_progress()
	get_node("/root/SignalHub").level_completed.emit(level, bug_count)
