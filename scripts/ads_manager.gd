extends Node

signal rewarded_ready_changed(ready: bool)
signal reward_granted(amount: int)
signal ad_load_failed(format: String, reason: String)

const TEST_IDS := "res://config/admob_test.cfg"
const REWARDED_COINS := 5

var plugin: Object
var banner_id := ""
var interstitial_id := ""
var rewarded_id := ""
var rewarded_ready := false
var pending_interstitial_action: Callable
var reward_pending := false
var pending_reward_action: Callable
var reward_paused_game := false
var was_paused_before_reward := false
var preview_mode := false
var preview_layer: CanvasLayer
var preview_top: ColorRect
var preview_bottom: ColorRect
var preview_overlay: Control
var preview_title: Label
var preview_watch: Button
var preview_close: Button
var preview_rewarded := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var ids := ConfigFile.new()
	if ids.load(TEST_IDS) != OK:
		return
	banner_id = str(ids.get_value("android", "banner_unit_id", ""))
	interstitial_id = str(ids.get_value("android", "interstitial_unit_id", ""))
	rewarded_id = str(ids.get_value("android", "rewarded_unit_id", ""))
	if not OS.has_feature("android"):
		preview_mode = not OS.get_cmdline_args().has("--script")
		if preview_mode:
			_build_preview()
		return
	if not Engine.has_singleton("SpiderAds"):
		push_warning("SpiderAds Android plugin is missing from this build; test ads cannot load.")
		return
	plugin = Engine.get_singleton("SpiderAds")
	plugin.interstitial_finished.connect(_on_interstitial_finished)
	plugin.rewarded_loaded.connect(_on_rewarded_loaded)
	plugin.reward_earned.connect(_on_reward_earned)
	plugin.rewarded_finished.connect(_on_rewarded_finished)
	if plugin.has_signal("ad_load_failed"):
		plugin.ad_load_failed.connect(_on_ad_load_failed)
	plugin.initializeAds()
	plugin.loadInterstitial(interstitial_id)
	plugin.loadRewarded(rewarded_id)

func show_banner() -> void:
	if get_node("/root/BillingManager").remove_ads_owned:
		return
	if preview_mode:
		preview_top.show()
		preview_bottom.show()
	elif plugin != null:
		plugin.showBanner(banner_id)

func hide_banner() -> void:
	if preview_mode:
		preview_top.hide()
		preview_bottom.hide()
	elif plugin != null:
		plugin.hideBanner()

func show_interstitial_then(action: Callable) -> void:
	if get_node("/root/BillingManager").remove_ads_owned:
		if action.is_valid():
			action.call()
		return
	if preview_mode:
		pending_interstitial_action = action
		_show_preview(false)
		return
	if plugin == null or not plugin.isInterstitialReady():
		if action.is_valid():
			action.call()
		return
	pending_interstitial_action = action
	plugin.showInterstitial()

func show_result_interstitial() -> void:
	show_interstitial_then(Callable())

func is_interstitial_ready() -> bool:
	return preview_mode or (plugin != null and plugin.isInterstitialReady())

func _on_interstitial_finished() -> void:
	if pending_interstitial_action.is_valid():
		var action := pending_interstitial_action
		pending_interstitial_action = Callable()
		action.call()

func is_rewarded_ready() -> bool:
	if preview_mode:
		return not reward_pending
	return rewarded_ready and plugin != null and plugin.isRewardedReady()

func show_rewarded_coins() -> bool:
	return _show_rewarded(_grant_rewarded_coins, false)

func show_rewarded_power(action: Callable) -> bool:
	return _show_rewarded(action, true)

func _show_rewarded(action: Callable, pause_game: bool) -> bool:
	if not is_rewarded_ready() or reward_pending:
		return false
	reward_pending = true
	pending_reward_action = action
	reward_paused_game = pause_game
	was_paused_before_reward = get_tree().paused
	if pause_game:
		get_tree().paused = true
	rewarded_ready = false
	rewarded_ready_changed.emit(false)
	if preview_mode:
		_show_preview(true)
	else:
		plugin.showRewarded()
	return true

func _on_rewarded_loaded() -> void:
	rewarded_ready = true
	rewarded_ready_changed.emit(true)

func _on_reward_earned() -> void:
	if not reward_pending:
		return
	reward_pending = false
	if pending_reward_action.is_valid():
		pending_reward_action.call()
	pending_reward_action = Callable()

func _grant_rewarded_coins() -> void:
	get_node("/root/GameManager").add_coins(REWARDED_COINS)
	reward_granted.emit(REWARDED_COINS)

func _on_rewarded_finished() -> void:
	reward_pending = false
	pending_reward_action = Callable()
	if reward_paused_game:
		get_tree().paused = was_paused_before_reward
	reward_paused_game = false
	if preview_mode:
		rewarded_ready_changed.emit(true)

func _on_ad_load_failed(format: String, reason: String) -> void:
	push_warning("%s test ad failed to load: %s" % [format, reason])
	ad_load_failed.emit(format, reason)

func _build_preview() -> void:
	preview_layer = CanvasLayer.new()
	preview_layer.layer = 100
	preview_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(preview_layer)
	var frame := Control.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_layer.add_child(frame)
	preview_top = _preview_banner(frame, false)
	preview_bottom = _preview_banner(frame, true)
	preview_overlay = Control.new()
	preview_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	preview_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	preview_layer.add_child(preview_overlay)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.01, 0.05, 0.04, 0.84)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_overlay.add_child(shade)
	var card := PanelContainer.new()
	card.anchor_left = 0.5
	card.anchor_right = 0.5
	card.anchor_top = 0.5
	card.anchor_bottom = 0.5
	card.offset_left = -280.0
	card.offset_right = 280.0
	card.offset_top = -180.0
	card.offset_bottom = 180.0
	var skin := StyleBoxFlat.new()
	skin.bg_color = Color(0.10, 0.24, 0.19)
	skin.border_color = Color(0.95, 0.76, 0.35)
	skin.set_border_width_all(4)
	skin.set_corner_radius_all(18)
	card.add_theme_stylebox_override("panel", skin)
	preview_overlay.add_child(card)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 24)
	card.add_child(column)
	preview_title = Label.new()
	preview_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_title.add_theme_font_size_override("font_size", 29)
	column.add_child(preview_title)
	var detail := Label.new()
	detail.text = "Desktop preview. Google test ads load in the Android build."
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.custom_minimum_size = Vector2(490, 75)
	detail.add_theme_font_size_override("font_size", 19)
	column.add_child(detail)
	preview_watch = Button.new()
	preview_watch.text = "COMPLETE TEST AD"
	preview_watch.custom_minimum_size.y = 64
	preview_watch.pressed.connect(_finish_preview.bind(true))
	column.add_child(preview_watch)
	preview_close = Button.new()
	preview_close.custom_minimum_size.y = 64
	preview_close.pressed.connect(_finish_preview.bind(false))
	column.add_child(preview_close)
	preview_overlay.hide()

func _preview_banner(frame: Control, bottom: bool) -> ColorRect:
	var banner := ColorRect.new()
	banner.anchor_right = 1.0
	banner.anchor_top = 1.0 if bottom else 0.0
	banner.anchor_bottom = 1.0 if bottom else 0.0
	banner.offset_top = -56.0 if bottom else 0.0
	banner.offset_bottom = 0.0 if bottom else 56.0
	banner.color = Color(0.09, 0.28, 0.22, 0.96)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(banner)
	var caption := Label.new()
	caption.text = "TEST AD PREVIEW  •  Android banner"
	caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 22)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(caption)
	banner.hide()
	return banner

func _show_preview(rewarded: bool) -> void:
	preview_rewarded = rewarded
	preview_title.text = "REWARDED TEST AD PREVIEW" if rewarded else "INTERSTITIAL TEST AD PREVIEW"
	preview_watch.visible = rewarded
	preview_close.text = "SKIP" if rewarded else "CLOSE"
	preview_overlay.show()

func _finish_preview(earned: bool) -> void:
	preview_overlay.hide()
	if preview_rewarded:
		if earned:
			_on_reward_earned()
		_on_rewarded_finished()
	else:
		_on_interstitial_finished()
