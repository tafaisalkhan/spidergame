extends Node2D

@export var intro_mode := false
@export_range(1, 1000, 1) var intro_level := 1

const SpiderScript = preload("res://scripts/spider.gd")
const BugScript = preload("res://scripts/trap_bug.gd")
const SoundScript = preload("res://scripts/sound.gd")
const GameHudScript = preload("res://scripts/ui/GameHud.gd")
const GameFont = preload("res://scripts/ui/GameFont.gd")
const FrozenEffectScript = preload("res://scripts/ui/FrozenEffect.gd")
const CatchEffectScript = preload("res://scripts/catch_effect.gd")
const ATLAS = preload("res://assets/player/spider_atlas.png")
const HUNT_BUG_TEXTURES = [
	preload("res://assets/bugs/sky_midge.svg"),
	preload("res://assets/bugs/ruby_midge.svg"),
	preload("res://assets/bugs/gold_midge.svg")
]
const BUGS_MODE_TEXTURES = [
	preload("res://assets/bugs/web_midge_blue.svg"),
	preload("res://assets/bugs/web_midge_red.svg"),
	preload("res://assets/bugs/web_midge_gold.svg")
]
const RED_SPIDER = preload("res://assets/rival/red_spider.png")
const GARDEN = preload("res://assets/background/garden.png")
const DARK_GARDEN_SHADER = preload("res://shaders/dark_garden.gdshader")
const RESULT_VICTORY = preload("res://assets/ui/result-victory.png")
const RESULT_FAILURE = preload("res://assets/ui/result-failure.png")
const RESULT_STAR = preload("res://assets/ui/victory-star.png")
const RESULT_ACTION_TEXTURE = preload("res://assets/ui/result-action.svg")
const RESULT_RETRY_ICON = preload("res://assets/ui/result-retry.svg")
const RESULT_NEXT_ICON = preload("res://assets/ui/result-next.svg")
const RESULT_HOME_ICON = preload("res://assets/ui/result-home.svg")
const REWARD_COIN = preload("res://assets/ui/reward-coin.png")
const POWER_SPEED = preload("res://assets/ui/power_speed.svg")
const POWER_TIMER = preload("res://assets/ui/hud_clock.svg")
const POWER_FREEZE = preload("res://assets/ui/power_freeze.svg")
const POWER_CUT = preload("res://assets/ui/power_cut.svg")
const POWER_WEB = preload("res://assets/ui/power_web.svg")
const POWER_CANCEL = preload("res://assets/ui/power_cancel.svg")
const POWER_CLOAK = preload("res://assets/ui/power_cloak.svg")
const REWARD_AD_ICON = preload("res://assets/ui/reward_ad.svg")
const BUGS_PAUSE_ICON = preload("res://assets/ui/bugs_pause.svg")
const POWERS_HIDE_ICON = preload("res://assets/ui/hud_powers_hide.svg")
const POWERS_SHOW_ICON = preload("res://assets/ui/hud_powers_show.svg")
const PANIC_BUG_SOUND = preload("res://assets/sound/panic_bug.wav")
const BUG_EATING_SOUND = preload("res://assets/sound/bug_eating_by_spider.mp3")
const BUG_DIED_SOUND = preload("res://assets/sound/bug_died.mp3")
const SPIDER_WALKING_SOUND = preload("res://assets/sound/spider_walking.wav")
const RIVAL_READY_SOUND = preload("res://assets/sound/rival_ready_to_attach.mp3")
const PLAYER_READY_SOUND = preload("res://assets/sound/powerup_fight.mp3")
const COIN_SOUND = preload("res://assets/sound/coin_sound.wav")
const STAR_SOUND = preload("res://assets/sound/star_sound.mp3")
const LEVEL_COMPLETE_SOUND = preload("res://assets/sound/level_complete.mp3")
const LEVEL_FAIL_SOUND = preload("res://assets/sound/level_fail.mp3")
const WEB_CENTER := Vector2(540, 960)
const DESIGN_SIZE := Vector2(1920, 1080)
const BUG_COUNT := 6
const SPIDER_SEPARATION := 112.0
const START_CUT_CHARGES := 2
const START_BUILD_CHARGES := 2
const START_BOOST_CHARGES := 2
const START_TIMER_CHARGES := 2
const START_STUN_CHARGES := 2
const REBUILD_TIME := 0.9
const RIVAL_EAT_DURATION := 1.15
const SOLO_START_SCALE := Vector2(0.08, 0.08)
const SOLO_MAX_SCALE := 0.60
const SOLO_GROWTH := 0.04
const SOLO_PLAYER_START := 20
const SOLO_RIVAL_START := 78
const FIRST_HUNT_BOUNDS := Rect2(-240.0, -1570.0, 1560.0, 3530.0)
const FIRST_HUNT_WEB_WIDTH := 1.45
const COMPACT_HUNT_SCALE := 0.70
const COMPACT_HUNT_BOUNDS := Rect2(0.0, -800.0, 1080.0, 2410.0)
const COMPACT_CAMERA_ZOOM := 2.3
const BUGS_MODE_CAMERA_ZOOM := 1.0
const BUGS_MODE_MIN_ZOOM := 0.35
const BUGS_MODE_MAX_ZOOM := 2.0
const BUGS_MODE_MIN_TIME := 10.0
const BUGS_MODE_START_EXTRA_TIME := 95.0
const BUGS_MODE_CATCH_TIME_BONUS := 6.0
const BUGS_MODE_WEB_LIMIT := 20
const RIVAL_RESPAWN_START_LEVEL := 6
const DEFAULT_CAMERA_ZOOM := 2.0
const MIN_CAMERA_ZOOM := 0.85
const MAX_CAMERA_ZOOM := 2.5
const CAMERA_ZOOM_STEP := 0.2
const HUD_TOP_MARGIN := 36.0
const STYLE_NAMES := ["CLASSIC", "SWIFT", "SHADE", "HUNTER", "GIANT"]
const STYLE_COSTS := [0, 30, 45, 60, 75]

class RivalHunter:
	var spider: Spider
	var node := 0
	var target := 0
	var progress := 0.0
	var power := 0
	var bugs_eaten := 0
	var active := true
	var respawn_remaining := 0.0
	var eating_remaining := 0.0
	var stun_remaining := 0.0
	var home := 0
	var base_speed := 195.0
	var cut_charges := 0
	var build_charges := 0
	var boost_charges := 0
	var stun_charges := 0
	var boost_remaining := 0.0
	var power_cooldown := 7.0
	var repair_edge := -1
	var rebuild_progress := 0.0

var spider: Spider
var rival: Spider
var normalized_rival_texture: Texture2D
var extra_rivals: Array[RivalHunter] = []
var solo_start_scale := SOLO_START_SCALE
var rival_levels := false
var bugs_mode := false
var carried_trap_scale := 0.0
var level_start_power := 0
var player_power := 0
var rival_power := 0
var rival_active := true
var rival_respawn_remaining := 0.0
var player_active := true
var player_heading := Vector2.ZERO
var solo_spawn_timer := 0.0
var solo_spawned_count := 0
var silk_refill_remaining := 8.0
var intro_reveal_active := false
var intro_reveal_tween: Tween
var escape_focus_bug: TrapBug
var escape_focus_tween: Tween
var escape_focus_returning := false
var escape_focus_zoom := 1.0
var escape_focus_position := Vector2.ZERO
var escape_focus_smoothing := true
var threat_warning_active := false
var threat_warning_tween: Tween
var threat_warning_panel: PanelContainer
var threat_warning_title: Label
var threat_warning_note: Label
var warned_rivals: Dictionary = {}
var duel_tween: Tween
var coins := 0
var unlocked_styles: Array[bool] = [true, false, false, false, false]
var selected_style := 0
var economy_enabled := true
var shop_open := false
var coins_label: Label
var game_hud
var elapsed_seconds := 0.0
var bugs_failure_reason := ""
var ui_root: Control
var ui_design: Control
var shop_button: Button
var shop_panel: PanelContainer
var style_buttons: Array[Button] = []
var cloak_button: Button
var reward_ad_buttons: Dictionary = {}
var power_toggle_button: Button
var power_toggle_icon: TextureRect
var bugs_item_rail: Panel
var bugs_pause_button: Button
var bugs_pause_dimmer: ColorRect
var bugs_pause_panel: PanelContainer
var bugs_paused := false
var powers_expanded := true
var cloak_charges := 2
var cloak_remaining := 0.0
var base_spider_speed := 0.0
var boost_charges := START_BOOST_CHARGES
var timer_charges := START_TIMER_CHARGES
var stun_charges := START_STUN_CHARGES
var boost_remaining := 0.0
var rival_stun_remaining := 0.0
var player_stun_remaining := 0.0
var rival_cut_charges := START_CUT_CHARGES
var rival_boost_charges := START_BOOST_CHARGES
var rival_stun_charges := START_STUN_CHARGES
var rival_boost_remaining := 0.0
var rival_power_cooldown := 6.0
var web_points: Array[Vector2] = []
var web_edges: Array[Vector2i] = []
var edge_lookup: Dictionary = {}
var edge_lengths: Array[float] = []
var edge_kind: Array[int] = [] # 0: fine capture ring, 1: load-bearing radial spoke
var edge_active: Array[bool] = []
var adjacency: Array = []
var upper_nodes: Array = []
var camera: Camera2D
var camera_zoom := DEFAULT_CAMERA_ZOOM
var bugs_mode_spider_start := 7
var rival_mode_spider_start := 0
var rival_mode_rival_start := 0
var generated_grid_columns := 0
var generated_grid_rows := 0
var bugs_mode_initial_links := BUGS_MODE_WEB_LIMIT
var active_touches: Dictionary = {}
var touch_start_positions: Dictionary = {}
var bugs_pinch_used := false
var bugs_drag_used := false
var pinch_start_distance := 0.0
var pinch_start_zoom := DEFAULT_CAMERA_ZOOM
var bugs_camera_offset := Vector2.ZERO
var spider_node := 0
var spider_target := 0
var spider_progress := 0.0
var spider_retreating := false
var rival_node := 44
var rival_target := 44
var rival_progress := 0.0
var rival_retreating := false
var rival_repair_edge := -1
var rival_rebuild_progress := 0.0
var player_repair_edge := -1
var player_rebuild_progress := 0.0
var selected_repair_edge := -1
var weave_start_node := -1
var selected_new_link := Vector2i(-1, -1)
var bugs_available_repair_edges: Array[int] = []
var bugs_available_new_targets: Array[int] = []
var player_new_link_progress := -1.0
var target_bug: TrapBug
var destination_node := -1
var tap_destination_edge := -1
var tap_destination_progress := 0.0
var chase_rival := false
var chase_extra_rival: RivalHunter
var auto_path: Array[int] = []
var trail_cut_enabled := false
var weave_mode := false
var cut_charges := START_CUT_CHARGES
var build_charges := START_BUILD_CHARGES
var rival_build_charges := START_BUILD_CHARGES
var cut_button: Button
var weave_button: Button
var cancel_button: Button
var boost_button: Button
var timer_button: Button
var bugs_zoom_in_button: Button
var bugs_zoom_out_button: Button
var bugs_focus_button: Button
var stun_button: Button
var last_cut_msec := 0
var web_progress := 0.0
var building := false
var construction_tween: Tween
var bugs: Array = []
var bugs_mode_spawn_nodes: Array[int] = []
var bugs_level_rng := RandomNumberGenerator.new()
var caught_count := 0
var rival_caught_count := 0
var escaped_count := 0
var finished := false
var winner := 0
var status_label: Label
var instruction_label: Label
var result_panel: TextureRect
var result_dimmer: ColorRect
var result_level: Label
var result_stars: HBoxContainer
var star_reveal_tweens: Array[Tween] = []
var result_reward: Label
var retry_button: Button
var result_reward_ad_button: Button
var result_menu_button: Button
var result_tween: Tween
var result_ad_serial := 0
var result_title: Label
var result_note: Label
var next_button: Button
var catch_sound: AudioStreamWAV
var walking_audio: AudioStreamPlayer
var rival_walking_audio: AudioStreamPlayer
var rival_ready_audio: AudioStreamPlayer
var rival_panic_audio: AudioStreamPlayer
var player_panic_audio: AudioStreamPlayer
var player_panicking := false
var panicking_rivals: Dictionary = {}
var rival_bug_lead_announced := false
var player_ready_audio: AudioStreamPlayer
var ready_audio_tween: Tween
var pulse := 0.0
var player_eat_remaining := 0.0
var player_rival_eat_remaining := 0.0
var player_rival_victim: Spider
var player_rival_hunter: RivalHunter
var player_rival_score := 0
var player_rival_morsel: Sprite2D
var rival_eat_remaining := 0.0
var player_eat_duration := 0.0
var rival_eat_duration := 0.0
var player_eat_bug: TrapBug
var rival_eat_bug: TrapBug
var player_morsel: Sprite2D
var rival_morsel: Sprite2D

func _ready() -> void:
	load_progress()
	if intro_mode and get_tree().has_meta("first_hunt_rival_levels"):
		rival_levels = bool(get_tree().get_meta("first_hunt_rival_levels"))
		get_tree().remove_meta("first_hunt_rival_levels")
	if intro_mode and get_tree().has_meta("first_hunt_bugs_mode"):
		bugs_mode = bool(get_tree().get_meta("first_hunt_bugs_mode"))
		get_tree().remove_meta("first_hunt_bugs_mode")
	if intro_mode and get_tree().has_meta("first_hunt_level"):
		intro_level = maxi(1, int(get_tree().get_meta("first_hunt_level")))
		get_tree().remove_meta("first_hunt_level")
	if intro_mode and intro_level > 1 and get_tree().has_meta("first_hunt_spider_power"):
		level_start_power = maxi(0, int(get_tree().get_meta("first_hunt_spider_power")))
		get_tree().remove_meta("first_hunt_spider_power")
		solo_start_scale = Vector2.ONE * solo_scale_for_power(level_start_power)
	elif not intro_mode and get_tree().has_meta("first_hunt_spider_power"):
		carried_trap_scale = solo_scale_for_power(maxi(0, int(get_tree().get_meta("first_hunt_spider_power"))))
		get_tree().remove_meta("first_hunt_spider_power")
	if rival_levels:
		solo_start_scale = Vector2.ONE * (0.30 if rival_count_battle() else rival_visual_scale_for_power(level_start_power))
	catch_sound = SoundScript.make_chime(760.0, 0.15)
	build_scene()
	get_viewport().size_changed.connect(update_mobile_layout)
	update_mobile_layout()
	apply_selected_style()
	restart()

func load_progress() -> void:
	economy_enabled = not OS.get_cmdline_args().has("--script")
	var manager := get_node("/root/GameManager")
	coins = manager.coins
	for i in range(1, STYLE_NAMES.size()):
		unlocked_styles[i] = manager.unlocked_styles[i]
	selected_style = manager.selected_style

func save_progress() -> void:
	if not economy_enabled:
		return
	get_node("/root/GameManager").sync_from_campaign(coins, unlocked_styles, selected_style)

func award_coins(amount: int, source_screen := Vector2(-1.0, -1.0), animation_delay := 0.0) -> void:
	if amount <= 0:
		return
	coins += amount
	update_shop_ui()
	save_progress()
	fly_reward_coins(amount, source_screen, animation_delay)

func fly_reward_coins(amount: int, source_screen: Vector2, animation_delay := 0.0) -> void:
	if not is_instance_valid(ui_root) or not is_instance_valid(coins_label):
		return
	var destination := coins_label.global_position + Vector2(125.0, 22.0) * ui_design.scale
	for i in mini(8, amount):
		var coin := TextureRect.new()
		coin.texture = REWARD_COIN
		coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		coin.size = Vector2(62.0, 62.0)
		coin.scale = Vector2.ONE * 1.25
		coin.modulate.a = 0.0
		coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		coin.z_index = 250
		ui_root.add_child(coin)
		var tween := create_tween()
		tween.tween_interval(animation_delay + float(i) * 0.11)
		tween.tween_callback(position_reward_coin.bind(coin, source_screen, Vector2(float(i % 3 - 1) * 30.0, float(i / 3) * 18.0), animation_delay > 0.0))
		if i == 0:
			tween.tween_callback(play_sound.bind(COIN_SOUND, 0.0))
		tween.tween_property(coin, "modulate:a", 1.0, 0.12)
		tween.parallel().tween_property(coin, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(coin, "position", destination - coin.size * 0.5, 0.95).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(coin, "scale", Vector2(0.42, 0.42), 0.95)
		tween.tween_callback(coin.queue_free)

func position_reward_coin(coin: TextureRect, source_screen: Vector2, offset: Vector2, from_result: bool) -> void:
	var origin := result_reward.get_global_rect().get_center() if from_result and is_instance_valid(result_reward) else (source_screen if source_screen.x >= 0.0 else Vector2(540.0, 950.0))
	coin.position = origin - coin.size * 0.5 + offset

func build_web_network() -> void:
	if bugs_mode or rival_levels:
		build_bugs_mode_web()
		return
	if intro_mode:
		build_hunt_mesh()
		return
	web_points = [WEB_CENTER]
	web_edges.clear()
	edge_lookup.clear()
	edge_lengths.clear()
	edge_kind.clear()
	edge_active.clear()
	adjacency.clear()
	upper_nodes.clear()
	var inner_offsets: Array[Vector2] = [
		Vector2(-250, -480), Vector2(0, -500), Vector2(250, -480),
		Vector2(285, -245), Vector2(300, 0), Vector2(285, 245),
		Vector2(250, 480), Vector2(0, 500), Vector2(-250, 480),
		Vector2(-285, 245), Vector2(-300, 0), Vector2(-285, -245)
	]
	var outer_offsets: Array[Vector2] = [
		Vector2(-480, -870), Vector2(0, -900), Vector2(480, -870),
		Vector2(490, -460), Vector2(495, 0), Vector2(490, 460),
		Vector2(480, 870), Vector2(0, 900), Vector2(-480, 870),
		Vector2(-490, 460), Vector2(-495, 0), Vector2(-490, -460)
	]
	for ring in 8:
		for i in 12:
			var offset: Vector2
			match ring:
				0:
					offset = inner_offsets[i] * 0.30
				1:
					offset = inner_offsets[i] * 0.54
				2:
					offset = inner_offsets[i] * 0.78
				3:
					offset = inner_offsets[i]
				_:
					offset = inner_offsets[i].lerp(outer_offsets[i], float(ring - 3) * 0.25)
			if ring > 0 and ring < 7:
				var tangent := Vector2(-offset.y, offset.x).normalized()
				var uneven := sin(float(i * 7 + ring * 11) * 0.71) * 0.065
				uneven += cos(float(i * 3 - ring * 5) * 0.83) * 0.035
				offset = offset * (1.0 + uneven)
				offset += tangent * sin(float(i * 3 + ring * 5)) * 19.0
			web_points.append(WEB_CENTER + offset)
	for i in web_points.size():
		adjacency.append([])
	for ring in 8:
		for i in 12:
			var node := 1 + ring * 12 + i
			var next := 1 + ring * 12 + (i + 1) % 12
			if ring == 0 or ring == 7 or (i * 7 + ring * 3) % 13 != 0:
				add_web_edge(node, next, 0)
			add_web_edge(0 if ring == 0 else node - 12, node, 1)
			if ring > 1 and ring < 7 and (i + ring * 2) % 5 == 0:
				add_web_edge(node - 12, next, 2)
	# A connected upper section gives the player somewhere to climb beyond the first screen.
	for row in 5:
		var current_row: Array[int] = []
		for column in 5:
			var node := web_points.size()
			var x := 70.0 + float(column) * 235.0 + sin(float(row * 7 + column * 3)) * 10.0
			var y := -250.0 - float(row) * 310.0 + cos(float(row * 5 + column * 2)) * 8.0
			web_points.append(Vector2(x, y))
			adjacency.append([])
			current_row.append(node)
		upper_nodes.append(current_row)
		for column in 4:
			add_web_edge(current_row[column], current_row[column + 1], 0)
		if row > 0:
			var previous_row: Array[int] = upper_nodes[row - 1]
			for column in 5:
				add_web_edge(previous_row[column], current_row[column], 1)
			for column in 4:
				if (row + column) % 2 == 0:
					add_web_edge(previous_row[column], current_row[column + 1], 2)
				else:
					add_web_edge(previous_row[column + 1], current_row[column], 2)
	for column in 5:
		var lower_node := 85 if column <= 1 else (86 if column <= 3 else 87)
		add_web_edge(lower_node, upper_nodes[0][column], 1 if column % 2 == 0 else 2)
	if intro_mode:
		for point_index in web_points.size():
			var point: Vector2 = web_points[point_index]
			point.x = WEB_CENTER.x + (point.x - WEB_CENTER.x) * FIRST_HUNT_WEB_WIDTH
			if compact_hunt():
				point = WEB_CENTER + (point - WEB_CENTER) * COMPACT_HUNT_SCALE
			web_points[point_index] = point
	for edge_id in web_edges.size():
		var edge := web_edges[edge_id]
		var curve := strand_points(web_points[edge.x], web_points[edge.y], edge_id, edge_kind[edge_id])
		var length := 0.0
		for part in curve.size() - 1:
			length += curve[part].distance_to(curve[part + 1])
		edge_lengths.append(length)

func build_bugs_mode_web() -> void:
	bugs_level_rng.seed = 20261021 + intro_level * 1000003
	bugs_mode_spawn_nodes.clear()
	web_points.clear()
	web_edges.clear()
	edge_lookup.clear()
	edge_lengths.clear()
	edge_kind.clear()
	edge_active.clear()
	adjacency.clear()
	upper_nodes.clear()
	var visible_size := get_viewport().get_visible_rect().size / BUGS_MODE_CAMERA_ZOOM
	var left := WEB_CENTER.x - visible_size.x * 0.445
	var right := WEB_CENTER.x + visible_size.x * 0.445 - 180.0
	var top := WEB_CENTER.y - visible_size.y * 0.5 + 170.0
	var bottom := WEB_CENTER.y + visible_size.y * 0.5 - 90.0
	var arena_scale := bugs_mode_arena_scale()
	var columns := 3 if intro_level == 1 else mini(8, 4 + int(floor(log(float(intro_level - 1)) / log(2.0))))
	var rows := columns + 1
	generated_grid_columns = columns
	generated_grid_rows = rows
	bugs_mode_spider_start = (rows - 1) * columns + columns / 2
	rival_mode_spider_start = (rows - 1) * columns + columns / 2
	rival_mode_rival_start = columns / 2
	for row in rows:
		for column in columns:
			var x := lerpf(left, right, float(column) / float(columns - 1)) + sin(float(row * 7 + column * 5)) * 24.0 + bugs_level_rng.randf_range(-26.0, 26.0)
			var y := lerpf(top, bottom, float(row) / float(rows - 1)) + cos(float(row * 3 + column * 11)) * 22.0 + bugs_level_rng.randf_range(-26.0, 26.0)
			web_points.append(WEB_CENTER + (Vector2(x, y) - WEB_CENTER) * arena_scale)
			adjacency.append([])
	for row in rows:
		for column in columns:
			var node := row * columns + column
			if column < columns - 1:
				add_web_edge(node, node + 1, 0)
			if row < rows - 1:
				add_web_edge(node, node + columns, 1)
	for row in rows - 1:
		for column in columns - 1:
			if intro_level == 1 and not (row == 0 and column == 0 or row == 1 and column == 1 or row == 2 and column == 0):
				continue
			var node := row * columns + column
			if bugs_level_rng.randi_range(0, 1) == 0:
				add_web_edge(node, node + columns + 1, 2)
			else:
				add_web_edge(node + 1, node + columns, 2)
	bugs_mode_initial_links = web_edges.size()
	for quadrant in (4 if bugs_mode else 0):
		var candidates: Array[int] = []
		for row in rows:
			for column in columns:
				var left_half := column < columns / 2 if columns % 2 == 0 else column <= columns / 2
				var top_half := row < rows / 2 if rows % 2 == 0 else row <= rows / 2
				if int(left_half) != quadrant % 2 or int(top_half) != quadrant / 2:
					continue
				var candidate := row * columns + column
				if candidate == bugs_mode_spider_start or candidate == rival_mode_rival_start or bugs_mode_spawn_nodes.has(candidate):
					continue
				if quadrant == 1 and adjacency[candidate].size() < 3:
					continue
				candidates.append(candidate)
		assert(not candidates.is_empty())
		bugs_mode_spawn_nodes.append(candidates[bugs_level_rng.randi_range(0, candidates.size() - 1)])
	while bugs_mode and bugs_mode_spawn_nodes.size() < bugs_mode_bug_count():
		var best_node := -1
		var best_score := -INF
		for candidate in web_points.size():
			if candidate == bugs_mode_spider_start or candidate == rival_mode_rival_start or bugs_mode_spawn_nodes.has(candidate):
				continue
			var nearest_bug_distance := INF
			for occupied_node in bugs_mode_spawn_nodes:
				nearest_bug_distance = minf(nearest_bug_distance, web_points[candidate].distance_to(web_points[occupied_node]))
			var score := nearest_bug_distance + bugs_level_rng.randf_range(-70.0, 70.0) * arena_scale
			if score > best_score:
				best_score = score
				best_node = candidate
		assert(best_node >= 0)
		bugs_mode_spawn_nodes.append(best_node)
	if bugs_mode:
		assert(bugs_mode_spawn_nodes.size() == bugs_mode_bug_count())
	for edge_id in web_edges.size():
		var edge := web_edges[edge_id]
		var curve := strand_points(web_points[edge.x], web_points[edge.y], edge_id, edge_kind[edge_id])
		var length := 0.0
		for part in curve.size() - 1:
			length += curve[part].distance_to(curve[part + 1])
		edge_lengths.append(length)

func build_hunt_mesh() -> void:
	# Irregular triangular cells, like a web stretched between the arena edges.
	web_points = [WEB_CENTER]
	web_edges.clear()
	edge_lookup.clear()
	edge_lengths.clear()
	edge_kind.clear()
	edge_active.clear()
	adjacency.clear()
	upper_nodes.clear()
	for row in 12:
		for column in 8:
			var x := -180.0 + float(column) * 205.0
			var y := 1730.0 - float(row) * 265.0
			x += sin(float(row * 13 + column * 7) * 0.73) * 34.0
			y += cos(float(row * 5 + column * 11) * 0.61) * 29.0
			var point := Vector2(x, y)
			if compact_hunt():
				point = WEB_CENTER + (point - WEB_CENTER) * COMPACT_HUNT_SCALE
			web_points.append(point)
	for i in web_points.size():
		adjacency.append([])
	for row in 12:
		for column in 8:
			var node := 1 + row * 8 + column
			if column < 7:
				add_web_edge(node, node + 1, 0)
			if row < 11:
				add_web_edge(node, node + 8, 1)
				if column < 7 and not (row == 3 and column == 3):
					if (row + column) % 2 == 0:
						add_web_edge(node, node + 9, 2)
					else:
						add_web_edge(node + 1, node + 8, 2)
	# The center is a playable junction within one cell.
	var center_row := 3
	var center_column := 3
	var anchor := 1 + center_row * 8 + center_column
	web_points[0] = (web_points[anchor] + web_points[anchor + 1] + web_points[anchor + 8] + web_points[anchor + 9]) * 0.25
	for corner in [anchor, anchor + 1, anchor + 8, anchor + 9]:
		add_web_edge(0, corner, 2)
	for edge_id in web_edges.size():
		var edge := web_edges[edge_id]
		var curve := strand_points(web_points[edge.x], web_points[edge.y], edge_id, edge_kind[edge_id])
		var length := 0.0
		for part in curve.size() - 1:
			length += curve[part].distance_to(curve[part + 1])
		edge_lengths.append(length)

func add_web_edge(a: int, b: int, kind: int) -> void:
	var index := web_edges.size()
	web_edges.append(Vector2i(a, b))
	edge_lookup[Vector2i(a, b)] = index
	edge_lookup[Vector2i(b, a)] = index
	edge_kind.append(kind)
	edge_active.append(true)
	adjacency[a].append(b)
	adjacency[b].append(a)

func atlas_region(rect: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = ATLAS
	texture.region = rect
	return texture

func build_scene() -> void:
	camera = Camera2D.new()
	camera.position = WEB_CENTER
	camera.zoom = Vector2.ONE * camera_zoom
	camera.limit_left = int(FIRST_HUNT_BOUNDS.position.x) if intro_mode else 0
	camera.limit_right = int(FIRST_HUNT_BOUNDS.end.x) if intro_mode else 1080
	camera.limit_top = int(FIRST_HUNT_BOUNDS.position.y) if intro_mode else -1850
	camera.limit_bottom = int(FIRST_HUNT_BOUNDS.end.y) if intro_mode else 1920
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	add_child(camera)
	camera.make_current()
	var columns := [-1080.0, 0.0, 1080.0]
	var rows := [-960.0, 960.0, 2880.0] if intro_mode else [-960.0, 960.0]
	var dark_garden: ShaderMaterial = null
	if bugs_mode or rival_levels:
		columns.clear()
		rows.clear()
		var backdrop_bounds := hunt_bounds().grow(get_viewport().get_visible_rect().size.x)
		for column_index in range(floori(backdrop_bounds.position.x / 1080.0), floori(backdrop_bounds.end.x / 1080.0) + 1):
			columns.append(float(column_index) * 1080.0)
		for row_index in range(floori(backdrop_bounds.position.y / 1920.0), floori(backdrop_bounds.end.y / 1920.0) + 1):
			rows.append(960.0 + float(row_index) * 1920.0)
		if bugs_mode or rival_levels:
			dark_garden = ShaderMaterial.new()
			dark_garden.shader = DARK_GARDEN_SHADER
	for row_y in rows:
		for column_x in columns:
			var background := Sprite2D.new()
			background.texture = GARDEN
			background.position = Vector2(540.0 + column_x, row_y)
			background.scale = Vector2(1080.0 / GARDEN.get_width(), 1920.0 / GARDEN.get_height())
			background.z_index = -10
			if bugs_mode or rival_levels:
				background.material = dark_garden
			add_child(background)

	spider = SpiderScript.new()
	spider.name = "BlueSpider"
	spider.setup(atlas_region(Rect2(12, 4, 565, 410)), 1)
	var rival_image := RED_SPIDER.get_image()
	var player_texture_size := Vector2i(spider.visual.texture.get_size())
	rival_image.resize(player_texture_size.x, player_texture_size.y, Image.INTERPOLATE_LANCZOS)
	normalized_rival_texture = ImageTexture.create_from_image(rival_image)
	base_spider_speed = spider.speed
	if intro_mode:
		spider.visual.scale = solo_start_scale
	elif carried_trap_scale > 0.0:
		spider.visual.scale = Vector2.ONE * carried_trap_scale
	add_child(spider)
	spider.set_physics_process(false)
	walking_audio = AudioStreamPlayer.new()
	walking_audio.name = "SpiderWalkingAudio"
	walking_audio.stream = SPIDER_WALKING_SOUND
	walking_audio.volume_db = -17.0
	add_child(walking_audio)
	if rival_levels:
		rival_walking_audio = AudioStreamPlayer.new()
		rival_walking_audio.name = "RivalWalkingAudio"
		rival_walking_audio.stream = SPIDER_WALKING_SOUND
		rival_walking_audio.volume_db = -23.0
		add_child(rival_walking_audio)
		rival_ready_audio = AudioStreamPlayer.new()
		rival_ready_audio.name = "RivalReadyAudio"
		rival_ready_audio.stream = RIVAL_READY_SOUND
		rival_ready_audio.volume_db = -3.0
		add_child(rival_ready_audio)
	if intro_mode:
		player_ready_audio = AudioStreamPlayer.new()
		player_ready_audio.name = "PlayerReadyAudio"
		player_ready_audio.stream = PLAYER_READY_SOUND
		player_ready_audio.volume_db = -6.0
		add_child(player_ready_audio)
	rival = SpiderScript.new()
	rival.name = "RedAISpider"
	rival.setup(normalized_rival_texture, 2)
	rival.visual.scale = solo_start_scale if intro_mode else Vector2(0.16, 0.16)
	rival.speed = base_rival_speed()
	add_child(rival)
	rival.set_physics_process(false)
	rival_panic_audio = AudioStreamPlayer.new()
	rival_panic_audio.name = "RivalPanicAudio"
	rival_panic_audio.stream = PANIC_BUG_SOUND
	rival_panic_audio.pitch_scale = 0.72
	rival_panic_audio.volume_db = -5.0
	add_child(rival_panic_audio)
	player_panic_audio = AudioStreamPlayer.new()
	player_panic_audio.name = "PlayerPanicAudio"
	player_panic_audio.stream = PANIC_BUG_SOUND
	player_panic_audio.pitch_scale = 0.9
	player_panic_audio.volume_db = -5.0
	add_child(player_panic_audio)

	var layer := CanvasLayer.new()
	add_child(layer)
	ui_root = Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui_root)
	ui_design = Control.new()
	ui_design.size = DESIGN_SIZE
	ui_design.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(ui_design)
	var root := ui_design
	game_hud = GameHudScript.new()
	game_hud.level = intro_level
	game_hud.campaign = intro_mode
	root.add_child(game_hud)
	coins_label = game_hud.coins_label
	status_label = game_hud.bugs_label
	instruction_label = game_hud.instruction_label
	instruction_label.text = "Tap a strand to cut it and slow the rival!"
	if bugs_mode or rival_levels:
		bugs_item_rail = Panel.new()
		bugs_item_rail.name = "ModeItemRail"
		bugs_item_rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var rail_style := StyleBoxFlat.new()
		rail_style.bg_color = Color(0.055, 0.060, 0.075, 0.87)
		rail_style.border_color = Color(0.28, 0.30, 0.32, 0.95)
		rail_style.border_width_left = 5
		bugs_item_rail.add_theme_stylebox_override("panel", rail_style)
		root.add_child(bugs_item_rail)

	cut_button = make_power_button(root, Vector2(570, 1745), "CUT WEB" if rival_levels else "CUT TRAIL", POWER_CUT)
	cut_button.pressed.connect(toggle_trail_cut)
	weave_button = make_power_button(root, Vector2(685, 1745), "CREATE WEB", POWER_WEB)
	weave_button.pressed.connect(toggle_weave_mode)
	cancel_button = make_power_button(root, Vector2(800, 1745), "CANCEL PATH", POWER_CANCEL)
	cancel_button.pressed.connect(cancel_auto_navigation)
	if intro_mode:
		boost_button = make_power_button(root, Vector2(340, 1745), "SPEED BOOST", POWER_SPEED)
		boost_button.pressed.connect(use_speed_boost)
		stun_button = make_power_button(root, Vector2(455, 1745), "FREEZE RIVAL", POWER_FREEZE)
		stun_button.pressed.connect(use_rival_stun)
		if bugs_mode:
			stun_button.hide()
	cloak_button = make_power_button(root, Vector2(915, 1745), "GO INVISIBLE", POWER_CLOAK)
	cloak_button.pressed.connect(use_cloak)
	add_power_reward_icon(cut_button, "cut")
	add_power_reward_icon(weave_button, "weave")
	if intro_mode:
		add_power_reward_icon(boost_button, "boost")
		add_power_reward_icon(stun_button, "stun")
	add_power_reward_icon(cloak_button, "cloak")
	power_toggle_button = Button.new()
	power_toggle_button.name = "PowerToggleButton"
	power_toggle_button.position = Vector2(34, 530)
	power_toggle_button.size = Vector2(90, 90)
	power_toggle_button.tooltip_text = "Hide powers"
	style_result_button(power_toggle_button, Color(0.10, 0.37, 0.42))
	power_toggle_button.pressed.connect(toggle_power_hud)
	root.add_child(power_toggle_button)
	power_toggle_icon = TextureRect.new()
	power_toggle_icon.name = "ToggleIcon"
	power_toggle_icon.texture = POWERS_HIDE_ICON
	power_toggle_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	power_toggle_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	power_toggle_icon.position = Vector2(5, 5)
	power_toggle_icon.size = Vector2(80, 80)
	power_toggle_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	power_toggle_button.add_child(power_toggle_icon)
	if bugs_mode or rival_levels:
		style_bugs_item_button(power_toggle_button)
		power_toggle_icon.texture = POWERS_SHOW_ICON
		power_toggle_button.tooltip_text = "Hide tools"
		for item_button in ([cut_button, cancel_button, stun_button, cloak_button] if bugs_mode else [cancel_button, cloak_button]):
			if is_instance_valid(item_button):
				item_button.hide()
		timer_button = make_power_button(root, Vector2.ZERO, "TIMER +5", POWER_TIMER)
		timer_button.pressed.connect(use_timer_power)
		add_power_reward_icon(timer_button, "timer")
		for item_button in ([timer_button, boost_button, weave_button] if bugs_mode else [cut_button, weave_button, timer_button, stun_button, boost_button]):
			style_bugs_item_button(item_button)
		bugs_zoom_in_button = make_power_button(root, Vector2.ZERO, "+")
		bugs_zoom_out_button = make_power_button(root, Vector2.ZERO, "-")
		for zoom_button in [bugs_zoom_in_button, bugs_zoom_out_button]:
			zoom_button.size = Vector2(110, 86)
			zoom_button.add_theme_font_size_override("font_size", 58)
			style_bugs_item_button(zoom_button)
		bugs_zoom_in_button.tooltip_text = "Zoom in"
		bugs_zoom_out_button.tooltip_text = "Zoom out"
		bugs_zoom_in_button.pressed.connect(change_camera_zoom.bind(CAMERA_ZOOM_STEP))
		bugs_zoom_out_button.pressed.connect(change_camera_zoom.bind(-CAMERA_ZOOM_STEP))
		bugs_focus_button = make_power_button(root, Vector2.ZERO, "FOCUS")
		bugs_focus_button.size = Vector2(110, 86)
		bugs_focus_button.add_theme_font_size_override("font_size", 26)
		bugs_focus_button.tooltip_text = "Reset camera to spider"
		style_bugs_item_button(bugs_focus_button)
		bugs_focus_button.pressed.connect(reset_camera_to_player)
		bugs_pause_button = make_power_button(root, Vector2.ZERO, "PAUSE", BUGS_PAUSE_ICON)
		bugs_pause_button.name = "BugsPauseButton"
		style_bugs_item_button(bugs_pause_button)
		bugs_pause_button.pressed.connect(toggle_bugs_pause)
	build_shop_ui(root)
	shop_button.hide()
	threat_warning_panel = PanelContainer.new()
	threat_warning_panel.position = Vector2(85, 300)
	threat_warning_panel.size = Vector2(910, 210)
	threat_warning_panel.visible = false
	threat_warning_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var warning_style := StyleBoxFlat.new()
	warning_style.bg_color = Color(0.24, 0.025, 0.055, 0.94)
	warning_style.border_color = Color(1.0, 0.3, 0.24)
	warning_style.set_border_width_all(6)
	warning_style.set_corner_radius_all(26)
	threat_warning_panel.add_theme_stylebox_override("panel", warning_style)
	root.add_child(threat_warning_panel)
	var warning_column := VBoxContainer.new()
	warning_column.alignment = BoxContainer.ALIGNMENT_CENTER
	threat_warning_panel.add_child(warning_column)
	threat_warning_title = make_label("RIVAL IS COMING FOR YOU!", 49, Color(1.0, 0.84, 0.72))
	threat_warning_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_column.add_child(threat_warning_title)
	threat_warning_note = make_label("It is bigger. Run or use FREEZE RIVAL!", 32, Color.WHITE)
	threat_warning_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_column.add_child(threat_warning_note)

	result_dimmer = ColorRect.new()
	result_dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_dimmer.color = Color(0.01, 0.035, 0.025, 0.72)
	result_dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_dimmer.visible = false
	result_dimmer.z_index = 100
	ui_root.add_child(result_dimmer)
	result_panel = TextureRect.new()
	result_panel.texture = RESULT_VICTORY
	result_panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result_panel.stretch_mode = TextureRect.STRETCH_SCALE
	result_panel.position = Vector2(530, -40)
	result_panel.size = Vector2(860, 1180)
	result_panel.pivot_offset = result_panel.size * 0.5
	result_panel.z_index = 101
	result_panel.visible = false
	root.add_child(result_panel)
	result_level = make_label("LEVEL %d" % intro_level, 42, Color.WHITE)
	result_level.position = Vector2(130, 82)
	result_level.size = Vector2(600, 65)
	result_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_level.add_theme_color_override("font_shadow_color", Color(0.15, 0.08, 0.02, 0.9))
	result_level.add_theme_constant_override("shadow_offset_x", 3)
	result_level.add_theme_constant_override("shadow_offset_y", 3)
	result_panel.add_child(result_level)
	result_title = make_label("LEVEL COMPLETE!", 55, Color(0.23, 0.34, 0.11))
	result_title.position = Vector2(95, 300)
	result_title.size = Vector2(670, 85)
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_panel.add_child(result_title)
	result_stars = HBoxContainer.new()
	result_stars.position = Vector2(238, 400)
	result_stars.size = Vector2(384, 118)
	result_stars.add_theme_constant_override("separation", 12)
	result_stars.alignment = BoxContainer.ALIGNMENT_CENTER
	result_panel.add_child(result_stars)
	for i in 3:
		var slot := Control.new()
		slot.custom_minimum_size = Vector2(112, 112)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		result_stars.add_child(slot)
		var star := TextureRect.new()
		star.texture = RESULT_STAR
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.size = Vector2(112, 112)
		star.pivot_offset = Vector2(56, 56)
		slot.add_child(star)
	result_reward = make_label("+10 COINS", 40, Color(0.40, 0.22, 0.045))
	result_reward.position = Vector2(100, 540)
	result_reward.size = Vector2(660, 65)
	result_reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_panel.add_child(result_reward)
	result_note = make_label("You caught every trapped bug.", 30, Color(0.25, 0.31, 0.18))
	result_note.position = Vector2(150, 645)
	result_note.size = Vector2(560, 105)
	result_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_panel.add_child(result_note)
	result_reward_ad_button = Button.new()
	result_reward_ad_button.name = "ResultRewardAdButton"
	result_reward_ad_button.text = "WATCH AD  +5 COINS"
	result_reward_ad_button.position = Vector2(250, 758)
	result_reward_ad_button.size = Vector2(360, 78)
	result_reward_ad_button.add_theme_font_size_override("font_size", 29)
	result_reward_ad_button.add_theme_font_override("font", GameFont.title_font())
	style_result_action(result_reward_ad_button)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		result_reward_ad_button.add_theme_color_override(state, Color.WHITE)
	result_reward_ad_button.pressed.connect(request_result_reward)
	result_panel.add_child(result_reward_ad_button)
	var result_ads := get_node("/root/AdsManager")
	result_ads.rewarded_ready_changed.connect(update_result_reward_ad_button.unbind(1))
	result_ads.reward_granted.connect(on_result_reward_granted)
	update_result_reward_ad_button()
	retry_button = Button.new()
	retry_button.name = "RetryButton"
	retry_button.text = ""
	retry_button.tooltip_text = "Replay level"
	retry_button.icon = RESULT_RETRY_ICON
	retry_button.position = Vector2(285, 870)
	retry_button.size = Vector2(110, 96)
	retry_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	retry_button.add_theme_font_size_override("font_size", 34)
	retry_button.add_theme_font_override("font", GameFont.display_font())
	style_result_action(retry_button)
	retry_button.pressed.connect(restart)
	result_panel.add_child(retry_button)
	if intro_mode:
		next_button = Button.new()
		next_button.name = "NextLevelButton"
		next_button.text = ""
		next_button.tooltip_text = "Next level"
		next_button.icon = RESULT_NEXT_ICON
		next_button.position = Vector2(375, 870)
		next_button.size = Vector2(110, 96)
		next_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		next_button.add_theme_font_size_override("font_size", 27)
		next_button.add_theme_font_override("font", GameFont.display_font())
		style_result_action(next_button)
		next_button.pressed.connect(advance_intro_level)
		result_panel.add_child(next_button)
	result_menu_button = Button.new()
	result_menu_button.name = "ResultMainMenuButton"
	result_menu_button.text = ""
	result_menu_button.tooltip_text = "Main menu"
	result_menu_button.icon = RESULT_HOME_ICON
	result_menu_button.position = Vector2(465, 870)
	result_menu_button.size = Vector2(110, 96)
	result_menu_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_menu_button.add_theme_font_size_override("font_size", 31)
	result_menu_button.add_theme_font_override("font", GameFont.display_font())
	style_result_action(result_menu_button)
	result_menu_button.pressed.connect(return_to_main_menu)
	result_panel.add_child(result_menu_button)
	if bugs_mode or rival_levels:
		build_bugs_pause_overlay()

func update_mobile_layout() -> void:
	if not is_instance_valid(ui_design):
		return
	var available := get_viewport().get_visible_rect().size
	var fit := minf(available.x / DESIGN_SIZE.x, available.y / DESIGN_SIZE.y)
	ui_design.scale = Vector2.ONE * fit
	ui_design.position = (available - DESIGN_SIZE * fit) * 0.5
	ui_design.size = Vector2(maxf(DESIGN_SIZE.x, available.x / fit), maxf(DESIGN_SIZE.y, available.y / fit))
	position_hud_at_screen_edges()
	if is_instance_valid(spider) and not intro_reveal_active and not threat_warning_active:
		update_camera_position()
		camera.reset_smoothing()

func position_hud_at_screen_edges() -> void:
	if not is_instance_valid(game_hud):
		return
	var edge_offset := ui_design.position.y / ui_design.scale.y
	game_hud.position.x = (DESIGN_SIZE.x - game_hud.size.x) * 0.5
	game_hud.position.y = HUD_TOP_MARGIN - edge_offset
	if bugs_mode or rival_levels:
		var right_edge := (get_viewport().get_visible_rect().size.x - ui_design.position.x) / ui_design.scale.x
		bugs_item_rail.position = Vector2(right_edge - 146.0, 0.0)
		bugs_item_rail.size = Vector2(146.0, DESIGN_SIZE.y)
		var tools := [timer_button, boost_button, weave_button] if bugs_mode else [cut_button, weave_button, timer_button, stun_button, boost_button]
		for index in tools.size():
			var item_button: Button = tools[index]
			item_button.position = Vector2(right_edge - 130.0, 22.0 + float(index) * (145.0 if bugs_mode else 106.0))
			if rival_levels:
				item_button.size = Vector2(100.0, 94.0)
		bugs_zoom_in_button.position = Vector2(right_edge - 130.0, 622.0 if bugs_mode else 562.0)
		bugs_zoom_out_button.position = Vector2(right_edge - 130.0, 723.0 if bugs_mode else 663.0)
		bugs_focus_button.position = Vector2(right_edge - 130.0, 824.0 if bugs_mode else 764.0)
		bugs_pause_button.position = Vector2(right_edge - 130.0, DESIGN_SIZE.y - 132.0)
		power_toggle_button.position = Vector2(right_edge - (240.0 if powers_expanded else 90.0), (DESIGN_SIZE.y - power_toggle_button.size.y) * 0.5)
		if is_instance_valid(bugs_pause_panel):
			bugs_pause_panel.position = Vector2((DESIGN_SIZE.x - bugs_pause_panel.size.x) * 0.5, (DESIGN_SIZE.y - bugs_pause_panel.size.y) * 0.5)
		return
	var side_buttons: Array[Button] = []
	for button in [boost_button, stun_button, cut_button, weave_button, cancel_button, cloak_button]:
		if is_instance_valid(button) and (button != cloak_button or selected_style == 2):
			side_buttons.append(button)
	var gap := 16.0
	var stack_height := float(side_buttons.size()) * 110.0 + float(maxi(0, side_buttons.size() - 1)) * gap
	var start_y := (DESIGN_SIZE.y - stack_height) * 0.5
	for index in side_buttons.size():
		side_buttons[index].position = Vector2(24.0, start_y + float(index) * (110.0 + gap))
	if is_instance_valid(power_toggle_button):
		power_toggle_button.position = Vector2(34.0, start_y - 106.0 if powers_expanded else (DESIGN_SIZE.y - power_toggle_button.size.y) * 0.5)

func change_camera_zoom(amount: float) -> void:
	if intro_reveal_active or escape_focus_bug != null:
		return
	set_camera_zoom(camera_zoom + amount)

func reset_camera_to_player() -> void:
	if not (bugs_mode or rival_levels) or intro_reveal_active or escape_focus_bug != null:
		return
	set_camera_zoom(1.0 / bugs_mode_arena_scale() if bugs_mode else 1.1 / bugs_mode_arena_scale())

func pan_bugs_camera(screen_delta: Vector2) -> void:
	if not (bugs_mode or rival_levels) or screen_delta.is_zero_approx():
		return
	bugs_camera_offset -= screen_delta / camera_zoom
	update_camera_position()
	bugs_camera_offset = camera.position - spider.position
	camera.reset_smoothing()

func set_camera_zoom(value: float) -> void:
	if bugs_mode or rival_levels:
		var arena_scale := bugs_mode_arena_scale()
		camera_zoom = clampf(value, 1.0 / arena_scale if rival_levels else maxf(BUGS_MODE_MIN_ZOOM, 1.0 / arena_scale), BUGS_MODE_MAX_ZOOM)
		camera.zoom = Vector2.ONE * camera_zoom
		bugs_camera_offset = Vector2.ZERO
		update_camera_position()
		camera.reset_smoothing()
		queue_redraw()
		return
	camera_zoom = clampf(value, MIN_CAMERA_ZOOM, MAX_CAMERA_ZOOM)
	camera.zoom = Vector2.ONE * camera_zoom
	update_camera_position()
	camera.reset_smoothing()

func make_label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font", GameFont.display_font())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func style_result_button(button: Button, fill: Color) -> void:
	for state in ["normal", "hover", "pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = fill.lightened(0.12) if state == "hover" else (fill.darkened(0.12) if state == "pressed" else fill)
		style.border_color = Color(0.96, 0.76, 0.32)
		style.set_border_width_all(4)
		style.set_corner_radius_all(18)
		button.add_theme_stylebox_override(state, style)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)

func style_bugs_item_button(button: Button) -> void:
	for state in ["normal", "hover", "pressed", "disabled"]:
		var skin := StyleBoxFlat.new()
		skin.bg_color = Color(0.075, 0.080, 0.095, 0.96) if state != "disabled" else Color(0.10, 0.11, 0.12, 0.83)
		if state == "hover":
			skin.bg_color = Color(0.16, 0.18, 0.21, 0.98)
		skin.border_color = Color(0.25, 0.28, 0.30) if state != "disabled" else Color(0.18, 0.19, 0.20)
		skin.set_border_width_all(3)
		skin.set_corner_radius_all(14)
		button.add_theme_stylebox_override(state, skin)

func build_bugs_pause_overlay() -> void:
	bugs_pause_dimmer = ColorRect.new()
	bugs_pause_dimmer.name = "BugsPauseDimmer"
	bugs_pause_dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bugs_pause_dimmer.color = Color(0.015, 0.02, 0.025, 0.72)
	bugs_pause_dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bugs_pause_dimmer.process_mode = Node.PROCESS_MODE_ALWAYS
	bugs_pause_dimmer.z_index = 200
	bugs_pause_dimmer.hide()
	ui_root.add_child(bugs_pause_dimmer)
	bugs_pause_panel = PanelContainer.new()
	bugs_pause_panel.name = "BugsPausePanel"
	bugs_pause_panel.size = Vector2(590, 420)
	bugs_pause_panel.custom_minimum_size = bugs_pause_panel.size
	bugs_pause_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	bugs_pause_panel.z_index = 201
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.085, 0.095, 0.11, 0.97)
	panel_style.border_color = Color(0.77, 0.80, 0.70)
	panel_style.set_border_width_all(5)
	panel_style.set_corner_radius_all(22)
	panel_style.set_content_margin_all(30)
	bugs_pause_panel.add_theme_stylebox_override("panel", panel_style)
	ui_design.add_child(bugs_pause_panel)
	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation", 20)
	bugs_pause_panel.add_child(actions)
	var title := make_label("PAUSED", 58, Color(1.0, 0.95, 0.78))
	title.custom_minimum_size.y = 100
	title.add_theme_font_override("font", GameFont.title_font())
	actions.add_child(title)
	var resume_button := Button.new()
	resume_button.name = "ResumeButton"
	resume_button.text = "RESUME GAME"
	resume_button.custom_minimum_size.y = 90
	resume_button.add_theme_font_override("font", GameFont.display_font())
	resume_button.add_theme_font_size_override("font_size", 36)
	style_result_button(resume_button, Color(0.12, 0.39, 0.29))
	resume_button.pressed.connect(toggle_bugs_pause)
	actions.add_child(resume_button)
	var menu_button := Button.new()
	menu_button.name = "MainMenuButton"
	menu_button.text = "MAIN MENU"
	menu_button.custom_minimum_size.y = 90
	menu_button.add_theme_font_override("font", GameFont.display_font())
	menu_button.add_theme_font_size_override("font_size", 36)
	style_result_button(menu_button, Color(0.37, 0.19, 0.17))
	menu_button.pressed.connect(return_to_main_menu)
	actions.add_child(menu_button)
	bugs_pause_panel.hide()

func toggle_bugs_pause() -> void:
	if not (bugs_mode or rival_levels) or finished or escape_focus_bug != null:
		return
	bugs_paused = not bugs_paused
	bugs_pause_dimmer.visible = bugs_paused
	bugs_pause_panel.visible = bugs_paused
	if is_instance_valid(walking_audio):
		walking_audio.stream_paused = bugs_paused
	if is_instance_valid(rival_walking_audio):
		rival_walking_audio.stream_paused = bugs_paused
	if is_instance_valid(rival_ready_audio):
		rival_ready_audio.stream_paused = bugs_paused
	if is_instance_valid(player_ready_audio):
		player_ready_audio.stream_paused = bugs_paused
	if is_instance_valid(player_panic_audio):
		player_panic_audio.stream_paused = bugs_paused
	for bug in bugs:
		if is_instance_valid(bug.free_voice_player):
			bug.free_voice_player.stream_paused = bugs_paused
		if is_instance_valid(bug.flight_audio):
			bug.flight_audio.stream_paused = bugs_paused
		if is_instance_valid(bug.stuck_audio):
			bug.stuck_audio.stream_paused = bugs_paused
	get_tree().paused = bugs_paused

func return_to_main_menu() -> void:
	bugs_paused = false
	get_tree().paused = false
	get_node("/root/GameManager").show_scene("res://scenes/main_menu.tscn")

func _exit_tree() -> void:
	if bugs_paused:
		get_tree().paused = false

func style_result_action(button: Button) -> void:
	for state in ["normal", "hover", "pressed", "disabled"]:
		var skin := StyleBoxTexture.new()
		skin.texture = RESULT_ACTION_TEXTURE
		skin.modulate_color = Color(1.16, 1.16, 1.08) if state == "hover" else (Color(0.78, 0.86, 0.79) if state == "pressed" else (Color(0.6, 0.6, 0.6) if state == "disabled" else Color.WHITE))
		button.add_theme_stylebox_override(state, skin)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", Color(1.0, 0.98, 0.82))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.91, 0.54))
	button.add_theme_color_override("font_outline_color", Color(0.02, 0.21, 0.13))
	button.add_theme_constant_override("outline_size", 4)

func update_result_reward_ad_button() -> void:
	if is_instance_valid(result_reward_ad_button):
		result_reward_ad_button.disabled = not get_node("/root/AdsManager").is_rewarded_ready()

func request_result_reward() -> void:
	if not finished:
		return
	if get_node("/root/AdsManager").show_rewarded_coins():
		result_note.text = "Finish the ad to earn 5 coins."
	else:
		result_note.text = "Rewarded ad is loading."

func on_result_reward_granted(amount: int) -> void:
	if finished and is_instance_valid(result_note):
		coins = get_node("/root/GameManager").coins
		update_shop_ui()
		fly_reward_coins(amount, Vector2(-1.0, -1.0), 0.0)
		result_note.text = "+%d coins earned from the ad!" % amount

func toggle_power_hud() -> void:
	powers_expanded = not powers_expanded
	if bugs_mode or rival_levels:
		bugs_item_rail.visible = powers_expanded
		var tools := [timer_button, boost_button, weave_button, bugs_zoom_in_button, bugs_zoom_out_button, bugs_focus_button] if bugs_mode else [cut_button, weave_button, timer_button, stun_button, boost_button, bugs_zoom_in_button, bugs_zoom_out_button, bugs_focus_button]
		for item_button in tools:
			item_button.visible = powers_expanded
		power_toggle_icon.texture = POWERS_SHOW_ICON if powers_expanded else POWERS_HIDE_ICON
		power_toggle_button.tooltip_text = "Hide tools" if powers_expanded else "Show tools"
		position_hud_at_screen_edges()
		return
	cut_button.visible = powers_expanded
	weave_button.visible = powers_expanded
	cancel_button.visible = powers_expanded
	if is_instance_valid(boost_button):
		boost_button.visible = powers_expanded
	if is_instance_valid(stun_button):
		stun_button.visible = powers_expanded
	if is_instance_valid(cloak_button):
		cloak_button.visible = powers_expanded and selected_style == 2
	power_toggle_icon.texture = POWERS_HIDE_ICON if powers_expanded else POWERS_SHOW_ICON
	power_toggle_button.tooltip_text = "Hide powers" if powers_expanded else "Show powers"
	position_hud_at_screen_edges()

func build_shop_ui(root: Control) -> void:
	shop_button = make_power_button(root, Vector2(718, 365), "SPIDER SHOP")
	shop_button.pressed.connect(toggle_shop)
	shop_panel = PanelContainer.new()
	shop_panel.position = Vector2(85, 465)
	shop_panel.size = Vector2(910, 950)
	shop_panel.visible = false
	root.add_child(shop_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	shop_panel.add_child(column)
	var title := make_label("CHOOSE YOUR SPIDER", 43, Color(0.16, 0.42, 0.65))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", GameFont.title_font())
	column.add_child(title)
	var style_icons: Array[Texture2D] = [preload("res://assets/branding/app-icon-spider-territory.png"), POWER_SPEED, POWER_CLOAK, POWER_WEB, preload("res://assets/ui/hud_bug_plaque.svg")]
	for i in STYLE_NAMES.size():
		var option := Button.new()
		option.custom_minimum_size = Vector2(830, 115)
		option.add_theme_font_size_override("font_size", 29)
		option.add_theme_font_override("font", GameFont.display_font())
		option.pressed.connect(choose_spider_style.bind(i))
		column.add_child(option)
		var icon := TextureRect.new()
		icon.texture = style_icons[i]
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.position = Vector2(28, 18)
		icon.size = Vector2(80, 80)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		option.add_child(icon)
		style_buttons.append(option)
	var close := Button.new()
	close.text = "CLOSE SHOP"
	close.custom_minimum_size = Vector2(830, 85)
	close.add_theme_font_size_override("font_size", 30)
	close.add_theme_font_override("font", GameFont.display_font())
	close.pressed.connect(toggle_shop)
	column.add_child(close)
	update_shop_ui()

func update_shop_ui() -> void:
	if not is_instance_valid(coins_label):
		return
	coins_label.text = "%d" % coins
	for i in style_buttons.size():
		var action := "SELECTED" if selected_style == i else ("SELECT" if unlocked_styles[i] else "%d COINS" % STYLE_COSTS[i])
		style_buttons[i].text = "%s  •  %s" % [STYLE_NAMES[i], action]
	shop_button.text = "SPIDER SHOP"

func toggle_shop() -> void:
	if threat_warning_active:
		return
	shop_open = not shop_open
	shop_panel.visible = shop_open
	if shop_open:
		spider.desired_direction = Vector2.ZERO
		cancel_auto_navigation()
	update_shop_ui()

func choose_spider_style(index: int) -> void:
	if not unlocked_styles[index]:
		if coins < STYLE_COSTS[index]:
			instruction_label.text = "Earn more coins by eating rival spiders."
			return
		coins -= STYLE_COSTS[index]
		unlocked_styles[index] = true
	selected_style = index
	if selected_style != 2:
		cloak_remaining = 0.0
	apply_selected_style()
	update_shop_ui()
	save_progress()

func apply_selected_style() -> void:
	if not is_instance_valid(spider):
		return
	if bugs_mode:
		spider.visual.self_modulate = Color.WHITE
	else:
		match selected_style:
			1:
				spider.visual.self_modulate = Color(0.56, 0.95, 1.0)
			2:
				spider.visual.self_modulate = Color(0.73, 0.59, 1.0)
			3:
				spider.visual.self_modulate = Color(1.0, 0.84, 0.43)
			4:
				spider.visual.self_modulate = Color(1.0, 0.60, 0.38)
			_:
				spider.visual.self_modulate = Color(0.45, 1.0, 0.38) if intro_mode and intro_level == 5 else Color.WHITE
	base_spider_speed = (175.0 if intro_mode and intro_level == 1 else (185.0 if compact_hunt() else (225.0 if intro_mode else 265.0))) * (1.25 if selected_style == 1 else 1.0)
	spider.speed = base_spider_speed * (1.7 if boost_remaining > 0.0 else 1.0)
	if is_instance_valid(cloak_button):
		cloak_button.visible = not (bugs_mode or rival_levels) and selected_style == 2 and powers_expanded
	position_hud_at_screen_edges()
	update_cloak_button()

func update_cloak_button() -> void:
	if is_instance_valid(cloak_button):
		set_power_charge(cloak_button, cloak_charges)
		cloak_button.disabled = cloak_charges <= 0 or cloak_remaining > 0.0

func use_cloak() -> void:
	if selected_style != 2 or cloak_charges <= 0 or cloak_remaining > 0.0 or finished or threat_warning_active:
		return
	cloak_charges -= 1
	set_power_reward_visible("cloak", cloak_charges == 0)
	cloak_remaining = 4.0
	var tint := spider.visual.self_modulate
	tint.a = 0.25
	spider.visual.self_modulate = tint
	instruction_label.text = "Invisible for four seconds!"
	update_cloak_button()

func intro_goal() -> int:
	if bugs_mode:
		return bugs_mode_bug_count()
	if rival_levels:
		return mini(16, 5 + 2 * int(floor(log(float(intro_level)) / log(2.0))))
	return 5 + (intro_level - 1) * 5

func bugs_mode_bug_count() -> int:
	if intro_level <= 1:
		return 4
	if intro_level <= 3:
		return 5
	if intro_level <= 7:
		return 6
	if intro_level <= 15:
		return 7
	return mini(12, 8 + (intro_level - 16) / 8)

func bugs_mode_bug_is_strong(index: int) -> bool:
	if not bugs_mode or intro_level <= 1:
		return false
	var count := bugs_mode_bug_count()
	var first := (intro_level * 3) % count
	for strong_index in mini(3, count - 4):
		if index == (first + strong_index * 2) % count:
			return true
	return false

func bugs_mode_arena_scale() -> float:
	return minf(2.6, 1.6 + float(intro_level - 1) * 0.12)

func bugs_mode_time_limit() -> float:
	return BUGS_MODE_MIN_TIME + BUGS_MODE_START_EXTRA_TIME / (1.0 + 0.05 * float(intro_level - 1))

func bugs_mode_release_time(distance_rank: int) -> float:
	return 20.0 + 5.0 * float(distance_rank)

func bugs_mode_release_rank(node: int) -> int:
	var origin := web_points[bugs_mode_spider_start]
	var distance := web_points[node].distance_squared_to(origin)
	var rank := 0
	for other_node in bugs_mode_spawn_nodes:
		var other_distance := web_points[other_node].distance_squared_to(origin)
		if other_distance < distance or (other_distance == distance and other_node < node):
			rank += 1
	return rank

func compact_hunt() -> bool:
	return intro_mode and intro_level <= 5

func hunt_bounds() -> Rect2:
	if bugs_mode or rival_levels:
		var visible_size := get_viewport().get_visible_rect().size / BUGS_MODE_CAMERA_ZOOM * bugs_mode_arena_scale()
		return Rect2(WEB_CENTER - visible_size * 0.5, visible_size)
	return COMPACT_HUNT_BOUNDS if compact_hunt() else FIRST_HUNT_BOUNDS

func solo_player_start_node() -> int:
	return rival_mode_spider_start if rival_levels else SOLO_PLAYER_START

func solo_rival_start_node() -> int:
	return rival_mode_rival_start if rival_levels else SOLO_RIVAL_START

func rival_count_for_level() -> int:
	if not intro_mode:
		return 1
	if bugs_mode:
		return 0
	if rival_levels:
		return mini(4, 1 + int(floor(float(intro_level - 1) / 2.0)))
	if compact_hunt():
		return 1
	return mini(4, maxi(1, intro_level - 1))

func rivals_can_respawn() -> bool:
	return intro_mode and not bugs_mode and not rival_count_battle() and intro_level >= RIVAL_RESPAWN_START_LEVEL and caught_count < intro_goal()

func rival_count_battle() -> bool:
	return rival_levels and intro_level > 5

func player_fight_score() -> int:
	return caught_count if rival_count_battle() else player_power

func player_can_eat_rival(actor: Spider) -> bool:
	var rival_score := power_of_rival(actor)
	return player_fight_score() > rival_score if rival_count_battle() else player_fight_score() >= rival_score

func rival_can_eat_player(actor: Spider) -> bool:
	return power_of_rival(actor) > player_fight_score()

func rival_has_speed_power() -> bool:
	return false

func rival_has_web_power() -> bool:
	return not intro_mode

func rival_has_freeze_power() -> bool:
	return false

func base_rival_speed() -> float:
	if bugs_mode:
		return 300.0
	return 170.0 if intro_mode and intro_level == 1 else (185.0 if compact_hunt() else 210.0)

func rival_travel_speed(speed: float, chase_multiplier: float = 1.0) -> float:
	return minf(speed * chase_multiplier, base_spider_speed * 0.9) if intro_mode else speed * chase_multiplier

func intro_initial_bug_count() -> int:
	if bugs_mode:
		return bugs_mode_bug_count()
	if rival_levels:
		return mini(14, 3 + intro_level)
	if compact_hunt():
		return mini(5, intro_level + 2)
	return mini(8, 4 + intro_level)

func solo_scale_for_power(power: int) -> float:
	return minf(SOLO_MAX_SCALE, SOLO_START_SCALE.x + SOLO_GROWTH * sqrt(float(power)))

func rival_visual_scale_for_power(power: int) -> float:
	return minf(SOLO_MAX_SCALE, 0.30 + SOLO_GROWTH * sqrt(float(power)))

func advance_intro_level() -> void:
	_finish_advance_intro_level()

func _finish_advance_intro_level() -> void:
	get_node("/root/GameManager").advance_first_hunt(intro_level + 1, 0 if bugs_mode else player_power)

func player_catch_radius() -> float:
	if bugs_mode:
		return 90.0
	var base_radius := 60.0 + maxf(0.0, spider.visual.scale.x - SOLO_START_SCALE.x) * 90.0 if intro_mode else 72.0
	return base_radius + (95.0 if selected_style == 3 else 0.0)

func next_scene_path() -> String:
	return "res://scenes/first_hunt.tscn"

func add_power_reward_icon(button: Button, power_key: String) -> void:
	var ad_button := Button.new()
	ad_button.name = "RewardAdButton"
	ad_button.text = ""
	ad_button.tooltip_text = "Watch a rewarded ad for two %s charges" % button.tooltip_text
	ad_button.anchor_left = 0.0
	ad_button.anchor_right = 1.0
	ad_button.anchor_top = 0.0
	ad_button.anchor_bottom = 1.0
	ad_button.offset_left = 0.0
	ad_button.offset_right = 0.0
	ad_button.offset_top = 0.0
	ad_button.offset_bottom = 0.0
	ad_button.mouse_filter = Control.MOUSE_FILTER_STOP
	ad_button.visible = false
	var skin := StyleBoxFlat.new()
	skin.bg_color = Color(0.08, 0.32, 0.48, 0.97)
	skin.border_color = Color(1.0, 0.87, 0.39)
	skin.set_border_width_all(4)
	skin.set_corner_radius_all(16)
	for state in ["normal", "hover", "pressed"]:
		ad_button.add_theme_stylebox_override(state, skin)
	var ad_icon := TextureRect.new()
	ad_icon.name = "VideoIcon"
	ad_icon.texture = REWARD_AD_ICON
	ad_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ad_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ad_icon.anchor_right = 1.0
	ad_icon.anchor_bottom = 1.0
	ad_icon.offset_left = 4.0
	ad_icon.offset_right = -4.0
	ad_icon.offset_top = 0.0
	ad_icon.offset_bottom = -14.0
	ad_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ad_button.add_child(ad_icon)
	var reward_label := Label.new()
	reward_label.text = "+2"
	reward_label.anchor_right = 1.0
	reward_label.anchor_top = 1.0
	reward_label.anchor_bottom = 1.0
	reward_label.offset_top = -35.0
	reward_label.offset_bottom = -3.0
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_label.add_theme_font_override("font", GameFont.title_font())
	reward_label.add_theme_font_size_override("font_size", 26)
	reward_label.add_theme_color_override("font_color", Color(1.0, 0.97, 0.77))
	reward_label.add_theme_color_override("font_outline_color", Color(0.03, 0.16, 0.18))
	reward_label.add_theme_constant_override("outline_size", 5)
	reward_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ad_button.add_child(reward_label)
	ad_button.pressed.connect(request_power_reward.bind(power_key))
	button.add_child(ad_button)
	reward_ad_buttons[power_key] = ad_button

func set_power_reward_visible(power_key: String, show_reward: bool) -> void:
	var ad_button := reward_ad_buttons.get(power_key) as Button
	if is_instance_valid(ad_button):
		ad_button.visible = show_reward

func request_power_reward(power_key: String) -> void:
	if finished or intro_reveal_active or threat_warning_active or shop_open:
		return
	var reward_button := reward_ad_buttons.get(power_key) as Button
	if not is_instance_valid(reward_button) or not reward_button.visible:
		return
	var ads := get_node("/root/AdsManager")
	if ads.show_rewarded_power(grant_power_reward.bind(power_key)):
		instruction_label.text = "Game paused for rewarded ad. Earn two %s charges." % power_key
	else:
		instruction_label.text = "Rewarded ad is loading. Try again soon."

func grant_power_reward(power_key: String) -> void:
	if not is_inside_tree() or finished:
		return
	match power_key:
		"cut": cut_charges += 2
		"weave": build_charges += 2
		"boost": boost_charges += 2
		"stun": stun_charges += 2
		"timer": timer_charges += 2
		"cloak": cloak_charges += 2
		_: return
	set_power_reward_visible(power_key, false)
	instruction_label.text = "+2 %s charges earned!" % power_key
	update_power_buttons()
	update_cloak_button()

func make_power_button(parent: Control, at: Vector2, caption: String, icon: Texture2D = null) -> Button:
	var button := Button.new()
	button.text = caption if icon == null else ""
	button.tooltip_text = caption
	button.position = at
	button.size = Vector2(110, 110) if icon != null else Vector2(300, 90)
	button.add_theme_font_size_override("font_size", 29)
	button.add_theme_font_override("font", GameFont.display_font())
	var power_color := Color(0.10, 0.38, 0.32)
	match caption:
		"SPEED BOOST": power_color = Color(0.55, 0.32, 0.06)
		"FREEZE RIVAL": power_color = Color(0.10, 0.38, 0.59)
		"CUT TRAIL": power_color = Color(0.54, 0.20, 0.19)
		"CREATE WEB": power_color = Color(0.12, 0.44, 0.28)
		"CANCEL PATH": power_color = Color(0.35, 0.29, 0.50)
		"GO INVISIBLE": power_color = Color(0.25, 0.30, 0.56)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var skin := StyleBoxFlat.new()
		if icon == null:
			skin.bg_color = Color(0.11, 0.33, 0.29, 0.96) if state != "disabled" else Color(0.18, 0.23, 0.22, 0.95)
			if state == "hover":
				skin.bg_color = Color(0.19, 0.47, 0.38)
			skin.border_color = Color(0.95, 0.76, 0.34)
			skin.set_border_width_all(4)
			skin.set_corner_radius_all(18)
		else:
			skin.bg_color = Color(0.18, 0.22, 0.24, 0.90) if state == "disabled" else (power_color.lightened(0.16) if state == "hover" else (power_color.darkened(0.20) if state == "pressed" else power_color))
			skin.border_color = Color(0.95, 0.81, 0.48) if state != "disabled" else Color(0.63, 0.68, 0.66)
			skin.set_border_width_all(4)
			skin.set_corner_radius_all(22)
			skin.shadow_color = Color(0.0, 0.02, 0.03, 0.7)
			skin.shadow_size = 5
		button.add_theme_stylebox_override(state, skin)
	button.add_theme_color_override("font_color", Color(0.99, 0.96, 0.82))
	parent.add_child(button)
	if icon != null:
		var image := TextureRect.new()
		image.name = "PowerIcon"
		image.texture = icon
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if caption != "CANCEL PATH" and caption != "PAUSE":
			image.anchor_right = 1.0
			image.anchor_bottom = 1.0
			image.offset_left = 5.0
			image.offset_right = -5.0
			image.offset_top = 5.0
			image.offset_bottom = -5.0
		else:
			image.position = Vector2(5, 5)
			image.size = Vector2(100, 100)
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(image)
		if caption != "CANCEL PATH" and caption != "PAUSE":
			var badge := Panel.new()
			badge.name = "ChargeBadge"
			badge.anchor_left = 1.0
			badge.anchor_right = 1.0
			badge.offset_left = -37.0
			badge.offset_right = -3.0
			badge.offset_top = -2.0
			badge.offset_bottom = 34.0
			badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var badge_skin := StyleBoxFlat.new()
			badge_skin.bg_color = Color(0.08, 0.06, 0.02, 0.94)
			badge_skin.border_color = Color(1.0, 0.90, 0.39)
			badge_skin.set_border_width_all(2)
			badge_skin.set_corner_radius_all(12)
			badge.add_theme_stylebox_override("panel", badge_skin)
			button.add_child(badge)
			var charge := Label.new()
			charge.name = "Charge"
			charge.anchor_left = 1.0
			charge.anchor_right = 1.0
			charge.offset_left = -37.0
			charge.offset_right = -3.0
			charge.offset_top = -2.0
			charge.offset_bottom = 34.0
			charge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			charge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			charge.add_theme_font_override("font", GameFont.title_font())
			charge.add_theme_font_size_override("font_size", 28)
			charge.add_theme_color_override("font_color", Color(1.0, 0.96, 0.29))
			charge.add_theme_color_override("font_outline_color", Color(0.03, 0.06, 0.05))
			charge.add_theme_constant_override("outline_size", 5)
			charge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.add_child(charge)
	return button

func set_power_charge(button: Button, amount: int) -> void:
	var charge := button.get_node_or_null("Charge") as Label
	if charge != null:
		charge.text = "%d" % amount

func update_power_buttons() -> void:
	set_power_charge(cut_button, cut_charges)
	set_power_charge(weave_button, build_charges)
	cut_button.disabled = cut_charges <= 0
	weave_button.disabled = build_charges <= 0
	if (bugs_mode or rival_levels) and is_instance_valid(timer_button):
		set_power_charge(timer_button, timer_charges)
		timer_button.disabled = timer_charges <= 0 or finished
	if intro_mode and is_instance_valid(boost_button):
		set_power_charge(boost_button, boost_charges)
		boost_button.disabled = boost_charges <= 0 or boost_remaining > 0.0
		set_power_charge(stun_button, stun_charges)
		stun_button.disabled = stun_charges <= 0 or all_active_rivals().is_empty() or rival_stun_remaining > 0.0

func use_speed_boost() -> void:
	if boost_charges <= 0 or boost_remaining > 0.0 or finished or threat_warning_active:
		return
	boost_charges -= 1
	set_power_reward_visible("boost", boost_charges == 0)
	boost_remaining = 3.0
	spider.speed = base_spider_speed * 1.7
	instruction_label.text = "Speed boost active!"
	update_power_buttons()

func use_timer_power() -> void:
	if not (bugs_mode or rival_levels) or timer_charges <= 0 or finished or intro_reveal_active or threat_warning_active:
		return
	var extended := 0
	for bug in bugs:
		if bug.active and bug.stuck and not bug.permanently_trapped and not bug.escaping_flight:
			bug.glue_duration += 5.0
			bug.glue_remaining += 5.0
			bug.refresh_trap_bar()
			bug.queue_redraw()
			extended += 1
	if extended == 0:
		return
	timer_charges -= 1
	set_power_reward_visible("timer", timer_charges == 0)
	instruction_label.text = "+5 seconds for every trapped bug!"
	update_power_buttons()

func use_rival_stun() -> void:
	if stun_charges <= 0 or rival_stun_remaining > 0.0 or all_active_rivals().is_empty() or finished or threat_warning_active:
		return
	stun_charges -= 1
	set_power_reward_visible("stun", stun_charges == 0)
	rival_stun_remaining = 3.0
	if rival_active:
		rival.visual.modulate = Color(0.55, 0.8, 1.0)
		show_freeze_effect(rival, rival_stun_remaining)
	for hunter in extra_rivals:
		if hunter.active:
			hunter.stun_remaining = 3.0
			hunter.spider.visual.modulate = Color(0.55, 0.8, 1.0)
			show_freeze_effect(hunter.spider, hunter.stun_remaining)
	instruction_label.text = "Rivals frozen for three seconds!"
	update_power_buttons()

func show_freeze_effect(actor: Spider, duration: float) -> void:
	var effect = actor.get_node_or_null("FreezeEffect")
	if effect == null:
		effect = FrozenEffectScript.new()
		effect.name = "FreezeEffect"
		actor.add_child(effect)
	effect.radius = maxf(45.0, actor.visual.texture.get_size().x * actor.visual.scale.x * 0.63)
	effect.remaining = duration

func cancel_auto_navigation() -> void:
	target_bug = null
	destination_node = -1
	tap_destination_edge = -1
	chase_rival = false
	chase_extra_rival = null
	selected_repair_edge = -1
	if player_new_link_progress < 0.0:
		selected_new_link = Vector2i(-1, -1)
	weave_start_node = -1
	bugs_available_repair_edges.clear()
	bugs_available_new_targets.clear()
	auto_path.clear()
	weave_mode = false
	if is_instance_valid(weave_button):
		update_power_buttons()

func toggle_trail_cut() -> void:
	if cut_charges <= 0 or threat_warning_active:
		return
	trail_cut_enabled = not trail_cut_enabled
	update_power_buttons()
	instruction_label.text = ("Tap a web strand to cut it." if trail_cut_enabled else "Tap the web to move.") if bugs_mode or rival_levels else ("Trail cut is on: crossed links will break." if trail_cut_enabled else "Trail cut is off.")

func toggle_weave_mode() -> void:
	if build_charges <= 0 or threat_warning_active:
		return
	if bugs_mode:
		if weave_mode:
			weave_mode = false
			weave_start_node = -1
			bugs_available_repair_edges.clear()
			bugs_available_new_targets.clear()
			instruction_label.text = "Tap a bug to chase it."
			queue_redraw()
			return
		if player_repair_edge >= 0 or player_new_link_progress >= 0.0:
			return
		if spider_target != spider_node:
			var current_edge := edge_index(spider_node, spider_target)
			if spider_retreating and current_edge >= 0 and not edge_active[current_edge]:
				cancel_auto_navigation()
				selected_repair_edge = current_edge
				instruction_label.text = "Returning to the junction, then rebuilding this strand."
			else:
				instruction_label.text = "Reach a web junction before using Create Web."
			return
		cancel_auto_navigation()
		refresh_bugs_weave_options()
		if bugs_available_repair_edges.size() == 1:
			var repair_edge := bugs_available_repair_edges[0]
			bugs_available_repair_edges.clear()
			bugs_available_new_targets.clear()
			begin_player_repair(repair_edge)
			queue_redraw()
			return
		if bugs_available_repair_edges.is_empty() and bugs_available_new_targets.is_empty():
			instruction_label.text = "No web can be built from this junction."
			return
		weave_mode = true
		weave_start_node = spider_node
		instruction_label.text = "Tap a highlighted strand or junction to build from your spider."
		queue_redraw()
		return
	weave_mode = not weave_mode
	update_power_buttons()
	if not weave_mode:
		weave_start_node = -1
	instruction_label.text = "Tap a broken link or two nearby junctions." if weave_mode else "Tap a ladybug to chase it."

func refresh_bugs_weave_options() -> void:
	bugs_available_repair_edges.clear()
	bugs_available_new_targets.clear()
	if not bugs_mode or spider_target != spider_node:
		return
	for neighbor in adjacency[spider_node]:
		var index := edge_index(spider_node, neighbor)
		if not edge_active[index]:
			bugs_available_repair_edges.append(index)
	for candidate in web_points.size():
		if valid_new_link(spider_node, candidate):
			bugs_available_new_targets.append(candidate)

func restart() -> void:
	result_ad_serial += 1
	get_node("/root/AdsManager").hide_banner()
	panicking_rivals.clear()
	player_heading = Vector2.ZERO
	if is_instance_valid(rival):
		rival.set_panic(0.0)
	if is_instance_valid(rival_panic_audio):
		rival_panic_audio.stop()
	player_panicking = false
	spider.set_panic(0.0)
	if is_instance_valid(player_panic_audio):
		player_panic_audio.stop()
	if ready_audio_tween != null and ready_audio_tween.is_running():
		ready_audio_tween.kill()
	if is_instance_valid(rival_ready_audio):
		rival_ready_audio.stop()
	rival_bug_lead_announced = false
	if is_instance_valid(player_ready_audio):
		player_ready_audio.stop()
	if construction_tween != null and construction_tween.is_running():
		construction_tween.kill()
	if intro_reveal_tween != null and intro_reveal_tween.is_running():
		intro_reveal_tween.kill()
	if escape_focus_tween != null and escape_focus_tween.is_running():
		escape_focus_tween.kill()
	escape_focus_bug = null
	escape_focus_returning = false
	if duel_tween != null and duel_tween.is_running():
		duel_tween.kill()
	if threat_warning_tween != null and threat_warning_tween.is_running():
		threat_warning_tween.kill()
	threat_warning_active = false
	warned_rivals.clear()
	threat_warning_panel.hide()
	camera.limit_left = int(FIRST_HUNT_BOUNDS.position.x) if intro_mode else 0
	camera.limit_right = int(FIRST_HUNT_BOUNDS.end.x) if intro_mode else 1080
	camera.limit_top = int(FIRST_HUNT_BOUNDS.position.y) if intro_mode else -1850
	camera.limit_bottom = int(FIRST_HUNT_BOUNDS.end.y) if intro_mode else 1920
	camera.position_smoothing_enabled = true
	for hunter in extra_rivals:
		hunter.spider.queue_free()
	extra_rivals.clear()
	intro_reveal_active = false
	elapsed_seconds = 0.0
	bugs_failure_reason = ""
	game_hud.set_elapsed(bugs_mode_time_limit() if bugs_mode else 0.0)
	game_hud.set_health(100.0)
	spider.set_health(100.0)
	spider.health_bar.visible = not (bugs_mode or rival_levels)
	rival.set_health(100.0)
	rival.health_bar.visible = not (bugs_mode or rival_levels)
	player_power = 0 if bugs_mode else level_start_power + (2 if intro_mode and intro_level == 1 and selected_style == 4 else 0)
	rival_power = level_start_power
	rival_active = rival_count_for_level() > 0
	rival_respawn_remaining = 0.0
	player_active = true
	solo_spawn_timer = 0.0
	solo_spawned_count = 0
	silk_refill_remaining = 8.0
	clear_eating()
	for bug in bugs:
		bug.queue_free()
	bugs.clear()
	build_web_network()
	camera_zoom = 1.0 / bugs_mode_arena_scale() if bugs_mode or rival_levels else (COMPACT_CAMERA_ZOOM if compact_hunt() else DEFAULT_CAMERA_ZOOM)
	camera.zoom = Vector2.ONE * camera_zoom
	var bounds := hunt_bounds()
	camera.limit_left = int(bounds.position.x)
	camera.limit_right = int(bounds.end.x)
	camera.limit_top = int(bounds.position.y)
	camera.limit_bottom = int(bounds.end.y)
	caught_count = 0
	rival_caught_count = 0
	escaped_count = 0
	finished = false
	winner = 0
	active_touches.clear()
	touch_start_positions.clear()
	bugs_pinch_used = false
	bugs_drag_used = false
	pinch_start_distance = 0.0
	bugs_camera_offset = Vector2.ZERO
	building = true
	web_progress = 0.0
	spider_node = bugs_mode_spider_start if bugs_mode else (solo_player_start_node() if intro_mode else 0)
	spider_target = spider_node
	spider_progress = 0.0
	spider_retreating = false
	spider.position = web_points[spider_node]
	camera.position = WEB_CENTER
	update_camera_position()
	camera.reset_smoothing()
	spider.velocity = Vector2.ZERO
	spider.desired_direction = Vector2.ZERO
	spider.speed = base_spider_speed
	set_spider_walking_sound(false)
	set_rival_walking_sound(false)
	cloak_charges = 2
	cloak_remaining = 0.0
	shop_open = false
	shop_panel.hide()
	boost_charges = START_BOOST_CHARGES
	timer_charges = START_TIMER_CHARGES
	stun_charges = START_STUN_CHARGES
	boost_remaining = 0.0
	apply_selected_style()
	update_cloak_button()
	rival_stun_remaining = 0.0
	player_stun_remaining = 0.0
	rival_cut_charges = START_CUT_CHARGES if rival_has_web_power() else 0
	rival_boost_charges = START_BOOST_CHARGES if rival_has_speed_power() else 0
	rival_stun_charges = START_STUN_CHARGES if rival_has_freeze_power() else 0
	rival_boost_remaining = 0.0
	rival_power_cooldown = 6.0
	spider.reset_catch()
	spider.visual.modulate = Color.WHITE
	spider.show()
	if intro_mode:
		spider.visual.scale = Vector2.ONE * 0.30 if bugs_mode or rival_count_battle() else Vector2.ONE * (rival_visual_scale_for_power(player_power) if rival_levels else solo_scale_for_power(player_power))
	rival_node = rival_mode_rival_start if bugs_mode else (solo_rival_start_node() if intro_mode else 44)
	rival_target = rival_node
	rival_progress = 0.0
	rival_retreating = false
	rival_repair_edge = -1
	rival_rebuild_progress = 0.0
	player_repair_edge = -1
	player_rebuild_progress = 0.0
	selected_repair_edge = -1
	weave_start_node = -1
	selected_new_link = Vector2i(-1, -1)
	bugs_available_repair_edges.clear()
	bugs_available_new_targets.clear()
	player_new_link_progress = -1.0
	target_bug = null
	destination_node = -1
	tap_destination_edge = -1
	chase_rival = false
	chase_extra_rival = null
	auto_path.clear()
	trail_cut_enabled = false
	weave_mode = false
	cut_charges = START_CUT_CHARGES
	build_charges = START_BUILD_CHARGES
	for reward_button in reward_ad_buttons.values():
		if is_instance_valid(reward_button):
			reward_button.hide()
	rival_build_charges = START_BUILD_CHARGES if rival_has_web_power() else 0
	var manager := get_node("/root/GameManager")
	build_charges += manager.take_power_stock("weave")
	boost_charges += manager.take_power_stock("boost")
	if bugs_mode or rival_levels:
		timer_charges += manager.take_power_stock("timer")
	if not bugs_mode:
		cut_charges += manager.take_power_stock("cut")
		stun_charges += manager.take_power_stock("stun")
	if not bugs_mode and not rival_levels and selected_style == 2:
		cloak_charges += manager.take_power_stock("cloak")
	update_power_buttons()
	last_cut_msec = 0
	for i in edge_active.size():
		edge_active[i] = true
	rival.position = web_points[rival_node]
	rival.velocity = Vector2.ZERO
	rival.speed = base_rival_speed()
	rival.reset_catch()
	rival.visual.rotation = 0.0
	rival.visual.modulate = Color.WHITE
	if rival_active:
		rival.show()
	else:
		rival.hide()
	if intro_mode:
		rival.visual.scale = Vector2.ONE * 0.30 if bugs_mode else solo_start_scale
		spawn_extra_rivals()
	spider.visual.rotation = 0.0
	if rival != null:
		rival.gait_strength = 0.0
		rival.animate_walk(0.0, false)
	spider.gait_strength = 0.0
	spider.animate_walk(0.0, false)
	result_panel.visible = false
	result_dimmer.visible = false
	result_panel.scale = Vector2.ONE * 0.8
	result_panel.modulate = Color.WHITE
	if result_tween != null and result_tween.is_running():
		result_tween.kill()
	instruction_label.text = ("Catch the bugs before they escape!" if bugs_mode else ("Meet your rival..." if rival_active else "Explore the web and eat bugs.")) if intro_mode else "Your spider is weaving its web home..."
	var starts := [39, 40, 45, 46]
	var sizes := [0.72, 1.12, 1.55, 0.88, 1.30, 1.85]
	var glue_times := [20.0, 22.0, 24.0, 26.0] if intro_mode else [4.8, 5.6, 1.6, 4.2, 5.2, 1.25]
	if intro_mode:
		for i in intro_initial_bug_count():
			spawn_solo_bug(rival_levels)
	for i in (0 if intro_mode else BUG_COUNT):
		var bug = BugScript.new()
		var source := Rect2(425, 485, 350, 270)
		var route: Array[int] = []
		if i < starts.size():
			for ring_step in 5:
				route.append(starts[i] + ring_step * 12)
		else:
			var upper_column := 1 if i == 4 else 3
			for row in upper_nodes:
				route.append(row[upper_column])
		var travel_speed := 180.0 if i == 5 else (85.0 if i == 2 else 48.0)
		bug.setup(atlas_region(source), web_points, route, travel_speed, Callable(self, "web_position"), Callable(self, "web_length_between"), sizes[i], TrapBug.MotionStyle.CRAWL, float(glue_times[i]), i == 2 or i == 5)
		bug.escaped.connect(on_bug_escaped)
		bug.broke_free.connect(on_bug_broke_free)
		add_child(bug)
		bug.set_process(false)
		bugs.append(bug)
	update_status()
	if intro_mode:
		finish_construction()
		if bugs_mode:
			start_bugs_reveal()
		elif rival_active and (intro_level <= 2 or rival_levels):
			start_intro_reveal()
	else:
		construction_tween = create_tween()
		construction_tween.tween_property(self, "web_progress", 1.0, 2.5)
		construction_tween.finished.connect(finish_construction)
	queue_redraw()

func spawn_solo_bug(fly_in := true) -> void:
	var species_id := solo_spawned_count % HUNT_BUG_TEXTURES.size()
	var is_big := species_id == 1
	var node := -1
	if bugs_mode:
		if solo_spawned_count >= bugs_mode_spawn_nodes.size():
			return
		node = bugs_mode_spawn_nodes[solo_spawned_count]
	else:
		var candidates: Array[int] = []
		for candidate in range(1, web_points.size()):
			if is_big and adjacency[candidate].size() < 3:
				continue
			if web_points[candidate].distance_to(web_points[solo_player_start_node()]) < (130.0 if compact_hunt() else 180.0):
				continue
			if rival_count_for_level() > 0 and web_points[candidate].distance_to(web_points[solo_rival_start_node()]) < (130.0 if compact_hunt() else 180.0):
				continue
			var occupied := false
			for existing in bugs:
				if (existing.active or existing.arriving) and existing.position.distance_to(web_points[candidate]) < (170.0 if compact_hunt() else 230.0):
					occupied = true
					break
			if not occupied and not adjacency[candidate].is_empty():
				candidates.append(candidate)
		if candidates.is_empty():
			return
		node = candidates.pick_random()
	var route: Array[int] = [node, int(adjacency[node].pick_random())]
	var bug: TrapBug = BugScript.new()
	bug.flight_sounds_enabled = bugs_mode or rival_levels
	var can_escape := bugs_mode or (rival_levels and solo_spawned_count % 5 == 2) or (not rival_levels and solo_spawned_count % 3 == 2)
	var strong_bug := bugs_mode_bug_is_strong(solo_spawned_count)
	var bug_size := randf_range(1.12, 1.28) if species_id == 1 else (randf_range(0.72, 0.84) if species_id == 2 else randf_range(0.48, 0.60))
	if bugs_mode or rival_levels:
		bug_size = randf_range(1.12, 1.22) if species_id == 1 else (randf_range(0.86, 0.94) if species_id == 2 else randf_range(0.68, 0.76))
		if bugs_mode and strong_bug:
			bug_size *= 1.08
	var hold_time := bugs_mode_release_time(bugs_mode_release_rank(node)) if bugs_mode else (randf_range(90.0, 110.0) if rival_levels else randf_range(18.0, 26.0))
	bug.setup(BUGS_MODE_TEXTURES[species_id] if bugs_mode or rival_levels else HUNT_BUG_TEXTURES[species_id], web_points, route, 0.0, Callable(self, "web_position"), Callable(self, "web_length_between"), bug_size, TrapBug.MotionStyle.FLUTTER, hold_time, strong_bug)
	if bugs_mode or rival_levels:
		bug.land_motion_style = TrapBug.MotionStyle.CRAWL
		bug.base_scale *= 3.6
		bug.sprite.scale = bug.base_scale
		bug.health_bar.position.y = -maxf(72.0, 88.0 * bug_size)
		if bugs_mode:
			bug.show_release_timer()
	bug.species_id = species_id
	bug.permanently_trapped = not can_escape
	bug.flies_away_on_release = can_escape
	bug.web_cut_limit = (2 if is_big else 1) if compact_hunt() else (2 if is_big and (solo_spawned_count == 1 or randf() < 0.6) else (1 if not is_big and (solo_spawned_count == 2 or (solo_spawned_count > 0 and randf() < 0.3)) else 0))
	if bugs_mode:
		bug.web_cut_limit = bugs_mode_initial_links
		bug.repeat_web_cuts = true
	bug.web_cut_remaining = 0.0 if bugs_mode else randf_range(4.0, 7.0)
	bug.refresh_trap_bar()
	bug.escaped.connect(on_bug_escaped)
	bug.broke_free.connect(on_bug_broke_free)
	bug.web_cut_requested.connect(on_bug_web_cut_requested)
	add_child(bug)
	if fly_in:
		bug.start_arrival(web_points[node] + Vector2(randf_range(-310.0, 310.0), -560.0))
		bug.set_process(not building)
	bugs.append(bug)
	solo_spawned_count += 1

func finish_construction() -> void:
	if not building:
		return
	if construction_tween != null and construction_tween.is_running():
		construction_tween.kill()
	building = false
	web_progress = 1.0
	instruction_label.text = "Tap a bug to chase it across the web." if intro_mode else "Tap a ladybug to chase it across the web."
	for bug in bugs:
		if bug.active or bug.arriving:
			bug.set_process(true)
	queue_redraw()

func start_intro_reveal() -> void:
	intro_reveal_active = true
	for bug in bugs:
		if bug.arriving:
			bug.set_process(false)
	instruction_label.text = "A rival spider waits at the top of the web!"
	intro_reveal_tween = create_tween()
	if rival_levels:
		camera.position = rival.position
		camera.reset_smoothing()
		intro_reveal_tween.tween_interval(1.8)
		intro_reveal_tween.tween_property(camera, "position", spider.position, 0.85)
	else:
		intro_reveal_tween.tween_property(camera, "position", Vector2(WEB_CENTER.x, rival.position.y), 0.85)
		intro_reveal_tween.tween_interval(0.65)
		intro_reveal_tween.tween_property(camera, "position", WEB_CENTER, 0.85)
	intro_reveal_tween.finished.connect(finish_intro_reveal)

func start_bugs_reveal() -> void:
	intro_reveal_active = true
	camera.position_smoothing_enabled = false
	camera.position = WEB_CENTER
	instruction_label.text = "Find the bugs, then chase them from your spider!"
	for bug in bugs:
		bug.set_process(false)
	intro_reveal_tween = create_tween()
	intro_reveal_tween.tween_interval(1.8)
	intro_reveal_tween.tween_property(camera, "zoom", Vector2.ONE / bugs_mode_arena_scale(), 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	intro_reveal_tween.parallel().tween_property(camera, "position", spider.position, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	intro_reveal_tween.finished.connect(finish_bugs_reveal)

func finish_bugs_reveal() -> void:
	if intro_reveal_tween != null and intro_reveal_tween.is_running():
		intro_reveal_tween.kill()
	intro_reveal_active = false
	camera_zoom = 1.0 / bugs_mode_arena_scale()
	camera.zoom = Vector2.ONE * camera_zoom
	bugs_camera_offset = Vector2.ZERO
	camera.position_smoothing_enabled = true
	for bug in bugs:
		if bug.active:
			bug.set_process(true)
	update_camera_position()
	camera.reset_smoothing()
	instruction_label.text = "Catch bugs before they fly away."

func start_bug_escape_focus(bug: TrapBug) -> void:
	if escape_focus_bug != null:
		return
	escape_focus_bug = bug
	escape_focus_returning = false
	escape_focus_zoom = camera_zoom
	escape_focus_position = camera.position
	escape_focus_smoothing = camera.position_smoothing_enabled
	intro_reveal_active = true
	camera.position_smoothing_enabled = false
	camera.zoom = Vector2.ONE * maxf(camera_zoom, 1.45)
	for other in bugs:
		if other != bug:
			other.set_process(false)
	focus_camera_on_escaping_bug()
	camera.reset_smoothing()

func focus_camera_on_escaping_bug() -> void:
	if escape_focus_bug == null:
		return
	var bounds := hunt_bounds()
	var half_screen := get_viewport().get_visible_rect().size * 0.5 / camera.zoom
	var min_position := bounds.position + half_screen
	var max_position := bounds.end - half_screen
	camera.position = Vector2(
		clampf(escape_focus_bug.position.x, min_position.x, max_position.x) if min_position.x <= max_position.x else bounds.get_center().x,
		clampf(escape_focus_bug.position.y, min_position.y, max_position.y) if min_position.y <= max_position.y else bounds.get_center().y
	)

func return_from_bug_escape() -> void:
	if escape_focus_bug == null or escape_focus_returning:
		return
	escape_focus_returning = true
	escape_focus_tween = create_tween().set_parallel(true)
	escape_focus_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	escape_focus_tween.tween_property(camera, "position", escape_focus_position, 0.7)
	escape_focus_tween.tween_property(camera, "zoom", Vector2.ONE * escape_focus_zoom, 0.7)
	escape_focus_tween.finished.connect(finish_bug_escape_focus)

func finish_bug_escape_focus() -> void:
	if escape_focus_tween != null and escape_focus_tween.is_running():
		escape_focus_tween.kill()
	camera.zoom = Vector2.ONE * escape_focus_zoom
	camera.position = escape_focus_position
	camera.position_smoothing_enabled = escape_focus_smoothing
	escape_focus_bug = null
	escape_focus_returning = false
	intro_reveal_active = false
	for bug in bugs:
		if bug.active:
			bug.set_process(true)
	update_camera_position()
	camera.reset_smoothing()
	if not finished:
		check_round_complete()

func finish_intro_reveal() -> void:
	if intro_reveal_tween != null and intro_reveal_tween.is_running():
		intro_reveal_tween.kill()
	intro_reveal_active = false
	if rival_levels:
		play_player_ready_sound()
	for bug in bugs:
		if bug.arriving:
			bug.set_process(true)
	camera.position = spider.position if rival_levels else WEB_CENTER
	instruction_label.text = "Eat %d bugs to finish. Rivals are optional!" % intro_goal()

func spawn_extra_rivals() -> void:
	var homes: Array[int] = []
	if rival_levels:
		homes.assign([0, generated_grid_columns - 1, (generated_grid_rows - 1) * generated_grid_columns])
	elif intro_mode:
		homes.assign([89, 96, 85])
	else:
		homes.assign([upper_nodes[4][0], upper_nodes[4][4], upper_nodes[3][2]])
	for i in mini(3, maxi(0, rival_count_for_level() - 1)):
		var hunter := RivalHunter.new()
		hunter.home = homes[i]
		hunter.node = hunter.home
		hunter.target = hunter.home
		hunter.power = level_start_power
		hunter.spider = SpiderScript.new()
		hunter.spider.name = "RivalSpider%d" % (i + 2)
		hunter.spider.setup(normalized_rival_texture, 2)
		hunter.spider.health_bar.visible = not rival_levels
		hunter.spider.set_physics_process(false)
		hunter.spider.position = web_points[hunter.home]
		hunter.base_speed = 195.0 + i * 12.0
		hunter.spider.speed = hunter.base_speed
		hunter.cut_charges = START_CUT_CHARGES if rival_has_web_power() else 0
		hunter.build_charges = START_BUILD_CHARGES if rival_has_web_power() else 0
		hunter.boost_charges = START_BOOST_CHARGES if rival_has_speed_power() else 0
		hunter.stun_charges = START_STUN_CHARGES if rival_has_freeze_power() else 0
		hunter.power_cooldown = 7.0 + float(i)
		hunter.spider.visual.scale = solo_start_scale
		hunter.spider.visual.self_modulate = Color(1.0, 0.75 - i * 0.12, 0.75 + i * 0.08)
		add_child(hunter.spider)
		extra_rivals.append(hunter)

func all_active_rivals() -> Array[Spider]:
	var actors: Array[Spider] = []
	if rival_active:
		actors.append(rival)
	for hunter in extra_rivals:
		if hunter.active:
			actors.append(hunter.spider)
	return actors

func power_of_rival(actor: Spider) -> int:
	if actor == rival:
		return rival_caught_count if rival_count_battle() else rival_power
	for hunter in extra_rivals:
		if hunter.spider == actor:
			return hunter.bugs_eaten if rival_count_battle() else hunter.power
	return -1

func warning_camera_position(at: Vector2) -> Vector2:
	return at

func start_threat_warning(actor: Spider) -> void:
	threat_warning_active = true
	warned_rivals[actor.get_instance_id()] = true
	spider.desired_direction = Vector2.ZERO
	threat_warning_panel.show()
	threat_warning_title.text = "RIVAL HAS MORE BUGS!" if rival_count_battle() else "RIVAL IS COMING FOR YOU!"
	threat_warning_note.text = "Catch bugs or use FREEZE RIVAL!" if rival_count_battle() else "It is bigger. Run or use FREEZE RIVAL!"
	instruction_label.text = "A rival with more bugs is hunting you!" if rival_count_battle() else "A bigger rival is hunting you!"
	var return_position := camera.position
	camera.limit_left = -100000
	camera.limit_right = 100000
	camera.limit_top = -100000
	camera.limit_bottom = 100000
	camera.position_smoothing_enabled = false
	threat_warning_tween = create_tween()
	threat_warning_tween.tween_property(camera, "position", warning_camera_position(actor.position), 0.75)
	threat_warning_tween.tween_interval(1.5)
	threat_warning_tween.tween_property(camera, "position", return_position, 0.75)
	threat_warning_tween.finished.connect(finish_threat_warning)

func finish_threat_warning() -> void:
	if threat_warning_tween != null and threat_warning_tween.is_running():
		threat_warning_tween.kill()
	threat_warning_active = false
	threat_warning_panel.hide()
	var bounds := hunt_bounds()
	camera.limit_left = int(bounds.position.x)
	camera.limit_right = int(bounds.end.x)
	camera.limit_top = int(bounds.position.y)
	camera.limit_bottom = int(bounds.end.y)
	camera.position_smoothing_enabled = true
	update_camera_position()
	camera.reset_smoothing()
	instruction_label.text = "A rival with more bugs is coming! Run or use FREEZE RIVAL." if rival_count_battle() else "The bigger rival is coming for you! Run or use FREEZE RIVAL."

func update_threat_warning() -> bool:
	if not intro_mode or finished or not player_active:
		return false
	for actor in all_active_rivals():
		var key := actor.get_instance_id()
		if not rival_can_eat_player(actor):
			warned_rivals.erase(key)
		elif not warned_rivals.has(key) and cloak_remaining <= 0.0:
			start_threat_warning(actor)
			return true
	return false

func _process(delta: float) -> void:
	pulse += delta
	var audio_settings := get_node_or_null("/root/AppSettings")
	if audio_settings != null and not audio_settings.sfx_enabled:
		if is_instance_valid(rival_ready_audio) and rival_ready_audio.playing:
			rival_ready_audio.stop()
		if is_instance_valid(player_ready_audio) and player_ready_audio.playing:
			player_ready_audio.stop()
		if is_instance_valid(rival_panic_audio) and rival_panic_audio.playing:
			rival_panic_audio.stop()
		if is_instance_valid(player_panic_audio) and player_panic_audio.playing:
			player_panic_audio.stop()
	if escape_focus_bug != null and not escape_focus_returning:
		focus_camera_on_escaping_bug()
	if intro_reveal_active or shop_open or threat_warning_active:
		return
	for bug in bugs:
		var panic_level := 0.0
		var approaching := not player_heading.is_zero_approx() and player_heading.dot((bug.position - spider.position).normalized()) > 0.35
		if not finished and not building and player_active and bug.active and bug.stuck and (bug == target_bug or approaching):
			var alert_distance := 950.0 * bugs_mode_arena_scale() if bugs_mode or rival_levels else 650.0
			panic_level = clampf((alert_distance - spider.position.distance_to(bug.position)) / (alert_distance * 0.8), 0.0, 1.0)
			if panic_level >= 0.75 and not bug.approach_panic_played:
				bug.approach_panic_played = true
				play_sound(PANIC_BUG_SOUND, -8.0)
		bug.set_escape_panic(panic_level)
	update_rival_panic()
	update_player_panic()
	if not finished:
		elapsed_seconds += delta
		game_hud.set_elapsed(maxf(0.0, ceilf(bugs_mode_time_limit() - elapsed_seconds)) if bugs_mode else elapsed_seconds)
		if bugs_mode and elapsed_seconds >= bugs_mode_time_limit():
			winner = 1 if caught_count > 0 else 2
			bugs_failure_reason = "Time ran out."
			finish_match()
			return
	if update_threat_warning():
		return
	if cloak_remaining > 0.0:
		cloak_remaining = maxf(0.0, cloak_remaining - delta)
		if cloak_remaining <= 0.0:
			apply_selected_style()
			update_cloak_button()
	if intro_mode and not finished:
		if not bugs_mode:
			silk_refill_remaining -= delta
			if silk_refill_remaining <= 0.0:
				silk_refill_remaining = 8.0
				if build_charges < START_BUILD_CHARGES:
					build_charges += 1
					update_power_buttons()
		if boost_remaining > 0.0:
			boost_remaining = maxf(0.0, boost_remaining - delta)
			if boost_remaining <= 0.0:
				spider.speed = base_spider_speed
				update_power_buttons()
		if rival_stun_remaining > 0.0:
			rival_stun_remaining = maxf(0.0, rival_stun_remaining - delta)
			if rival_stun_remaining <= 0.0:
				rival.visual.modulate = Color.WHITE
				update_power_buttons()
		if player_stun_remaining > 0.0:
			player_stun_remaining = maxf(0.0, player_stun_remaining - delta)
			if player_stun_remaining <= 0.0:
				spider.visual.modulate = Color.WHITE
		if rival_boost_remaining > 0.0:
			rival_boost_remaining = maxf(0.0, rival_boost_remaining - delta)
			if rival_boost_remaining <= 0.0:
				rival.speed = base_rival_speed()
		rival_power_cooldown -= delta
		if rival_active and rival_power_cooldown <= 0.0:
			use_rival_ai_power()
		if not bugs_mode:
			solo_spawn_timer += delta
		if not bugs_mode and solo_spawn_timer >= 2.5:
			solo_spawn_timer = 0.0
			var active_bugs := 0
			for bug in bugs:
				if bug.active or bug.arriving:
					active_bugs += 1
			if active_bugs < intro_initial_bug_count():
				spawn_solo_bug()
		if rivals_can_respawn() and not rival_active and rival_count_for_level() > 0:
			rival_respawn_remaining -= delta
			if rival_respawn_remaining <= 0.0:
				respawn_solo_rival()
		for hunter in extra_rivals:
			if not hunter.active:
				if rivals_can_respawn():
					hunter.respawn_remaining -= delta
					if hunter.respawn_remaining <= 0.0:
						respawn_extra_rival(hunter)
			else:
				if hunter.eating_remaining > 0.0:
					hunter.eating_remaining = maxf(0.0, hunter.eating_remaining - delta)
				if hunter.boost_remaining > 0.0:
					hunter.boost_remaining = maxf(0.0, hunter.boost_remaining - delta)
					if hunter.boost_remaining <= 0.0:
						hunter.spider.speed = hunter.base_speed
				if hunter.stun_remaining <= 0.0:
					hunter.power_cooldown -= delta
					if hunter.power_cooldown <= 0.0:
						use_extra_rival_ai_power(hunter)
			if hunter.stun_remaining > 0.0:
				hunter.stun_remaining = maxf(0.0, hunter.stun_remaining - delta)
				if hunter.stun_remaining <= 0.0:
					hunter.spider.visual.modulate = Color.WHITE
	if building and Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down").length() > 0.1:
		finish_construction()
	if not finished and not building:
		var keyboard := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		if keyboard.length() > 0.1:
			spider.desired_direction = keyboard
			cancel_auto_navigation()
		else:
			spider.desired_direction = Vector2.ZERO
		if target_bug != null and not target_bug.active and not target_bug.arriving:
			cancel_auto_navigation()
		for bug in bugs:
			if not bug.active:
				continue
			if bug.route_index < bug.route.size() - 1:
				var bug_route_edge := edge_index(bug.route[bug.route_index], bug.route[bug.route_index + 1])
				if not edge_active[bug_route_edge] and not (bugs_mode and bug.stuck and bug.web_cut_edges.has(bug_route_edge)):
					bug.active = false
					bug.visible = false
					on_bug_escaped(bug)
					continue
			var blue_distance: float = spider.position.distance_to(bug.position + bug.sprite.position)
			var red_distance: float = rival.position.distance_to(bug.position) if rival_active else INF
			var blue_ready := player_active and player_eat_remaining <= 0.0 and player_rival_eat_remaining <= 0.0 and player_stun_remaining <= 0.0 and blue_distance <= player_catch_radius()
			var red_ready := rival_eat_remaining <= 0.0 and rival_stun_remaining <= 0.0 and red_distance <= 72.0
			if intro_mode and not blue_ready and not red_ready:
				for hunter in extra_rivals:
					if hunter.active and hunter.eating_remaining <= 0.0 and hunter.stun_remaining <= 0.0 and hunter.spider.position.distance_to(bug.position) <= 72.0:
						extra_rival_catch_bug(hunter, bug)
						break
			if blue_ready or red_ready:
				catch_bug(bug, 1 if blue_ready and (not red_ready or blue_distance <= red_distance) else 2)
	if building or player_eat_remaining > 0.0 or player_rival_eat_remaining > 0.0 or rival_eat_remaining > 0.0:
		queue_redraw()

func update_rival_panic() -> void:
	for actor in all_active_rivals():
		var distance := spider.position.distance_to(actor.position)
		var selected_chase := chase_rival and ((chase_extra_rival == null and actor == rival) or (chase_extra_rival != null and actor == chase_extra_rival.spider))
		var approaching := not player_heading.is_zero_approx() and player_heading.dot((actor.position - spider.position).normalized()) > 0.35
		var panic_level := 0.0
		if intro_mode and not finished and player_active and cloak_remaining <= 0.0 and player_can_eat_rival(actor) and (selected_chase or approaching):
			panic_level = clampf((700.0 - distance) / 520.0, 0.0, 1.0)
		actor.set_panic(panic_level)
		var key := actor.get_instance_id()
		if panic_level >= 0.45 and not panicking_rivals.has(key):
			panicking_rivals[key] = true
			var settings := get_node_or_null("/root/AppSettings")
			if (settings == null or settings.sfx_enabled) and not rival_panic_audio.playing:
				rival_panic_audio.play()
		elif panic_level <= 0.05:
			panicking_rivals.erase(key)

func update_player_panic() -> void:
	var panic_level := 0.0
	if intro_mode and not finished and player_active and cloak_remaining <= 0.0:
		for actor in all_active_rivals():
			if rival_can_eat_player(actor):
				panic_level = maxf(panic_level, clampf((700.0 - spider.position.distance_to(actor.position)) / 520.0, 0.0, 1.0))
	spider.set_panic(panic_level)
	if panic_level >= 0.45 and not player_panicking:
		player_panicking = true
		var settings := get_node_or_null("/root/AppSettings")
		if settings == null or settings.sfx_enabled:
			player_panic_audio.play()
	elif panic_level <= 0.05:
		player_panicking = false

func _physics_process(delta: float) -> void:
	if finished or building or intro_reveal_active or shop_open or threat_warning_active:
		player_heading = Vector2.ZERO
		set_spider_walking_sound(false)
		set_rival_walking_sound(false)
		return
	var spider_before_move := spider.position
	if not player_active:
		spider.animate_walk(delta, false)
	elif player_stun_remaining > 0.0:
		spider.animate_walk(delta, false)
	elif player_rival_eat_remaining > 0.0:
		player_rival_eat_remaining = maxf(0.0, player_rival_eat_remaining - delta)
		if player_rival_eat_remaining <= 0.0:
			finish_player_eat_rival()
	elif player_eat_remaining > 0.0:
		player_eat_remaining = maxf(0.0, player_eat_remaining - delta)
		if player_eat_remaining <= 0.0:
			finish_eating(1)
	else:
		move_spider_on_web(delta)
	var player_motion := spider.position - spider_before_move
	player_heading = player_motion.normalized() if player_motion.length_squared() > 0.25 else Vector2.ZERO
	if player_active and player_eat_remaining <= 0.0 and player_rival_eat_remaining <= 0.0 and player_stun_remaining <= 0.0:
		catch_bug_passed_on_way(spider_before_move, spider.position)
	set_spider_walking_sound(spider.position.distance_squared_to(spider_before_move) > 0.25)
	var rival_before_move := rival.position
	if rival_active and rival_stun_remaining <= 0.0:
		if rival_eat_remaining > 0.0:
			rival_eat_remaining = maxf(0.0, rival_eat_remaining - delta)
			if rival_eat_remaining <= 0.0:
				finish_eating(2)
		else:
			move_rival_on_web(delta)
	var rival_moving := rival_active and rival.position.distance_squared_to(rival_before_move) > 0.25
	if threat_warning_active:
		set_rival_walking_sound(false)
		return
	if intro_mode:
		for hunter in extra_rivals:
			if hunter.active and hunter.eating_remaining <= 0.0 and hunter.stun_remaining <= 0.0:
				var hunter_before_move := hunter.spider.position
				move_extra_rival(hunter, delta)
				rival_moving = rival_moving or hunter.spider.position.distance_squared_to(hunter_before_move) > 0.25
		set_rival_walking_sound(rival_moving)
		resolve_rival_duels()
		if threat_warning_active:
			return
		for actor in all_active_rivals():
			if player_rival_eat_remaining > 0.0:
				break
			if player_active and spider.position.distance_to(actor.position) <= SPIDER_SEPARATION + 18.0:
				resolve_player_rival_collision(actor)
	update_camera_position()

func update_camera_position() -> void:
	if intro_mode:
		var half_screen := get_viewport().get_visible_rect().size * 0.5 / camera.zoom
		var bounds := hunt_bounds()
		if bugs_mode or rival_levels:
			var arena_scale := bugs_mode_arena_scale()
			var follow_player := bugs_camera_offset.is_zero_approx() and camera_zoom > 1.0 / arena_scale + 0.001
			camera.limit_left = floori(bounds.position.x - (half_screen.x if follow_player else 0.0))
			camera.limit_right = ceili(bounds.end.x + (half_screen.x if follow_player else 0.0))
			camera.limit_top = floori(bounds.position.y - (half_screen.y if follow_player else 0.0))
			camera.limit_bottom = ceili(bounds.end.y + (half_screen.y if follow_player else 0.0))
			if follow_player:
				camera.position = spider.position
				return
		var horizontal_min := bounds.position.x + half_screen.x
		var horizontal_max := bounds.end.x - half_screen.x
		var vertical_min := bounds.position.y + half_screen.y
		var vertical_max := bounds.end.y - half_screen.y
		camera.position = Vector2(
			clampf(spider.position.x + (bugs_camera_offset.x if bugs_mode or rival_levels else 0.0), horizontal_min, horizontal_max) if horizontal_min <= horizontal_max else bounds.get_center().x,
			clampf(spider.position.y + (bugs_camera_offset.y if bugs_mode or rival_levels else 0.0), vertical_min, vertical_max) if vertical_min <= vertical_max else bounds.get_center().y
		)
	else:
		camera.position = Vector2(WEB_CENTER.x, minf(WEB_CENTER.y, spider.position.y))

func _unhandled_input(event: InputEvent) -> void:
	if finished or intro_reveal_active or shop_open or threat_warning_active or (intro_mode and not player_active):
		return
	if (bugs_mode or rival_levels) and DisplayServer.is_touchscreen_available() and event is InputEventMouse:
		return
	var touch_tap := false
	var touch_tap_point := Vector2.ZERO
	if event is InputEventScreenTouch:
		if bugs_mode or rival_levels:
			if event.pressed:
				active_touches[event.index] = event.position
				touch_start_positions[event.index] = event.position
				if active_touches.size() == 2:
					var locations := active_touches.values()
					pinch_start_distance = Vector2(locations[0]).distance_to(Vector2(locations[1]))
					pinch_start_zoom = camera_zoom
					bugs_pinch_used = true
				get_viewport().set_input_as_handled()
				return
			var was_single_tap := active_touches.size() == 1 and not bugs_pinch_used and not bugs_drag_used
			active_touches.erase(event.index)
			touch_start_positions.erase(event.index)
			if active_touches.size() < 2:
				pinch_start_distance = 0.0
			if active_touches.is_empty():
				if bugs_pinch_used and not is_equal_approx(camera_zoom, pinch_start_zoom):
					bugs_camera_offset = Vector2.ZERO
					update_camera_position()
					camera.reset_smoothing()
				bugs_pinch_used = false
				bugs_drag_used = false
			if not was_single_tap:
				return
			touch_tap = true
			touch_tap_point = event.position
		else:
			if event.pressed:
				active_touches[event.index] = event.position
				if active_touches.size() == 2:
					var locations := active_touches.values()
					var first: Vector2 = locations[0]
					var second: Vector2 = locations[1]
					pinch_start_distance = first.distance_to(second)
					pinch_start_zoom = camera_zoom
					get_viewport().set_input_as_handled()
					return
				if active_touches.size() > 2:
					get_viewport().set_input_as_handled()
					return
			else:
				active_touches.erase(event.index)
				if active_touches.size() < 2:
					pinch_start_distance = 0.0
				return
	if event is InputEventScreenDrag and active_touches.has(event.index):
		var previous_position: Vector2 = active_touches[event.index]
		var previous_locations := active_touches.values()
		var previous_center := Vector2.ZERO
		if active_touches.size() == 2:
			previous_center = (Vector2(previous_locations[0]) + Vector2(previous_locations[1])) * 0.5
		active_touches[event.index] = event.position
		if active_touches.size() == 2 and pinch_start_distance > 1.0:
			var locations := active_touches.values()
			var first: Vector2 = locations[0]
			var second: Vector2 = locations[1]
			set_camera_zoom(pinch_start_zoom * first.distance_to(second) / pinch_start_distance)
			if bugs_mode or rival_levels:
				pan_bugs_camera((first + second) * 0.5 - previous_center)
			get_viewport().set_input_as_handled()
		elif (bugs_mode or rival_levels) and active_touches.size() == 1:
			var start_position: Vector2 = touch_start_positions.get(event.index, previous_position)
			if bugs_drag_used or start_position.distance_to(event.position) > 14.0:
				bugs_drag_used = true
				pan_bugs_camera(event.position - previous_position)
			get_viewport().set_input_as_handled()
		return
	if building and ((event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed)):
		finish_construction()
	if building:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_C:
			toggle_trail_cut()
		elif event.keycode == KEY_B:
			toggle_weave_mode()
		elif event.keycode == KEY_ESCAPE:
			cancel_auto_navigation()
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			change_camera_zoom(CAMERA_ZOOM_STEP)
			get_viewport().set_input_as_handled()
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			change_camera_zoom(-CAMERA_ZOOM_STEP)
			get_viewport().set_input_as_handled()
			return
	var screen_point := Vector2.ZERO
	if touch_tap:
		screen_point = touch_tap_point
	elif event is InputEventScreenTouch and event.pressed:
		screen_point = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		screen_point = event.position
	else:
		return
	var point: Vector2 = get_canvas_transform().affine_inverse() * screen_point
	if (bugs_mode or rival_levels) and trail_cut_enabled:
		if cut_nearest_edge(point):
			trail_cut_enabled = false
			update_power_buttons()
			instruction_label.text = "Web cut. Tap the web to move."
		get_viewport().set_input_as_handled()
		return
	if intro_mode:
		for actor in all_active_rivals():
			if point.distance_to(actor.position) <= 85.0:
				cancel_auto_navigation()
				chase_rival = true
				if actor != rival:
					for hunter in extra_rivals:
						if hunter.spider == actor:
							chase_extra_rival = hunter
							break
				instruction_label.text = "Chasing a rival. Grow bigger to eat it!"
				get_viewport().set_input_as_handled()
				return
	if weave_mode:
		if bugs_mode:
			var local_broken := nearest_edge_at(point, false)
			var local_anchor := nearest_anchor_at(point)
			if local_broken < 0 and local_anchor >= 0:
				local_broken = edge_index(spider_node, local_anchor)
			if bugs_available_repair_edges.has(local_broken):
				cancel_auto_navigation()
				begin_player_repair(local_broken)
			elif bugs_available_new_targets.has(local_anchor):
				var start_node := spider_node
				cancel_auto_navigation()
				selected_new_link = Vector2i(start_node, local_anchor)
				begin_player_new_link()
			else:
				instruction_label.text = "Choose a highlighted connection beside your spider."
			queue_redraw()
			get_viewport().set_input_as_handled()
			return
		var broken := nearest_edge_at(point, false)
		if broken >= 0:
			cancel_auto_navigation()
			selected_repair_edge = broken
			update_power_buttons()
			instruction_label.text = "Moving to the gap to weave a new link."
			get_viewport().set_input_as_handled()
			return
		var anchor := nearest_anchor_at(point)
		if anchor >= 0:
			if weave_start_node < 0:
				weave_start_node = anchor
				instruction_label.text = "Tap a second nearby junction to connect."
			else:
				if valid_new_link(weave_start_node, anchor):
					var first_anchor := weave_start_node
					cancel_auto_navigation()
					selected_new_link = Vector2i(first_anchor, anchor)
					update_power_buttons()
					instruction_label.text = "Moving to weave a new silk link."
				else:
					instruction_label.text = "Choose two nearby junctions without crossing silk."
					weave_start_node = anchor
			queue_redraw()
			get_viewport().set_input_as_handled()
		return
	var selected_bug := nearest_bug_at(point)
	if selected_bug != null:
		cancel_auto_navigation()
		target_bug = selected_bug
		instruction_label.text = "Chasing ladybug by the shortest web route."
		get_viewport().set_input_as_handled()
		return
	var joint := nearest_anchor_at(point, 70.0)
	if joint >= 0:
		cancel_auto_navigation()
		destination_node = joint
		instruction_label.text = "Moving to the selected web junction."
		get_viewport().set_input_as_handled()
		return
	if bugs_mode or rival_levels:
		var touched_edge := nearest_edge_at(point, true)
		if touched_edge >= 0:
			var link: Vector2i = web_edges[touched_edge]
			var route_a := route_to_node(link.x)
			var route_b := route_to_node(link.y)
			var tap_progress := edge_tap_progress(touched_edge, point)
			cancel_auto_navigation()
			destination_node = link.x if route_a["cost"] + tap_progress * edge_lengths[touched_edge] <= route_b["cost"] + (1.0 - tap_progress) * edge_lengths[touched_edge] else link.y
			tap_destination_edge = touched_edge
			tap_destination_progress = tap_progress
			instruction_label.text = "Moving along the web to your tap."
		else:
			cancel_auto_navigation()
			destination_node = nearest_anchor_at(point, INF)
			instruction_label.text = "Moving to the nearest web junction."
		get_viewport().set_input_as_handled()
		return
	if cut_nearest_edge(point):
		get_viewport().set_input_as_handled()

func nearest_bug_at(point: Vector2) -> TrapBug:
	var chosen: TrapBug
	var best_distance := INF
	for bug in bugs:
		if not bug.active and not bug.arriving:
			continue
		var distance: float = point.distance_to(bug.position + bug.sprite.position)
		var radius: float = maxf(maxf(52.0, 47.0 * bug.size_factor), 52.0 / camera_zoom if bugs_mode or rival_levels else 0.0)
		if distance <= radius and distance < best_distance:
			chosen = bug
			best_distance = distance
	return chosen

func required_bug_repair_edge(bug: TrapBug) -> int:
	for index in bug.web_cut_edges:
		if not edge_active[index]:
			return index
	return -1

func on_bug_web_cut_requested(bug: TrapBug) -> void:
	if not intro_mode or finished or not bug.active or not bug.stuck or bug.web_cuts_done >= bug.web_cut_limit:
		return
	var node: int = bug.route[0]
	if bugs_mode:
		if bug != target_bug or spider.position.distance_to(bug.position) >= 950.0 * bugs_mode_arena_scale():
			return
		var approach_edge := -1
		if spider_target == node and spider_node != node:
			approach_edge = edge_index(spider_node, node)
		else:
			var approach_path: Array = route_to_node(node)["path"]
			if approach_path.size() >= 2:
				approach_edge = edge_index(int(approach_path[-2]), node)
		var occupied_spider_edge := edge_index(spider_node, spider_target) if spider_target != spider_node else -1
		if approach_edge < 0 or not edge_active[approach_edge] or approach_edge == occupied_spider_edge:
			if bug.species_id != 1:
				return
			# A large bug can eventually sever every link at its own junction.
			# It still tears just one link per cooldown and never cuts beneath the spider.
			var nearest_remaining := INF
			for neighbor in adjacency[node]:
				var candidate_edge := edge_index(node, neighbor)
				if candidate_edge == occupied_spider_edge or not edge_active[candidate_edge]:
					continue
				var distance_to_spider := web_points[neighbor].distance_to(spider.position)
				if distance_to_spider < nearest_remaining:
					nearest_remaining = distance_to_spider
					approach_edge = candidate_edge
		if approach_edge < 0 or not edge_active[approach_edge] or approach_edge == occupied_spider_edge:
			return
		if cut_edge(approach_edge, 4):
			bug.web_cut_edges.append(approach_edge)
			bug.web_cuts_done += 1
			bug.web_needs_repair = true
			bug.flash_web_cut()
			instruction_label.text = "The large bug is tearing every route to it! Use Create Web beside your spider." if bug.species_id == 1 else "The chased bug cut your approach! Find another route or use Create Web."
		return
	var candidates: Array[int] = []
	for neighbor in adjacency[node]:
		var index := edge_index(node, neighbor)
		if not edge_active[index] or index == edge_index(bug.route[0], bug.route[1]) or (spider_target != spider_node and index == edge_index(spider_node, spider_target)):
			continue
		var occupied := false
		for other in bugs:
			if other.active and edge_index(other.route[0], other.route[1]) == index:
				occupied = true
				break
		if not occupied:
			candidates.append(index)
	if candidates.is_empty():
		return
	var index: int = candidates.pick_random()
	if cut_edge(index, 4):
		bug.web_cut_edges.append(index)
		bug.web_cuts_done += 1
		bug.web_needs_repair = true
		bug.queue_redraw()
		instruction_label.text = "A bug tore a web link! Use Create Web beside your spider to repair it."

func nearest_edge_at(point: Vector2, active_state: bool) -> int:
	var best := -1
	var best_distance := 38.0 / camera_zoom if bugs_mode or rival_levels else 38.0
	for i in web_edges.size():
		if edge_active[i] != active_state:
			continue
		var edge := web_edges[i]
		var curve := strand_points(web_points[edge.x], web_points[edge.y], i, edge_kind[i])
		for part in curve.size() - 1:
			var nearest := Geometry2D.get_closest_point_to_segment(point, curve[part], curve[part + 1])
			var distance := nearest.distance_to(point)
			if distance < best_distance:
				best = i
				best_distance = distance
	return best

func edge_tap_progress(index: int, point: Vector2) -> float:
	var edge: Vector2i = web_edges[index]
	var curve := strand_points(web_points[edge.x], web_points[edge.y], index, edge_kind[index])
	var best_distance := INF
	var best_progress := 0.0
	for part in curve.size() - 1:
		var from: Vector2 = curve[part]
		var to: Vector2 = curve[part + 1]
		var nearest := Geometry2D.get_closest_point_to_segment(point, from, to)
		var distance := point.distance_squared_to(nearest)
		if distance < best_distance:
			best_distance = distance
			var segment := to - from
			var portion := clampf((nearest - from).dot(segment) / segment.length_squared(), 0.0, 1.0) if segment.length_squared() > 0.0 else 0.0
			best_progress = (float(part) + portion) / float(curve.size() - 1)
	return best_progress

func nearest_anchor_at(point: Vector2, max_distance := 42.0) -> int:
	var chosen := -1
	var best_distance := max_distance / camera_zoom if bugs_mode or rival_levels else max_distance
	for i in web_points.size():
		var distance := point.distance_to(web_points[i])
		if distance < best_distance:
			best_distance = distance
			chosen = i
	return chosen

func valid_new_link(a: int, b: int) -> bool:
	if bugs_mode and web_edges.size() >= bugs_mode_initial_links + (0 if intro_level == 1 else 2):
		return false
	if a < 0 or b < 0 or a == b or edge_index(a, b) >= 0:
		return false
	var from := web_points[a]
	var to := web_points[b]
	var length := from.distance_to(to)
	if length < 55.0 or length > (390.0 * bugs_mode_arena_scale() if bugs_mode or rival_levels else 390.0):
		return false
	var new_curve := strand_points(from, to, web_edges.size(), 2)
	for node in web_points.size():
		if node == a or node == b:
			continue
		for new_part in new_curve.size() - 1:
			if Geometry2D.get_closest_point_to_segment(web_points[node], new_curve[new_part], new_curve[new_part + 1]).distance_to(web_points[node]) < 14.0:
				return false
	for index in web_edges.size():
		var edge := web_edges[index]
		if edge.x == a or edge.x == b or edge.y == a or edge.y == b:
			continue
		var curve := strand_points(web_points[edge.x], web_points[edge.y], index, edge_kind[index])
		for new_part in new_curve.size() - 1:
			for part in curve.size() - 1:
				if Geometry2D.segment_intersects_segment(new_curve[new_part], new_curve[new_part + 1], curve[part], curve[part + 1]) != null:
					return false
	return true

func edge_index(a: int, b: int) -> int:
	return int(edge_lookup.get(Vector2i(a, b), -1))

func web_length_between(a: int, b: int) -> float:
	var index := edge_index(a, b)
	return edge_lengths[index] if index >= 0 else INF

func web_position(a: int, b: int, progress: float) -> Vector2:
	if progress <= 0.0:
		return web_points[a]
	if progress >= 1.0:
		return web_points[b]
	var index := edge_index(a, b)
	if index < 0:
		return web_points[a]
	var edge := web_edges[index]
	var t := progress if edge.x == a else 1.0 - progress
	return strand_curve_point(web_points[edge.x], web_points[edge.y], index, edge_kind[index], t)

func web_tangent(a: int, b: int, progress: float) -> Vector2:
	var before := web_position(a, b, maxf(0.0, progress - 0.01))
	var after := web_position(a, b, minf(1.0, progress + 0.01))
	return (after - before).normalized()

func cut_nearest_edge(point: Vector2) -> bool:
	if cut_charges <= 0:
		instruction_label.text = "No cut charges left this round."
		return false
	var now := Time.get_ticks_msec()
	if now - last_cut_msec < 400:
		return false
	var best := nearest_edge_at(point, true)
	if best == -1:
		return false
	last_cut_msec = now
	return cut_edge(best, 1)

func cut_edge(index: int, team: int = 0, hunter: RivalHunter = null) -> bool:
	if index < 0 or index >= edge_active.size() or not edge_active[index]:
		return false
	if team == 4 and spider_target != spider_node and edge_index(spider_node, spider_target) == index:
		return false
	if intro_mode:
		for bug in bugs:
			if bug.active and edge_index(bug.route[0], bug.route[1]) == index:
				if not (bugs_mode and team == 4):
					instruction_label.text = "A bug is on that link. Eat it before cutting."
					return false
	if team == 1:
		if cut_charges <= 0:
			return false
		cut_charges -= 1
		set_power_reward_visible("cut", cut_charges == 0)
		if cut_charges == 0:
			trail_cut_enabled = false
		update_power_buttons()
	elif team == 2 and intro_mode:
		if not rival_has_web_power() or rival_cut_charges <= 0:
			return false
		rival_cut_charges -= 1
	elif team == 3 and intro_mode:
		if not rival_has_web_power() or hunter == null or hunter.cut_charges <= 0:
			return false
		hunter.cut_charges -= 1
	edge_active[index] = false
	auto_path.clear()
	var edge := web_edges[index]
	if spider_target != spider_node and edge_index(spider_node, spider_target) == index:
		spider_retreating = true
	if rival != null and rival_target != rival_node and edge_index(rival_node, rival_target) == index:
		rival_retreating = true
	for other in extra_rivals:
		if other.active and other.target != other.node and edge_index(other.node, other.target) == index:
			other.target = other.node
			other.progress = 0.0
			other.spider.position = web_points[other.node]
	var dropped_bug := false
	for bug in bugs:
		if bug.active and bug.route_index < bug.route.size() - 1:
			if edge_index(bug.route[bug.route_index], bug.route[bug.route_index + 1]) == index:
				if bugs_mode and team == 4:
					continue
				bug.active = false
				bug.visible = false
				on_bug_escaped(bug)
				dropped_bug = true
	if not finished:
		instruction_label.text = "A bug escaped through the cut!" if dropped_bug else "Web cut! The rival must rebuild this strand."
	queue_redraw()
	return true

func restore_edge(index: int, team: int = 2) -> void:
	if index < 0 or index >= edge_active.size():
		return
	edge_active[index] = true
	for bug in bugs:
		if bug.web_needs_repair and required_bug_repair_edge(bug) < 0:
			bug.web_needs_repair = false
			bug.queue_redraw()
	if team == 1:
		player_repair_edge = -1
		player_rebuild_progress = 0.0
		instruction_label.text = "You wove a new link across the gap."
	elif team == 2:
		rival_repair_edge = -1
		rival_rebuild_progress = 0.0
		instruction_label.text = "Rival rebuilt the strand. Cut another to delay it!"
	else:
		instruction_label.text = "A rival rebuilt the strand!"
	auto_path.clear()
	queue_redraw()

func spider_step_is_clear(actor: Spider, proposed: Vector2) -> bool:
	if intro_mode:
		# First Hunt resolves unequal-size contact as combat. Equal-size spiders
		# must be able to cross, otherwise both stop forever on the same strand.
		return hunt_bounds().has_point(proposed)
	if rival == null or (intro_mode and (not rival_active or not player_active or cloak_remaining > 0.0)):
		return true
	var other: Spider = rival if actor == spider else spider
	var old_distance := actor.position.distance_to(other.position)
	var new_distance := proposed.distance_to(other.position)
	if old_distance < SPIDER_SEPARATION:
		return new_distance > old_distance
	if new_distance < SPIDER_SEPARATION:
		return false
	var nearest := Geometry2D.get_closest_point_to_segment(other.position, actor.position, proposed)
	return nearest.distance_to(other.position) >= SPIDER_SEPARATION

func begin_player_repair(index: int) -> bool:
	if index < 0 or edge_active[index] or build_charges <= 0:
		return false
	var edge := web_edges[index]
	if spider_target != spider_node or (spider_node != edge.x and spider_node != edge.y):
		return false
	build_charges -= 1
	set_power_reward_visible("weave", build_charges == 0)
	update_power_buttons()
	player_repair_edge = index
	player_rebuild_progress = 0.0
	instruction_label.text = "Weaving a new link across the gap..."
	queue_redraw()
	return true

func begin_player_new_link() -> bool:
	if selected_new_link.x < 0 or spider_target != spider_node or spider_node != selected_new_link.x:
		return false
	if build_charges <= 0 or not valid_new_link(selected_new_link.x, selected_new_link.y):
		selected_new_link = Vector2i(-1, -1)
		return false
	build_charges -= 1
	set_power_reward_visible("weave", build_charges == 0)
	update_power_buttons()
	player_new_link_progress = 0.0
	instruction_label.text = "Spinning a new silk connection..."
	queue_redraw()
	return true

func complete_player_new_link() -> void:
	if selected_new_link.x < 0 or not valid_new_link(selected_new_link.x, selected_new_link.y):
		player_new_link_progress = -1.0
		selected_new_link = Vector2i(-1, -1)
		return
	var a := selected_new_link.x
	var b := selected_new_link.y
	var index := web_edges.size()
	add_web_edge(a, b, 2)
	var curve := strand_points(web_points[a], web_points[b], index, 2)
	var length := 0.0
	for part in curve.size() - 1:
		length += curve[part].distance_to(curve[part + 1])
	edge_lengths.append(length)
	selected_new_link = Vector2i(-1, -1)
	player_new_link_progress = -1.0
	auto_path.clear()
	instruction_label.text = "New web link ready. Both spiders can use it."
	queue_redraw()

func route_to_node(destination: int) -> Dictionary:
	var node_count := web_points.size()
	var repair_budget := mini(build_charges, web_edges.size())
	var state_count := node_count * (repair_budget + 1)
	var distances: Array[float] = []
	var previous: Array[int] = []
	var visited: Array[bool] = []
	for state in state_count:
		distances.append(INF)
		previous.append(-1)
		visited.append(false)
	if spider_target == spider_node:
		distances[spider_node] = 0.0
	else:
		var remaining_edge := web_length_between(spider_node, spider_target)
		distances[spider_node] = spider_progress * remaining_edge
		distances[spider_target] = (1.0 - spider_progress) * remaining_edge
	for iteration in state_count:
		var current := -1
		for state in state_count:
			if not visited[state] and (current == -1 or distances[state] < distances[current]):
				current = state
		if current < 0 or is_inf(distances[current]):
			break
		if current % node_count == destination:
			var path: Array[int] = []
			var cursor := current
			while cursor >= 0:
				path.push_front(cursor % node_count)
				cursor = previous[cursor]
			return {"cost": distances[current], "path": path}
		visited[current] = true
		var node := current % node_count
		var used_builds := int(current / node_count)
		for neighbor in adjacency[node]:
			var index := edge_index(node, neighbor)
			var next_builds: int = used_builds + (0 if edge_active[index] else 1)
			if next_builds > repair_budget:
				continue
			var next_state: int = next_builds * node_count + int(neighbor)
			var weave_cost := spider.speed * REBUILD_TIME if not edge_active[index] else 0.0
			var candidate: float = distances[current] + edge_lengths[index] + weave_cost
			if candidate < distances[next_state]:
				distances[next_state] = candidate
				previous[next_state] = current
	var no_path: Array[int] = []
	return {"cost": INF, "path": no_path}

func plan_auto_path() -> Array[int]:
	if chase_rival and chase_extra_rival != null and chase_extra_rival.active:
		var destination: int = chase_extra_rival.node if chase_extra_rival.progress < 0.5 else chase_extra_rival.target
		return route_to_node(destination)["path"]
	if chase_rival and rival_active:
		var destination: int = rival_node if rival_progress < 0.5 else rival_target
		return route_to_node(destination)["path"]
	if selected_new_link.x >= 0:
		return route_to_node(selected_new_link.x)["path"]
	if selected_repair_edge >= 0:
		if edge_active[selected_repair_edge]:
			selected_repair_edge = -1
			return []
		var repair := web_edges[selected_repair_edge]
		var toward_a := route_to_node(repair.x)
		var toward_b := route_to_node(repair.y)
		return toward_a["path"] if toward_a["cost"] <= toward_b["cost"] else toward_b["path"]
	if destination_node >= 0:
		return route_to_node(destination_node)["path"]
	if tap_destination_edge >= 0:
		var tapped_link: Vector2i = web_edges[tap_destination_edge]
		if spider_node == tapped_link.x:
			return [tapped_link.x, tapped_link.y]
		if spider_node == tapped_link.y:
			return [tapped_link.y, tapped_link.x]
		return []
	if target_bug == null or (not target_bug.active and not target_bug.arriving):
		return []
	if target_bug.arriving:
		return route_to_node(target_bug.route[0])["path"]
	var required_edge := -1 if bugs_mode else required_bug_repair_edge(target_bug)
	if required_edge >= 0:
		var torn := web_edges[required_edge]
		var route_a := route_to_node(torn.x)
		var route_b := route_to_node(torn.y)
		return route_a["path"] if route_a["cost"] <= route_b["cost"] else route_b["path"]
	var near_node: int = target_bug.route[target_bug.route_index]
	var near_route := route_to_node(near_node)
	if target_bug.stuck or target_bug.route_index >= target_bug.route.size() - 1:
		return near_route["path"]
	var far_node: int = target_bug.route[target_bug.route_index + 1]
	var far_route := route_to_node(far_node)
	var length := web_length_between(near_node, far_node)
	var near_cost: float = near_route["cost"] + target_bug.progress * length
	var far_cost: float = far_route["cost"] + (1.0 - target_bug.progress) * length
	return near_route["path"] if near_cost <= far_cost else far_route["path"]

func move_rival_on_web(delta: float) -> void:
	var chase_speed := 1.3 if intro_mode and rival_can_eat_player(rival) and player_active and cloak_remaining <= 0.0 else 1.0
	var travel_speed := rival_travel_speed(rival.speed, chase_speed)
	if intro_mode and player_active and cloak_remaining <= 0.0 and not rival_can_eat_player(rival) and rival.position.distance_to(spider.position) < 650.0:
		if rival_target != rival_node and rival_progress > 0.0 and web_points[rival_target].distance_to(spider.position) < web_points[rival_node].distance_to(spider.position):
			var previous := rival_node
			rival_node = rival_target
			rival_target = previous
			rival_progress = 1.0 - rival_progress
	if rival_retreating:
		var before := rival.position
		var next_progress := maxf(0.0, rival_progress - travel_speed * delta / web_length_between(rival_node, rival_target))
		var proposed := web_position(rival_node, rival_target, next_progress)
		if not spider_step_is_clear(rival, proposed):
			rival.animate_walk(delta, false)
			return
		rival_progress = next_progress
		rival.position = proposed
		rival.face_motion(rival.position - before, delta)
		rival.animate_walk(delta, true)
		if rival_progress <= 0.0:
			rival_target = rival_node
			rival_retreating = false
		return
	if rival_repair_edge >= 0:
		rival_rebuild_progress += delta / 2.5
		rival.animate_walk(delta, false)
		if rival_rebuild_progress >= 1.0:
			restore_edge(rival_repair_edge)
		queue_redraw()
		return
	if rival_target == rival_node:
		rival_target = choose_rival_next_node()
	if rival_target == rival_node:
		rival.animate_walk(delta, false)
		return
	var length := web_length_between(rival_node, rival_target)
	var before := rival.position
	var next_progress := minf(1.0, rival_progress + travel_speed * delta / length)
	var proposed := web_position(rival_node, rival_target, next_progress)
	if not spider_step_is_clear(rival, proposed):
		rival.animate_walk(delta, false)
		return
	rival_progress = next_progress
	rival.position = proposed
	rival.face_motion(rival.position - before, delta)
	rival.animate_walk(delta, true)
	if rival_progress >= 1.0:
		rival_node = rival_target
		rival_progress = 0.0

func choose_rival_next_node() -> int:
	if intro_mode and player_active and cloak_remaining <= 0.0 and not rival_can_eat_player(rival) and rival.position.distance_to(spider.position) < 650.0:
		return escape_step_from(rival_node, spider.position)
	var distances: Array[float] = []
	var previous: Array[int] = []
	var visited: Array[bool] = []
	for i in web_points.size():
		distances.append(INF)
		previous.append(-1)
		visited.append(false)
	distances[rival_node] = 0.0
	for i in web_points.size():
		var current := -1
		for node in web_points.size():
			if not visited[node] and (current == -1 or distances[node] < distances[current]):
				current = node
		if current == -1 or is_inf(distances[current]):
			break
		visited[current] = true
		for neighbor in adjacency[current]:
			if not edge_active[edge_index(current, neighbor)]:
				continue
			var candidate: float = distances[current] + web_length_between(current, neighbor)
			if candidate < distances[neighbor]:
				distances[neighbor] = candidate
				previous[neighbor] = current
	if intro_mode:
		var hunt_destination := -1
		var hunt_distance := INF
		if rival_can_eat_player(rival) and cloak_remaining <= 0.0 and player_active:
			var player_destination: int = spider_node if spider_progress < 0.5 else spider_target
			hunt_destination = player_destination
			hunt_distance = distances[player_destination]
		for hunter in extra_rivals:
			if hunter.active and power_of_rival(rival) > power_of_rival(hunter.spider):
				var prey_destination: int = hunter.node if hunter.progress < 0.5 else hunter.target
				if distances[prey_destination] < hunt_distance:
					hunt_distance = distances[prey_destination]
					hunt_destination = prey_destination
		if hunt_destination >= 0 and hunt_destination != rival_node and not is_inf(hunt_distance):
			return first_step_to(hunt_destination, previous)
	var repair_distance := INF
	var repair_endpoint := -1
	var repair_edge := -1
	for i in web_edges.size():
		if edge_active[i]:
			continue
		var broken := web_edges[i]
		for endpoint in [broken.x, broken.y]:
			if distances[endpoint] < repair_distance:
				repair_distance = distances[endpoint]
				repair_endpoint = endpoint
				repair_edge = i
	if repair_endpoint >= 0:
		if rival_build_charges <= 0:
			repair_endpoint = -1
		elif repair_endpoint == rival_node:
			rival_build_charges -= 1
			rival_repair_edge = repair_edge
			rival_rebuild_progress = 0.0
			return rival_node
		else:
			return first_step_to(repair_endpoint, previous)
	var best_score := INF
	var best_endpoint := -1
	var best_other := -1
	for bug in bugs:
		if not bug.active or bug.route_index >= bug.route.size() - 1:
			continue
		var near_node: int = bug.route[bug.route_index]
		var far_node: int = bug.route[bug.route_index + 1]
		var edge_length: float = web_length_between(near_node, far_node)
		var near_score: float = distances[near_node] + bug.progress * edge_length
		var far_score: float = distances[far_node] + (1.0 - bug.progress) * edge_length
		if near_score < best_score:
			best_score = near_score
			best_endpoint = near_node
			best_other = far_node
		if far_score < best_score:
			best_score = far_score
			best_endpoint = far_node
			best_other = near_node
	if best_endpoint == -1:
		return rival_node
	if best_endpoint == rival_node:
		return best_other
	return first_step_to(best_endpoint, previous)

func first_step_to(destination: int, previous: Array[int]) -> int:
	var step := destination
	while previous[step] != -1 and previous[step] != rival_node:
		step = previous[step]
	return step if previous[step] == rival_node else rival_node

func next_step_from(start: int, destination: int) -> int:
	if start == destination:
		return start
	var queue: Array[int] = [start]
	var previous := {}
	previous[start] = start
	var cursor := 0
	while cursor < queue.size():
		var node: int = queue[cursor]
		cursor += 1
		for neighbor in adjacency[node]:
			if previous.has(neighbor) or not edge_active[edge_index(node, neighbor)]:
				continue
			previous[neighbor] = node
			if neighbor == destination:
				var step: int = destination
				while previous[step] != start:
					step = previous[step]
				return step
			queue.append(neighbor)
	return start

func escape_step_from(start: int, danger: Vector2) -> int:
	var best := start
	var best_distance := -1.0
	for neighbor in adjacency[start]:
		if not edge_active[edge_index(start, neighbor)]:
			continue
		var distance: float = web_points[neighbor].distance_squared_to(danger)
		if distance > best_distance:
			best_distance = distance
			best = neighbor
	return best

func extra_rival_destination(hunter: RivalHunter) -> int:
	if player_active and cloak_remaining <= 0.0 and not rival_can_eat_player(hunter.spider) and hunter.spider.position.distance_to(spider.position) < 650.0:
		return escape_step_from(hunter.node, spider.position)
	var best_node := hunter.node
	var best_distance := INF
	if player_active and cloak_remaining <= 0.0 and rival_can_eat_player(hunter.spider):
		best_node = spider_node if spider_progress < 0.5 else spider_target
		best_distance = hunter.spider.position.distance_to(spider.position)
	for actor in all_active_rivals():
		if actor == hunter.spider or power_of_rival(hunter.spider) <= power_of_rival(actor):
			continue
		var distance := hunter.spider.position.distance_to(actor.position)
		if distance < best_distance:
			best_distance = distance
			if actor == rival:
				best_node = rival_node if rival_progress < 0.5 else rival_target
			else:
				for other in extra_rivals:
					if other.spider == actor:
						best_node = other.node if other.progress < 0.5 else other.target
	if best_distance < INF:
		return best_node
	for bug in bugs:
		if not bug.active:
			continue
		var distance := hunter.spider.position.distance_to(bug.position)
		if distance < best_distance:
			best_distance = distance
			best_node = bug.route[bug.route_index]
	return best_node

func move_extra_rival(hunter: RivalHunter, delta: float) -> void:
	if hunter.repair_edge >= 0:
		hunter.rebuild_progress += delta / REBUILD_TIME
		hunter.spider.animate_walk(delta, false)
		if hunter.rebuild_progress >= 1.0:
			restore_edge(hunter.repair_edge, 3)
			hunter.repair_edge = -1
			hunter.rebuild_progress = 0.0
		return
	if rival_has_web_power() and hunter.build_charges > 0 and hunter.target == hunter.node:
		for neighbor in adjacency[hunter.node]:
			var link := edge_index(hunter.node, neighbor)
			if not edge_active[link]:
				hunter.build_charges -= 1
				hunter.repair_edge = link
				hunter.rebuild_progress = 0.0
				hunter.spider.animate_walk(delta, false)
				return
	if player_active and cloak_remaining <= 0.0 and not rival_can_eat_player(hunter.spider) and hunter.spider.position.distance_to(spider.position) < 650.0:
		if hunter.target != hunter.node and hunter.progress > 0.0 and web_points[hunter.target].distance_to(spider.position) < web_points[hunter.node].distance_to(spider.position):
			var previous := hunter.node
			hunter.node = hunter.target
			hunter.target = previous
			hunter.progress = 1.0 - hunter.progress
	if hunter.target == hunter.node:
		hunter.target = next_step_from(hunter.node, extra_rival_destination(hunter))
	if hunter.target == hunter.node or not edge_active[edge_index(hunter.node, hunter.target)]:
		hunter.target = hunter.node
		hunter.progress = 0.0
		hunter.spider.animate_walk(delta, false)
		return
	var before := hunter.spider.position
	var speed := rival_travel_speed(hunter.spider.speed, 1.3 if rival_can_eat_player(hunter.spider) and player_active else 1.0)
	var proposed_progress := minf(1.0, hunter.progress + speed * delta / web_length_between(hunter.node, hunter.target))
	var proposed := web_position(hunter.node, hunter.target, proposed_progress)
	if not hunt_bounds().has_point(proposed):
		return
	hunter.progress = proposed_progress
	hunter.spider.position = proposed
	hunter.spider.face_motion(proposed - before, delta)
	hunter.spider.animate_walk(delta, true)
	if hunter.progress >= 1.0:
		hunter.node = hunter.target
		hunter.progress = 0.0

func extra_rival_catch_bug(hunter: RivalHunter, bug: TrapBug) -> void:
	if bug == target_bug:
		cancel_auto_navigation()
	bug.catch()
	hunter.bugs_eaten += 1
	hunter.eating_remaining = bug.eat_duration
	if not rival_count_battle():
		hunter.power += 1
		var scale := rival_visual_scale_for_power(hunter.power) if rival_levels else solo_scale_for_power(hunter.power)
		hunter.spider.visual.scale = Vector2.ONE * scale
	spawn_catch_effect(hunter.spider.position, 2)
	update_status()
	update_threat_warning()

func defeat_rival_actor(victim: Spider, victor: Spider) -> void:
	victim.set_panic(0.0)
	panicking_rivals.erase(victim.get_instance_id())
	var victim_score := rival_caught_count
	var victim_hunter: RivalHunter
	if victim != rival:
		for hunter in extra_rivals:
			if hunter.spider == victim:
				victim_hunter = hunter
				victim_score = hunter.bugs_eaten
				break
	var gain := maxi(1, int(floor(float(victim_score) * 0.5)))
	if victor == rival:
		rival_caught_count += gain
		if not rival_count_battle():
			rival_power += gain
			rival.visual.scale = Vector2.ONE * (rival_visual_scale_for_power(rival_power) if rival_levels else solo_scale_for_power(rival_power))
	else:
		for hunter in extra_rivals:
			if hunter.spider == victor:
				hunter.bugs_eaten += gain
				if not rival_count_battle():
					hunter.power += gain
					hunter.spider.visual.scale = Vector2.ONE * (rival_visual_scale_for_power(hunter.power) if rival_levels else solo_scale_for_power(hunter.power))
				break
	if victim == rival:
		rival_active = false
		rival_respawn_remaining = 4.0 if rivals_can_respawn() else -1.0
		rival_caught_count = 0
		rival_eat_remaining = 0.0
		rival_eat_bug = null
		if is_instance_valid(rival_morsel):
			rival_morsel.queue_free()
		rival_morsel = null
		rival.finish_eating()
	else:
		victim_hunter.active = false
		victim_hunter.respawn_remaining = 4.0 if rivals_can_respawn() else -1.0
		victim_hunter.bugs_eaten = 0
		victim_hunter.eating_remaining = 0.0
	victim.set_health(0.0)
	victim.hide()
	warned_rivals.erase(victim.get_instance_id())
	spawn_catch_effect(victim.position, 2)
	instruction_label.text = "A rival with more bugs ate another rival!" if rival_count_battle() else "A bigger rival ate a smaller rival and grew!"
	update_status()
	update_threat_warning()
	check_round_complete()

func resolve_rival_duels() -> void:
	var actors := all_active_rivals()
	for i in actors.size():
		for j in range(i + 1, actors.size()):
			var first: Spider = actors[i]
			var second: Spider = actors[j]
			if first.position.distance_to(second.position) > SPIDER_SEPARATION + 18.0:
				continue
			if power_of_rival(first) > power_of_rival(second):
				defeat_rival_actor(second, first)
				return
			elif power_of_rival(second) > power_of_rival(first):
				defeat_rival_actor(first, second)
				return

func move_spider_on_web(delta: float) -> void:
	if player_new_link_progress >= 0.0:
		player_new_link_progress += delta / REBUILD_TIME
		spider.animate_walk(delta, false)
		queue_redraw()
		if player_new_link_progress >= 1.0:
			complete_player_new_link()
		return
	if player_repair_edge >= 0:
		player_rebuild_progress += delta / REBUILD_TIME
		spider.animate_walk(delta, false)
		queue_redraw()
		if player_rebuild_progress >= 1.0:
			var completed := player_repair_edge
			restore_edge(completed, 1)
			if selected_repair_edge == completed:
				selected_repair_edge = -1
		return
	if spider_retreating:
		var before := spider.position
		var next_progress := maxf(0.0, spider_progress - spider.speed * delta / web_length_between(spider_node, spider_target))
		var proposed := web_position(spider_node, spider_target, next_progress)
		if not spider_step_is_clear(spider, proposed):
			spider.animate_walk(delta, false)
			return
		spider_progress = next_progress
		spider.position = proposed
		spider.face_motion(spider.position - before, delta)
		spider.animate_walk(delta, true)
		if spider_progress <= 0.0:
			spider_target = spider_node
			spider_retreating = false
			auto_path.clear()
		return
	var auto_moving := target_bug != null or destination_node >= 0 or tap_destination_edge >= 0 or chase_rival or selected_repair_edge >= 0 or selected_new_link.x >= 0
	var planned_now := false
	if auto_moving and auto_path.is_empty():
		auto_path = plan_auto_path()
		planned_now = true
	if destination_node >= 0 and spider_node == destination_node and spider_target == spider_node:
		destination_node = -1
		auto_path.clear()
		if tap_destination_edge < 0:
			spider.animate_walk(delta, false)
			return
		auto_path = plan_auto_path()
	if auto_moving and auto_path.is_empty():
		spider.animate_walk(delta, false)
		instruction_label.text = "No Web charges. Watch an ad to repair the route." if build_charges <= 0 else "No route to that point."
		return
	var input_direction := spider.desired_direction
	if not auto_moving and input_direction.length() < 0.18:
		spider.animate_walk(delta, false)
		return
	if spider_target == spider_node:
		var next_node := spider_node
		if auto_moving:
			if auto_path.size() > 1:
				next_node = auto_path[1]
			elif selected_new_link.x >= 0:
				begin_player_new_link()
				return
			elif selected_repair_edge >= 0:
				begin_player_repair(selected_repair_edge)
				return
			elif target_bug != null:
				if target_bug.arriving:
					spider.animate_walk(delta, false)
					return
				var required_edge := -1 if bugs_mode else required_bug_repair_edge(target_bug)
				if required_edge >= 0:
					if not begin_player_repair(required_edge):
						instruction_label.text = "No Web charges. Watch an ad to repair the route." if build_charges <= 0 else "Move to the broken strand to repair it."
					return
				if spider.position.distance_to(target_bug.position) <= player_catch_radius():
					spider.animate_walk(delta, false)
					return
				var near_node: int = target_bug.route[target_bug.route_index]
				if target_bug.route_index < target_bug.route.size() - 1:
					var far_node: int = target_bug.route[target_bug.route_index + 1]
					next_node = far_node if spider_node == near_node else near_node
			elif chase_rival:
				spider.animate_walk(delta, false)
				return
		else:
			var best_score := 0.43
			for candidate in adjacency[spider_node]:
				var index := edge_index(spider_node, candidate)
				if not edge_active[index] and build_charges <= 0:
					continue
				var path_direction := (web_points[candidate] - web_points[spider_node]).normalized()
				var score := input_direction.normalized().dot(path_direction)
				if not edge_active[index]:
					score -= 0.08
				if score > best_score:
					best_score = score
					next_node = candidate
		if next_node != spider_node and not edge_active[edge_index(spider_node, next_node)]:
			if not begin_player_repair(edge_index(spider_node, next_node)):
				instruction_label.text = "No Web charges. Watch an ad to repair the route." if build_charges <= 0 else "Move to the broken strand to repair it."
			spider.animate_walk(delta, false)
			return
		if bugs_mode and target_bug != null and target_bug.active and next_node == target_bug.route[0] and target_bug.web_cut_remaining <= 0.0:
			var upcoming_edge := edge_index(spider_node, next_node)
			on_bug_web_cut_requested(target_bug)
			if not edge_active[upcoming_edge]:
				spider.animate_walk(delta, false)
				return
		spider_target = next_node
	if spider_target == spider_node:
		spider.animate_walk(delta, false)
		return
	if auto_moving and planned_now and auto_path.size() > 0 and auto_path[0] == spider_node and spider_progress > 0.0:
		var previous := spider_node
		spider_node = spider_target
		spider_target = previous
		spider_progress = 1.0 - spider_progress
		auto_path.clear()
	var from := web_points[spider_node]
	var to := web_points[spider_target]
	var along := (to - from).normalized()
	if not auto_moving and input_direction.normalized().dot(along) < -0.65:
		var previous := spider_node
		spider_node = spider_target
		spider_target = previous
		spider_progress = 1.0 - spider_progress
		from = web_points[spider_node]
		to = web_points[spider_target]
		along = (to - from).normalized()
	var before := spider.position
	var next_progress := minf(1.0, spider_progress + spider.speed * delta / web_length_between(spider_node, spider_target))
	var tapped_final_leg := destination_node < 0 and tap_destination_edge == edge_index(spider_node, spider_target)
	var tap_stop_progress := 1.0
	if tapped_final_leg:
		tap_stop_progress = tap_destination_progress if spider_node == web_edges[tap_destination_edge].x else 1.0 - tap_destination_progress
		next_progress = minf(next_progress, tap_stop_progress)
	var proposed := web_position(spider_node, spider_target, next_progress)
	if not spider_step_is_clear(spider, proposed):
		spider.animate_walk(delta, false)
		return
	spider_progress = next_progress
	spider.position = proposed
	spider.face_motion(spider.position - before, delta)
	spider.animate_walk(delta, true)
	if tapped_final_leg and spider_progress >= tap_stop_progress - 0.0001:
		tap_destination_edge = -1
		auto_path.clear()
	if spider_progress >= 1.0:
		var traveled_edge := edge_index(spider_node, spider_target)
		spider_node = spider_target
		spider_progress = 0.0
		auto_path.clear()
		if trail_cut_enabled and not bugs_mode and not rival_levels and cut_charges > 0:
			cut_edge(traveled_edge, 1)

func catch_bug_passed_on_way(from: Vector2, to: Vector2) -> void:
	if from.is_equal_approx(to):
		return
	var movement := to - from
	var first_bug: TrapBug
	var first_progress := INF
	for bug in bugs:
		if not bug.active:
			continue
		var bug_center: Vector2 = bug.position + bug.sprite.position
		var progress := clampf((bug_center - from).dot(movement) / movement.length_squared(), 0.0, 1.0)
		var nearest := from + movement * progress
		if bug_center.distance_to(nearest) <= player_catch_radius() and progress < first_progress:
			first_bug = bug
			first_progress = progress
	if first_bug != null:
		catch_bug(first_bug, 1)

func catch_bug(bug, team: int = 1) -> void:
	if finished or not bug.active or ((player_eat_remaining > 0.0 or player_rival_eat_remaining > 0.0) if team == 1 else rival_eat_remaining > 0.0):
		return
	var eater: Spider = spider if team == 1 else rival
	if bug == target_bug:
		cancel_auto_navigation()
	bug.catch()
	var morsel := Sprite2D.new()
	morsel.texture = bug.sprite.texture
	morsel.scale = bug.sprite.scale
	morsel.position = bug.position
	morsel.z_index = 12
	add_child(morsel)
	var bite := create_tween()
	bite.tween_property(morsel, "position", eater.position + Vector2.DOWN.rotated(eater.visual.rotation) * 22.0, 0.20).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	bite.parallel().tween_property(morsel, "scale", bug.sprite.scale * 0.58, 0.20)
	eater.start_eating()
	if team == 1:
		set_spider_walking_sound(false)
	play_sound(BUG_EATING_SOUND, -8.0)
	if team == 1:
		player_eat_bug = bug
		player_morsel = morsel
		player_eat_duration = bug.eat_duration
		player_eat_remaining = bug.eat_duration
	else:
		rival_eat_bug = bug
		rival_morsel = morsel
		rival_eat_duration = bug.eat_duration
		rival_eat_remaining = bug.eat_duration
	instruction_label.text = ("You are eating a bug..." if team == 1 else "The rival is eating a bug...")
	queue_redraw()

func finish_eating(team: int) -> void:
	var eater: Spider = spider if team == 1 else rival
	var morsel: Sprite2D = player_morsel if team == 1 else rival_morsel
	eater.finish_eating()
	if is_instance_valid(morsel):
		var vanish := create_tween()
		vanish.tween_property(morsel, "scale", Vector2.ZERO, 0.15)
		vanish.parallel().tween_property(morsel, "modulate:a", 0.0, 0.15)
		vanish.finished.connect(morsel.queue_free)
	spawn_catch_effect(eater.position, team)
	play_sound(BUG_DIED_SOUND, -7.0)
	if team == 1:
		caught_count += 1
		if bugs_mode:
			elapsed_seconds = maxf(0.0, elapsed_seconds - BUGS_MODE_CATCH_TIME_BONUS)
			game_hud.set_elapsed(maxf(0.0, ceilf(bugs_mode_time_limit() - elapsed_seconds)))
		if intro_mode and not bugs_mode and not rival_count_battle():
			player_power += 1
			var grown_size := rival_visual_scale_for_power(player_power) if rival_levels else solo_scale_for_power(player_power)
			spider.visual.scale = Vector2(grown_size, grown_size)
		player_eat_bug = null
		player_morsel = null
		player_eat_duration = 0.0
	else:
		rival_caught_count += 1
		if intro_mode and not bugs_mode and not rival_count_battle():
			rival_power += 1
			var rival_size := rival_visual_scale_for_power(rival_power) if rival_levels else solo_scale_for_power(rival_power)
			rival.visual.scale = Vector2(rival_size, rival_size)
		rival_eat_bug = null
		rival_morsel = null
		rival_eat_duration = 0.0
	instruction_label.text = "Caught %d / %d bugs. Keep hunting!" % [caught_count, bugs_mode_bug_count()] if bugs_mode else "+1 bug eaten! Keep hunting on the web."
	update_status()
	check_round_complete()
	queue_redraw()
	if team == 2 and intro_mode:
		update_threat_warning()

func clear_eating() -> void:
	if player_rival_eat_remaining > 0.0:
		spider.finish_eating()
	player_rival_eat_remaining = 0.0
	player_rival_victim = null
	player_rival_hunter = null
	player_rival_score = 0
	if is_instance_valid(player_rival_morsel):
		player_rival_morsel.queue_free()
	player_rival_morsel = null
	player_eat_remaining = 0.0
	rival_eat_remaining = 0.0
	player_eat_duration = 0.0
	rival_eat_duration = 0.0
	player_eat_bug = null
	rival_eat_bug = null
	if is_instance_valid(player_morsel):
		player_morsel.queue_free()
	if is_instance_valid(rival_morsel):
		rival_morsel.queue_free()
	player_morsel = null
	rival_morsel = null

func spawn_catch_effect(at: Vector2, team: int) -> void:
	var effect = CatchEffectScript.new()
	effect.position = at
	effect.z_index = 13
	effect.setup(team)
	add_child(effect)

func on_bug_escaped(_bug) -> void:
	if finished:
		return
	if _bug is TrapBug:
		_bug.stop_free_voice()
	if _bug == target_bug:
		cancel_auto_navigation()
	escaped_count += 1
	update_status()
	if bugs_mode:
		instruction_label.text = "%d bug%s escaped. Catch the rest!" % [escaped_count, "" if escaped_count == 1 else "s"]
		if _bug == escape_focus_bug:
			return_from_bug_escape()
			return
		check_round_complete()
		return
	check_round_complete()

func on_bug_broke_free(bug: TrapBug) -> void:
	if finished:
		return
	if bugs_mode:
		instruction_label.text = "A bug broke free and is flying away!"
		if bug.flies_away_on_release:
			start_bug_escape_focus(bug)
		return
	instruction_label.text = "A ladybug broke free and is flying away!" if bug.flies_away_on_release else ("A strong ladybug broke free! Catch it!" if bug.strong else "A ladybug escaped the glue!")

func check_round_complete() -> void:
	if player_rival_eat_remaining > 0.0:
		return
	if intro_mode:
		if bugs_mode:
			if caught_count + escaped_count >= bugs.size():
				winner = 1 if caught_count > 0 else 2
				if winner == 2:
					bugs_failure_reason = "All %d bugs flew away." % bugs_mode_bug_count()
				finish_match()
			return
		if rival_count_battle():
			if caught_count >= intro_goal() or all_active_rivals().is_empty():
				winner = 1
				finish_match()
			elif highest_rival_bug_count() >= intro_goal():
				winner = 2
				finish_match()
			return
		if caught_count >= intro_goal():
			winner = 1
			finish_match()
		return
	if caught_count + rival_caught_count + escaped_count >= bugs.size():
		finish_match()

func resolve_solo_collision() -> void:
	if not intro_mode or finished or not rival_active or player_rival_eat_remaining > 0.0:
		return
	if bugs_mode:
		start_player_eat_rival(rival)
		return
	if player_can_eat_rival(rival):
		start_player_eat_rival(rival)
	elif rival_can_eat_player(rival) and cloak_remaining <= 0.0:
		defeat_player_by_rival()

func resolve_player_rival_collision(actor: Spider) -> void:
	if actor == rival:
		resolve_solo_collision()
		return
	var hunter: RivalHunter
	for candidate in extra_rivals:
		if candidate.spider == actor:
			hunter = candidate
			break
	if hunter == null or not hunter.active or not player_active or player_rival_eat_remaining > 0.0:
		return
	if player_can_eat_rival(actor):
		start_player_eat_rival(actor, hunter)
	elif rival_can_eat_player(actor) and cloak_remaining <= 0.0:
		defeat_player_by_rival()

func start_player_eat_rival(victim: Spider, hunter: RivalHunter = null) -> void:
	player_rival_victim = victim
	player_rival_hunter = hunter
	player_rival_score = rival_caught_count if hunter == null else hunter.bugs_eaten
	player_rival_eat_remaining = RIVAL_EAT_DURATION
	cancel_auto_navigation()
	set_spider_walking_sound(false)
	var morsel := Sprite2D.new()
	morsel.texture = victim.visual.texture
	morsel.position = victim.position
	morsel.rotation = victim.visual.rotation
	morsel.scale = victim.visual.scale
	morsel.z_index = 12
	add_child(morsel)
	player_rival_morsel = morsel
	var bite := create_tween()
	bite.tween_property(morsel, "position", spider.position, RIVAL_EAT_DURATION * 0.82).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	bite.parallel().tween_property(morsel, "scale", Vector2.ZERO, RIVAL_EAT_DURATION * 0.82)
	bite.parallel().tween_property(morsel, "modulate:a", 0.0, RIVAL_EAT_DURATION * 0.82)
	spider.start_eating()
	play_sound(BUG_EATING_SOUND, -8.0)
	if hunter == null:
		rival_active = false
		chase_rival = false
		rival_eat_remaining = 0.0
		rival_eat_duration = 0.0
		rival_eat_bug = null
		if is_instance_valid(rival_morsel):
			rival_morsel.queue_free()
		rival_morsel = null
		rival.finish_eating()
	else:
		hunter.active = false
		hunter.eating_remaining = 0.0
		warned_rivals.erase(victim.get_instance_id())
	victim.set_health(0.0)
	victim.hide()
	instruction_label.text = "Eating rival..."
	queue_redraw()

func finish_player_eat_rival() -> void:
	if player_rival_victim == null:
		return
	var victim := player_rival_victim
	var hunter := player_rival_hunter
	var bonus := 0 if bugs_mode else int(floor(float(player_rival_score) * 0.5))
	spider.finish_eating()
	if is_instance_valid(player_rival_morsel):
		player_rival_morsel.queue_free()
	player_rival_morsel = null
	player_rival_victim = null
	player_rival_hunter = null
	player_rival_score = 0
	if hunter == null:
		rival_respawn_remaining = 4.0 if rivals_can_respawn() else -1.0
		rival_caught_count = 0
	else:
		hunter.respawn_remaining = 4.0 if rivals_can_respawn() else -1.0
		hunter.bugs_eaten = 0
	if not bugs_mode:
		caught_count += bonus
		if not rival_count_battle():
			player_power += maxi(1, bonus)
			var grown_size := rival_visual_scale_for_power(player_power) if rival_levels else solo_scale_for_power(player_power)
			spider.visual.scale = Vector2.ONE * grown_size
	award_coins(1, get_canvas_transform() * victim.position)
	spawn_catch_effect(spider.position, 1)
	play_player_ready_sound()
	instruction_label.text = "Rival defeated! Keep catching bugs." if bugs_mode else "Rival eaten! +%d bugs from its score." % bonus
	update_status()
	update_power_buttons()
	check_round_complete()
	queue_redraw()

func defeat_player_by_rival() -> void:
	if finished or not player_active:
		return
	spawn_catch_effect(spider.position, 2)
	player_active = false
	game_hud.set_health(0.0)
	spider.set_health(0.0)
	player_eat_remaining = 0.0
	player_eat_duration = 0.0
	player_eat_bug = null
	if is_instance_valid(player_morsel):
		player_morsel.queue_free()
	player_morsel = null
	spider.finish_eating()
	spider.hide()
	winner = 2
	finish_match()

func respawn_solo_rival() -> void:
	rival.set_panic(0.0)
	panicking_rivals.erase(rival.get_instance_id())
	if spider.position.distance_to(web_points[solo_rival_start_node()]) < SPIDER_SEPARATION * 2.0:
		rival_respawn_remaining = 1.0
		return
	rival_active = true
	rival_node = solo_rival_start_node()
	rival_target = rival_node
	rival_progress = 0.0
	rival.position = web_points[rival_node]
	rival_power = player_power
	rival_caught_count = 0
	rival_cut_charges = START_CUT_CHARGES if rival_has_web_power() else 0
	rival_build_charges = START_BUILD_CHARGES if rival_has_web_power() else 0
	rival_boost_charges = START_BOOST_CHARGES if rival_has_speed_power() else 0
	rival_stun_charges = START_STUN_CHARGES if rival_has_freeze_power() else 0
	rival_boost_remaining = 0.0
	rival_stun_remaining = 0.0
	rival_power_cooldown = 5.0
	rival.speed = base_rival_speed()
	rival.visual.scale = spider.visual.scale
	rival.visual.modulate = Color.WHITE
	rival.set_health(100.0)
	rival.show()
	warned_rivals.erase(rival.get_instance_id())
	instruction_label.text = "The rival returned from the top!"
	update_power_buttons()

func respawn_extra_rival(hunter: RivalHunter) -> void:
	hunter.spider.set_panic(0.0)
	panicking_rivals.erase(hunter.spider.get_instance_id())
	for actor in all_active_rivals():
		if actor.position.distance_to(web_points[hunter.home]) < SPIDER_SEPARATION * 2.0:
			hunter.respawn_remaining = 1.0
			return
	if player_active and spider.position.distance_to(web_points[hunter.home]) < SPIDER_SEPARATION * 2.0:
		hunter.respawn_remaining = 1.0
		return
	hunter.active = true
	hunter.node = hunter.home
	hunter.target = hunter.home
	hunter.progress = 0.0
	hunter.power = player_power
	hunter.bugs_eaten = 0
	hunter.eating_remaining = 0.0
	hunter.stun_remaining = 0.0
	hunter.cut_charges = START_CUT_CHARGES if rival_has_web_power() else 0
	hunter.build_charges = START_BUILD_CHARGES if rival_has_web_power() else 0
	hunter.boost_charges = START_BOOST_CHARGES if rival_has_speed_power() else 0
	hunter.stun_charges = START_STUN_CHARGES if rival_has_freeze_power() else 0
	hunter.boost_remaining = 0.0
	hunter.power_cooldown = 6.0
	hunter.repair_edge = -1
	hunter.rebuild_progress = 0.0
	hunter.spider.speed = hunter.base_speed
	hunter.spider.position = web_points[hunter.home]
	hunter.spider.visual.scale = Vector2.ONE * (rival_visual_scale_for_power(hunter.power) if rival_levels else solo_scale_for_power(hunter.power))
	hunter.spider.visual.modulate = Color.WHITE
	hunter.spider.set_health(100.0)
	hunter.spider.show()
	warned_rivals.erase(hunter.spider.get_instance_id())

func use_rival_ai_power() -> void:
	rival_power_cooldown = 7.0
	if not intro_mode or not rival_active or finished or threat_warning_active or rival_stun_remaining > 0.0:
		return
	var distance := rival.position.distance_to(spider.position)
	if rival_has_web_power() and cloak_remaining <= 0.0 and rival_cut_charges > 0 and distance < 650.0:
		var threatened_edge := edge_index(spider_node, spider_target) if spider_target != spider_node else -1
		if threatened_edge >= 0 and cut_edge(threatened_edge, 2):
			instruction_label.text = "The rival cut your web link!"
			return
	if rival_has_freeze_power() and cloak_remaining <= 0.0 and rival_stun_charges > 0 and distance < 520.0 and player_stun_remaining <= 0.0:
		rival_stun_charges -= 1
		player_stun_remaining = 2.0
		spider.visual.modulate = Color(0.65, 0.77, 1.0)
		show_freeze_effect(spider, player_stun_remaining)
		instruction_label.text = "The rival stopped your spider for two seconds!"
		return
	if rival_has_speed_power() and rival_boost_charges > 0 and distance > 250.0 and rival_boost_remaining <= 0.0:
		rival_boost_charges -= 1
		rival_boost_remaining = 3.0
		rival.speed = base_rival_speed() * 1.5
		instruction_label.text = "The rival is moving faster!"

func use_extra_rival_ai_power(hunter: RivalHunter) -> void:
	hunter.power_cooldown = 7.0
	if not hunter.active or finished or threat_warning_active or hunter.stun_remaining > 0.0:
		return
	var distance := hunter.spider.position.distance_to(spider.position)
	if rival_has_web_power() and cloak_remaining <= 0.0 and hunter.cut_charges > 0 and distance < 650.0:
		var threatened_edge := edge_index(spider_node, spider_target) if spider_target != spider_node else -1
		if threatened_edge >= 0 and cut_edge(threatened_edge, 3, hunter):
			instruction_label.text = "A rival cut your web link!"
			return
	if rival_has_freeze_power() and cloak_remaining <= 0.0 and hunter.stun_charges > 0 and distance < 520.0 and player_stun_remaining <= 0.0:
		hunter.stun_charges -= 1
		player_stun_remaining = 2.0
		spider.visual.modulate = Color(0.65, 0.77, 1.0)
		show_freeze_effect(spider, player_stun_remaining)
		instruction_label.text = "A rival froze your spider!"
		return
	if rival_has_speed_power() and hunter.boost_charges > 0 and distance > 250.0 and hunter.boost_remaining <= 0.0:
		hunter.boost_charges -= 1
		hunter.boost_remaining = 3.0
		hunter.spider.speed = hunter.base_speed * 1.5
		instruction_label.text = "A rival is moving faster!"

func bugs_mode_star_count() -> int:
	if caught_count >= bugs_mode_bug_count():
		return 3
	if caught_count == bugs_mode_bug_count() - 1:
		return 2
	return 1 if caught_count > 0 else 0

func bugs_mode_coin_reward() -> int:
	return 5 if caught_count > 0 else 0

func finish_match() -> void:
	if finished:
		return
	finished = true
	for actor in all_active_rivals():
		actor.set_panic(0.0)
	panicking_rivals.clear()
	rival_panic_audio.stop()
	player_panicking = false
	spider.set_panic(0.0)
	player_panic_audio.stop()
	set_rival_walking_sound(false)
	if ready_audio_tween != null and ready_audio_tween.is_running():
		ready_audio_tween.kill()
	if is_instance_valid(rival_ready_audio):
		rival_ready_audio.stop()
	if intro_mode and winner == 1:
		get_node("/root/GameManager").notify_level_completed(intro_level, caught_count)
	spider.desired_direction = Vector2.ZERO
	if not intro_mode:
		winner = 1 if caught_count > rival_caught_count else (2 if rival_caught_count > caught_count else 0)
	for bug in bugs:
		bug.set_process(false)
		bug.stop_bug_sounds()
		if intro_mode and (bug.active or bug.arriving):
			bug.hide()
	instruction_label.text = ("You caught %d of %d bugs!" % [caught_count, bugs_mode_bug_count()] if winner == 1 else bugs_failure_reason) if bugs_mode else (("You won the bug-count battle!" if winner == 1 else "A rival won the bug-count battle!") if rival_count_battle() else (("You reached the bug goal!" if winner == 1 else "The bigger rival caught your spider. Try again!") if intro_mode else "The spider with the most catches wins."))
	show_result_popup(winner == 1)
	if winner == 1:
		award_coins(5, Vector2(-1.0, -1.0), 0.65)
		play_sound(LEVEL_COMPLETE_SOUND, -3.0)
	else:
		play_sound(LEVEL_FAIL_SOUND, -3.0)
	get_node("/root/AdsManager").show_banner()
	result_ad_serial += 1
	show_result_interstitial_after_reveal(result_ad_serial)

func show_result_interstitial_after_reveal(serial: int) -> void:
	await get_tree().create_timer(2.5).timeout
	var ads := get_node("/root/AdsManager")
	for attempt in 17:
		if not is_inside_tree() or not finished or serial != result_ad_serial or not result_panel.visible:
			return
		if ads.is_interstitial_ready():
			ads.show_result_interstitial()
			return
		if ads.plugin == null or get_node("/root/BillingManager").remove_ads_owned:
			return
		if attempt < 16:
			await get_tree().create_timer(0.5).timeout

func show_result_popup(success: bool) -> void:
	if result_tween != null and result_tween.is_running():
		result_tween.kill()
	for star_tween in star_reveal_tweens:
		if star_tween.is_running():
			star_tween.kill()
	star_reveal_tweens.clear()
	result_panel.texture = RESULT_VICTORY if success else RESULT_FAILURE
	result_level.text = "LEVEL %d" % intro_level if intro_mode else "THE WEB TRAP"
	result_title.text = ("LEVEL COMPLETE!" if success else ("LEVEL FAILED" if bugs_mode else "GAME OVER")) if intro_mode else ("YOU WIN!" if success else ("LEVEL FAILED" if winner == 2 else "DRAW!"))
	result_title.add_theme_color_override("font_color", Color(0.23, 0.34, 0.11) if success else Color(0.56, 0.13, 0.08))
	result_reward.text = "+5 COINS" if success else "NO COINS"
	result_note.text = ("Caught: %d / %d  Escaped: %d" % [caught_count, bugs_mode_bug_count(), escaped_count]) if bugs_mode else (("You: %d  Top rival: %d  Goal: %d" % [caught_count, highest_rival_bug_count(), intro_goal()]) if rival_count_battle() else (("Bug count: %d / %d" % [caught_count, intro_goal()]) if intro_mode else "You: %d   Rival: %d   Escaped: %d" % [caught_count, rival_caught_count, escaped_count]))
	update_result_reward_ad_button()
	var earned_stars := bugs_mode_star_count() if bugs_mode else (3 if success else 0)
	for index in result_stars.get_child_count():
		var star := result_stars.get_child(index).get_child(0)
		star.modulate = Color(1.0, 1.0, 1.0, 0.0) if index < earned_stars else Color(0.24, 0.24, 0.24, 0.28)
		star.scale = Vector2.ZERO if index < earned_stars else Vector2.ONE
		if index < earned_stars:
			var star_tween := create_tween()
			star_tween.tween_interval(0.38 + float(index) * 0.18)
			if index == 0:
				star_tween.tween_callback(play_sound.bind(STAR_SOUND, -4.0))
			star_tween.tween_property(star, "scale", Vector2.ONE, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			star_tween.parallel().tween_property(star, "modulate:a", 1.0, 0.25)
			star_reveal_tweens.append(star_tween)
	retry_button.visible = true
	if intro_mode:
		next_button.visible = success
	var three_actions := intro_mode and next_button.visible
	retry_button.position = Vector2(185, 870) if three_actions else Vector2(285, 870)
	result_menu_button.position = Vector2(565, 870) if three_actions else Vector2(465, 870)
	result_dimmer.visible = true
	result_dimmer.modulate.a = 0.0
	result_panel.visible = true
	result_panel.modulate.a = 0.0
	result_panel.scale = Vector2(0.42, 0.42)
	result_panel.rotation = deg_to_rad(-3.0)
	result_tween = create_tween().set_parallel(true)
	result_tween.tween_property(result_dimmer, "modulate:a", 1.0, 0.24)
	result_tween.tween_property(result_panel, "modulate:a", 1.0, 0.26)
	result_tween.tween_property(result_panel, "scale", Vector2.ONE * 0.8, 0.48).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	result_tween.tween_property(result_panel, "rotation", 0.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func hide_result_popup() -> void:
	if result_tween != null and result_tween.is_running():
		result_tween.kill()
	result_panel.hide()
	result_dimmer.hide()

func update_status() -> void:
	status_label.text = "%d:%d" % [caught_count, highest_rival_bug_count()] if rival_count_battle() else "%d/%d" % [caught_count, intro_goal() if intro_mode else BUG_COUNT]
	if rival_levels:
		update_spider_bug_label(spider, caught_count, Color(0.45, 0.88, 1.0))
		update_spider_bug_label(rival, rival_caught_count, Color(1.0, 0.48, 0.37))
		for hunter in extra_rivals:
			update_spider_bug_label(hunter.spider, hunter.bugs_eaten, Color(1.0, 0.58, 0.42))
		var rival_leads := highest_rival_bug_count() > caught_count
		if rival_leads and not rival_bug_lead_announced:
			play_rival_ready_sound()
		elif not rival_leads and is_instance_valid(rival_ready_audio):
			rival_ready_audio.stop()
		rival_bug_lead_announced = rival_leads

func highest_rival_bug_count() -> int:
	var best := rival_caught_count if rival_active else 0
	for hunter in extra_rivals:
		if hunter.active:
			best = maxi(best, hunter.bugs_eaten)
	return best

func update_spider_bug_label(actor: Spider, count: int, color: Color) -> void:
	var label := actor.get_node_or_null("BugCountLabel") as Label
	if label == null:
		label = Label.new()
		label.name = "BugCountLabel"
		label.position = Vector2(-90.0, -155.0)
		label.size = Vector2(180.0, 65.0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font", GameFont.title_font())
		label.add_theme_font_size_override("font_size", 52)
		label.add_theme_color_override("font_color", color)
		label.add_theme_color_override("font_outline_color", Color(0.01, 0.03, 0.04))
		label.add_theme_constant_override("outline_size", 8)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.z_index = 30
		actor.add_child(label)
	label.text = "%d" % count

func set_spider_walking_sound(moving: bool) -> void:
	if not is_instance_valid(walking_audio):
		return
	var settings := get_node_or_null("/root/AppSettings")
	if not moving or (settings != null and not settings.sfx_enabled):
		if walking_audio.playing:
			walking_audio.stop()
	elif not walking_audio.playing:
		walking_audio.play()

func set_rival_walking_sound(moving: bool) -> void:
	if not is_instance_valid(rival_walking_audio):
		return
	var settings := get_node_or_null("/root/AppSettings")
	if not moving or (settings != null and not settings.sfx_enabled):
		if rival_walking_audio.playing:
			rival_walking_audio.stop()
	elif not rival_walking_audio.playing:
		rival_walking_audio.play()

func play_ready_audio(audio: AudioStreamPlayer) -> void:
	if not is_instance_valid(audio) or finished:
		return
	var settings := get_node_or_null("/root/AppSettings")
	if settings != null and not settings.sfx_enabled:
		return
	audio.play()

func play_player_ready_sound() -> void:
	play_ready_audio(player_ready_audio)

func play_rival_ready_sound() -> void:
	if not rival_levels or highest_rival_bug_count() <= caught_count:
		return
	play_ready_audio(rival_ready_audio)

func play_sound(stream: AudioStream, volume_db := -12.0) -> void:
	var settings := get_node_or_null("/root/AppSettings")
	if settings != null and not settings.sfx_enabled:
		return
	var audio := AudioStreamPlayer.new()
	audio.stream = stream
	audio.volume_db = volume_db
	add_child(audio)
	audio.play()
	audio.finished.connect(audio.queue_free)

func strand_curve_point(from: Vector2, to: Vector2, index: int, kind: int, t: float) -> Vector2:
	var direction := to - from
	var sideways := Vector2(-direction.y, direction.x).normalized()
	var bend := 3.0 if kind == 1 else (7.0 if kind == 0 else 5.0)
	var variation := sin(float(index * 19 + 7) * 0.61)
	var sway := bend * variation
	var fiber := sin(t * PI) * sway
	fiber += sin(t * TAU * 2.0 + float(index) * 0.9) * 1.5 * sin(t * PI)
	return from.lerp(to, t) + sideways * fiber

func strand_points(from: Vector2, to: Vector2, index: int, kind: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for step in 13:
		var t := float(step) / 12.0
		points.append(strand_curve_point(from, to, index, kind, t))
	return points

func draw_tapered_strand(points: PackedVector2Array, kind: int, ring_number: int) -> void:
	var fine_width := 1.15
	var knot_width := 7.8
	var silk_color := Color(0.89, 0.97, 0.88, 0.84)
	if kind == 1:
		fine_width = 2.0 + float(ring_number) * 0.05
		knot_width = 10.0 + float(ring_number) * 0.37
		silk_color = Color(0.84, 0.97, 0.91, 0.95)
	elif kind == 2:
		fine_width = 1.65
		knot_width = 9.0
	for part in points.size() - 1:
		var t := (float(part) + 0.5) / float(points.size() - 1)
		var taper := pow(absf(t * 2.0 - 1.0), 2.25)
		var width := lerpf(fine_width, knot_width, taper)
		draw_line(points[part], points[part + 1], Color(0.10, 0.27, 0.30, 0.38), width + 2.3, true)
		draw_line(points[part], points[part + 1], silk_color, width, true)
		draw_line(points[part], points[part + 1], Color(1.0, 1.0, 0.98, 0.36), 0.8, true)

func _draw() -> void:
	if intro_mode and not bugs_mode:
		draw_rect(hunt_bounds(), Color(0.48, 0.92, 1.0, 0.68), false, 6.0, true)
	var outer := PackedVector2Array()
	if not intro_mode:
		for i in 12:
			outer.append(web_points[85 + i])
		draw_colored_polygon(outer, Color(0.24, 0.65, 0.92, 0.035 * web_progress))
	if not intro_mode and web_progress > 0.45:
		var hub_alpha := clampf((web_progress - 0.45) * 1.8, 0.0, 1.0)
		draw_circle(WEB_CENTER, 61.0, Color(0.87, 0.97, 0.92, 0.07 * hub_alpha))
		for radius in [18.0, 28.0, 39.0, 52.0]:
			draw_arc(WEB_CENTER, radius, 0.0, TAU, 44, Color(0.89, 0.97, 0.91, 0.64 * hub_alpha), 1.5, true)
	var visible_edges := web_progress * float(web_edges.size())
	for i in web_edges.size():
		var fraction := clampf(visible_edges - float(i), 0.0, 1.0)
		if fraction <= 0.0:
			continue
		var edge := web_edges[i]
		var from := web_points[edge.x]
		var radial := edge_kind[i] == 1
		var ring_number := int((maxi(edge.x, edge.y) - 1) / 12)
		var silk_width := 1.35 if edge_kind[i] == 0 else (1.5 + float(ring_number) * 0.34 if radial else 2.2)
		if not edge_active[i]:
			var to_broken := web_points[edge.y]
			var direction := (to_broken - from).normalized()
			var gap := from.distance_to(to_broken)
			var stub := minf(30.0, gap * 0.22)
			draw_line(from, from + direction * stub, Color(0.87, 0.89, 0.77, 0.86), silk_width + 0.8, true)
			draw_line(to_broken, to_broken - direction * stub, Color(0.87, 0.89, 0.77, 0.86), silk_width + 0.8, true)
			if rival_repair_edge == i:
				var rebuild_from := web_points[rival_node]
				var rebuild_to := to_broken if rival_node == edge.x else from
				draw_line(rebuild_from, rebuild_from.lerp(rebuild_to, rival_rebuild_progress), Color(1.0, 0.69, 0.63, 0.96), silk_width + 1.0, true)
			if player_repair_edge == i:
				var rebuild_from := web_points[spider_node]
				var rebuild_to := to_broken if spider_node == edge.x else from
				draw_line(rebuild_from, rebuild_from.lerp(rebuild_to, player_rebuild_progress), Color(0.51, 0.86, 1.0, 0.98), silk_width + 2.0, true)
			continue
		var to := from.lerp(web_points[edge.y], fraction)
		var thread := strand_points(from, to, i, edge_kind[i])
		draw_tapered_strand(thread, edge_kind[i], ring_number)
		if building and fraction < 1.0:
			draw_line(WEB_CENTER, to, Color(0.90, 0.99, 1.0, 0.55), 2.0, true)
	if player_new_link_progress >= 0.0 and selected_new_link.x >= 0:
		var new_from := web_points[selected_new_link.x]
		var new_to := web_points[selected_new_link.y]
		var woven_to := new_from.lerp(new_to, minf(1.0, player_new_link_progress))
		draw_line(new_from, woven_to, Color(0.48, 0.88, 1.0, 0.95), 5.0, true)
	if bugs_mode and weave_mode and spider_target == spider_node:
		for available_edge in bugs_available_repair_edges:
			var link: Vector2i = web_edges[available_edge]
			var far_node: int = link.y if link.x == spider_node else link.x
			draw_line(web_points[spider_node], web_points[far_node], Color(0.38, 0.89, 1.0, 0.55), 4.0, true)
			draw_arc(web_points[far_node], 18.0, 0.0, TAU, 24, Color(0.42, 0.94, 1.0, 0.95), 3.0, true)
		for available_node in bugs_available_new_targets:
			draw_line(web_points[spider_node], web_points[available_node], Color(0.53, 1.0, 0.68, 0.38), 2.5, true)
			draw_arc(web_points[available_node], 16.0, 0.0, TAU, 24, Color(0.57, 1.0, 0.72, 0.86), 2.5, true)
	if weave_start_node >= 0:
		draw_arc(web_points[weave_start_node], 20.0, 0.0, TAU, 24, Color(0.38, 0.85, 1.0, 0.95), 4.0, true)
	if web_progress >= 0.99:
		for i in web_points.size():
			var knot_size := 7.0 if i == 0 else 3.6 + float(i - 1) / 12.0 * 0.43
			draw_circle(web_points[i], knot_size + 2.0, Color(0.10, 0.28, 0.30, 0.32))
			draw_circle(web_points[i], knot_size, Color(0.86, 0.96, 0.86, 0.91))
			draw_circle(web_points[i] + Vector2(-1.0, -1.0), maxf(1.0, knot_size * 0.32), Color(1.0, 1.0, 0.98, 0.74))
		for i in [4, 9, 15, 23, 28, 35, 42, 47, 55, 62, 71, 79, 86, 94]:
			if i >= web_points.size():
				continue
			var drop := web_points[i]
			draw_circle(drop + Vector2(4, 5), 5.0, Color(0.59, 0.82, 0.91, 0.53))
			draw_circle(drop + Vector2(3, 3), 1.8, Color(1.0, 1.0, 1.0, 0.78))
	if bugs_mode and camera_zoom < 0.95:
		for bug in bugs:
			if bug.active:
				var marker_color := Color(0.44, 0.85, 1.0) if bug.species_id == 0 else (Color(1.0, 0.36, 0.31) if bug.species_id == 1 else Color(1.0, 0.82, 0.28))
				draw_arc(bug.position, 45.0 / camera_zoom, 0.0, TAU, 32, marker_color, 3.5 / camera_zoom, true)
	if player_eat_remaining > 0.0:
		draw_eating_progress(spider.position, player_eat_remaining, player_eat_duration, Color(0.27, 0.75, 1.0))
	if player_rival_eat_remaining > 0.0:
		draw_eating_progress(spider.position, player_rival_eat_remaining, RIVAL_EAT_DURATION, Color(1.0, 0.78, 0.28))
	if rival_eat_remaining > 0.0:
		draw_eating_progress(rival.position, rival_eat_remaining, rival_eat_duration, Color(1.0, 0.33, 0.30))

func draw_eating_progress(at: Vector2, remaining: float, duration: float, color: Color) -> void:
	var completion := 1.0 - remaining / maxf(duration, 0.01)
	draw_arc(at, 56.0, -PI / 2.0, -PI / 2.0 + TAU, 32, Color(0.05, 0.14, 0.18, 0.7), 6.0, true)
	draw_arc(at, 56.0, -PI / 2.0, -PI / 2.0 + TAU * completion, 32, color, 6.0, true)
