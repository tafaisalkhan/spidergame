extends Node2D

const SpiderScript = preload("res://scripts/spider.gd")
const BugScript = preload("res://scripts/bug.gd")
const JoystickScript = preload("res://scripts/joystick.gd")
const WebGraphScript = preload("res://scripts/web_graph.gd")
const EnemyAIScript = preload("res://scripts/enemy_ai.gd")
const SoundScript = preload("res://scripts/sound.gd")
const CatchEffectScript = preload("res://scripts/catch_effect.gd")
const ATLAS = preload("res://assets/player/spider_atlas.png")
const GameFont = preload("res://scripts/ui/GameFont.gd")
const GARDEN = preload("res://assets/background/garden.png")
const RED_SPIDER = preload("res://assets/rival/red_spider.png")
const ROCK = preload("res://assets/background_items/mossy_rock.png")
const HOME_COST := 30
const HOME_POSITION := Vector2(555, 850)
const PLAY_BOUNDS := Rect2(75, 255, 930, 1320)

var level := 1
var step := 0
var player: Spider
var bugs: Array[GardenBug] = []
var silk := 0
var bugs_caught := 0
var moved_distance := 0.0
var nest_built := false
var constructing := false
var home_sprite: Sprite2D
var home_ring := 0.0
var background: Sprite2D
var ui: CanvasLayer
var joystick: SpiderJoystick
var title_label: Label
var instruction_label: Label
var stat_label: Label
var progress_label: Label
var build_button: Button
var victory_panel: PanelContainer
var next_button: Button
var victory_title: Label
var victory_note: Label
var pulse := 0.0
var last_popup := 0.0
var graph: WebGraph
var homes: Array[Dictionary] = []
var web_mode := false
var web_pointer := -2
var web_start := -1
var web_end := Vector2.ZERO
var build_web_button: Button
var repair_button: Button
var repaired := false
var damage_triggered := false
var repair_mode := false
var home_production_timer := 0.0
var level_completed := false
var enemy: Spider
var enemy_ai: EnemySpiderAI
var red_graph: WebGraph
var red_nest: Sprite2D
var cinematic_red: Sprite2D
var hold_time := 0.0
var obstacles: Array[Dictionary] = []
var obstacle_nodes: Array[StaticBody2D] = []
var catch_sound: AudioStreamWAV
var build_sound: AudioStreamWAV
var win_sound: AudioStreamWAV

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0 and args[0].is_valid_int():
		level = clampi(int(args[0]), 1, 4)
	build_scene()
	start_level()

func atlas_region(rect: Rect2) -> AtlasTexture:
	var tex := AtlasTexture.new()
	tex.atlas = ATLAS
	tex.region = rect
	return tex

func build_scene() -> void:
	catch_sound = SoundScript.make_chime(700.0, 0.15)
	build_sound = SoundScript.make_chime(480.0, 0.32)
	win_sound = SoundScript.make_chime(880.0, 0.65)
	background = Sprite2D.new()
	background.texture = GARDEN
	background.position = Vector2(540, 960)
	background.scale = Vector2(1080.0 / GARDEN.get_width(), 1920.0 / GARDEN.get_height())
	background.z_index = -10
	add_child(background)

	player = SpiderScript.new()
	player.name = "BlueSpider"
	player.position = Vector2(280, 1240)
	player.bounds = PLAY_BOUNDS
	player.setup(atlas_region(Rect2(12, 4, 565, 410)), 1)
	player.moved.connect(on_player_moved)
	add_child(player)

	home_sprite = Sprite2D.new()
	home_sprite.texture = atlas_region(Rect2(476, 750, 505, 520))
	home_sprite.position = HOME_POSITION
	home_sprite.scale = Vector2(0.34, 0.34)
	home_sprite.visible = false
	home_sprite.z_index = -1
	add_child(home_sprite)

	ui = CanvasLayer.new()
	add_child(ui)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(root)

	var header := PanelContainer.new()
	header.position = Vector2(32, 30)
	header.size = Vector2(1016, 190)
	header.modulate = Color(0.94, 1.0, 1.0, 0.94)
	root.add_child(header)
	var header_box := VBoxContainer.new()
	header_box.add_theme_constant_override("separation", 4)
	header.add_child(header_box)
	title_label = make_label("A NEW BEGINNING", 40, Color(0.08, 0.24, 0.32))
	header_box.add_child(title_label)
	stat_label = make_label("Silk  0 / 30", 30, Color(0.13, 0.42, 0.73))
	header_box.add_child(stat_label)
	progress_label = make_label("Bugs Collected: 0/3", 26, Color(0.18, 0.33, 0.34))
	header_box.add_child(progress_label)

	var instruction_panel := PanelContainer.new()
	instruction_panel.position = Vector2(54, 220)
	instruction_panel.size = Vector2(972, 108)
	root.add_child(instruction_panel)
	instruction_label = make_label("Welcome, Little Spider!", 32, Color(0.07, 0.27, 0.30))
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	instruction_panel.add_child(instruction_label)

	joystick = JoystickScript.new()
	joystick.position = Vector2(65, 1580)
	joystick.direction_changed.connect(func(value: Vector2) -> void: player.desired_direction = value)
	root.add_child(joystick)

	build_button = Button.new()
	build_button.text = "BUILD HOME\n30 SILK"
	build_button.position = Vector2(770, 1660)
	build_button.size = Vector2(260, 130)
	build_button.add_theme_font_size_override("font_size", 29)
	build_button.add_theme_font_override("font", GameFont.display_font())
	build_button.pressed.connect(begin_nest)
	build_button.visible = false
	root.add_child(build_button)
	build_web_button = Button.new()
	build_web_button.text = "BUILD WEB"
	build_web_button.position = Vector2(736, 1640)
	build_web_button.size = Vector2(295, 105)
	build_web_button.add_theme_font_size_override("font_size", 30)
	build_web_button.add_theme_font_override("font", GameFont.display_font())
	build_web_button.pressed.connect(toggle_web_mode)
	build_web_button.visible = false
	root.add_child(build_web_button)
	repair_button = Button.new()
	repair_button.text = "REPAIR WEB\n10 SILK"
	repair_button.position = Vector2(730, 1750)
	repair_button.size = Vector2(305, 110)
	repair_button.add_theme_font_size_override("font_size", 26)
	repair_button.add_theme_font_override("font", GameFont.display_font())
	repair_button.pressed.connect(begin_repair_selection)
	repair_button.visible = false
	root.add_child(repair_button)

	victory_panel = PanelContainer.new()
	victory_panel.position = Vector2(105, 675)
	victory_panel.size = Vector2(870, 500)
	victory_panel.visible = false
	root.add_child(victory_panel)
	var victory_box := VBoxContainer.new()
	victory_box.alignment = BoxContainer.ALIGNMENT_CENTER
	victory_box.add_theme_constant_override("separation", 28)
	victory_panel.add_child(victory_box)
	victory_title = make_label("HOME SWEET HOME!", 52, Color(0.08, 0.42, 0.73))
	victory_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_box.add_child(victory_title)
	var stars := make_label("★  ★  ★", 70, Color(0.96, 0.72, 0.13))
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_box.add_child(stars)
	victory_note = make_label("Your garden home is ready!", 31, Color(0.18, 0.34, 0.28))
	victory_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_box.add_child(victory_note)
	next_button = Button.new()
	next_button.text = "NEXT LEVEL"
	next_button.custom_minimum_size = Vector2(400, 100)
	next_button.add_theme_font_size_override("font_size", 34)
	next_button.add_theme_font_override("font", GameFont.display_font())
	next_button.pressed.connect(next_level)
	victory_box.add_child(next_button)

func make_label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font", GameFont.display_font())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func start_level() -> void:
	step = 0
	silk = 0
	bugs_caught = 0
	moved_distance = 0.0
	nest_built = false
	constructing = false
	level_completed = false
	hold_time = 0.0
	if is_instance_valid(enemy_ai):
		enemy_ai.queue_free()
		enemy_ai = null
	if is_instance_valid(enemy):
		enemy.queue_free()
		enemy = null
	if is_instance_valid(red_nest):
		red_nest.queue_free()
		red_nest = null
	if is_instance_valid(cinematic_red):
		cinematic_red.queue_free()
		cinematic_red = null
	for body in obstacle_nodes:
		body.queue_free()
	obstacle_nodes.clear()
	obstacles.clear()
	web_mode = false
	web_pointer = -2
	web_start = -1
	repaired = false
	damage_triggered = false
	repair_mode = false
	home_production_timer = 0.0
	homes.clear()
	graph = WebGraphScript.new()
	home_ring = 0.0
	home_sprite.visible = false
	home_sprite.position = HOME_POSITION
	home_sprite.scale = Vector2(0.34, 0.34)
	victory_panel.visible = false
	victory_title.text = "HOME SWEET HOME!"
	victory_note.text = "Your garden home is ready!"
	player.position = Vector2(280, 1240)
	player.desired_direction = Vector2.ZERO
	build_web_button.visible = level >= 2
	build_web_button.text = "BUILD WEB"
	repair_button.visible = false
	next_button.text = "REPLAY LEVEL" if level == 4 else "NEXT LEVEL"
	for bug in bugs:
		bug.queue_free()
	bugs.clear()
	if level == 1:
		title_label.text = "LEVEL 1  ·  A NEW BEGINNING"
		instruction_label.text = "Welcome, Little Spider!"
		spawn_bug(Vector2(455, 1130), 101)
		spawn_bug(Vector2(710, 1070), 102)
		spawn_bug(Vector2(710, 625), 103)
		await get_tree().create_timer(1.7).timeout
		if is_inside_tree() and step == 0:
			instruction_label.text = "Catch bugs and build your first home!"
			await get_tree().create_timer(2.0).timeout
			if is_inside_tree() and step == 0:
				instruction_label.text = "Drag the joystick to move your spider."
	else:
		setup_web_level()
		spawn_bug(Vector2(455, 1130), 101)
		spawn_bug(Vector2(710, 1070), 102)
		spawn_bug(Vector2(710, 625), 103)
		spawn_bug(Vector2(275, 935), 104, "Ladybug", 15)
		spawn_bug(Vector2(925, 945), 105, "Butterfly", 20)
		if level == 4:
			setup_enemy()
	setup_obstacles()
	update_hud()
	queue_redraw()

func spawn_bug(at: Vector2, seed_value: int, kind := "Fly", reward := 10) -> void:
	var bug: GardenBug = BugScript.new()
	bug.position = at
	var region := Rect2(5, 420, 380, 335)
	if kind == "Ladybug":
		region = Rect2(425, 485, 350, 270)
	elif kind == "Butterfly":
		region = Rect2(855, 395, 365, 370)
	bug.setup(atlas_region(region), kind, reward, seed_value)
	bug.caught.connect(on_bug_caught)
	add_child(bug)
	bugs.append(bug)

func _process(delta: float) -> void:
	pulse += delta
	if not victory_panel.visible:
		var keyboard := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		if keyboard.length() > 0.1:
			player.desired_direction = keyboard
		elif joystick.pointer_id == -2:
			player.desired_direction = Vector2.ZERO
		for bug in bugs:
			bug.try_catch(player)
		if level >= 2:
			update_homes(delta)
			check_web_level_completion()
		if level == 4 and is_instance_valid(enemy):
			for bug in bugs:
				bug.try_catch(enemy)
		if level == 1 and step == 2 and not constructing and player.position.distance_to(HOME_POSITION) < 125.0:
			build_button.visible = true
			instruction_label.text = "Tap BUILD HOME to make your nest!"
		elif not constructing:
			build_button.visible = false
		if level == 1 and (step == 2 or constructing):
			queue_redraw()

func on_player_moved(distance: float) -> void:
	if level != 1 or step != 0:
		return
	moved_distance += distance
	if moved_distance >= 120.0:
		step = 1
		instruction_label.text = "Catch three flies to gather silk!"
		update_hud()

func on_bug_caught(bug: GardenBug, team: int) -> void:
	if team == 2 and level == 4 and is_instance_valid(enemy_ai):
		show_bug_catch(bug, enemy, 2)
		enemy_ai.silk += bug.reward
		show_popup("+%d Silk" % bug.reward, bug.position)
		get_tree().create_timer(3.0).timeout.connect(func() -> void:
			if is_instance_valid(bug): bug.respawn())
		return
	if team != 1 or (level == 1 and step == 0) or constructing:
		bug.respawn()
		return
	show_bug_catch(bug, player, 1)
	silk += bug.reward
	bugs_caught += 1
	play_sound(catch_sound)
	show_popup("+%d Silk" % bug.reward, bug.position)
	update_hud()
	if level >= 2:
		instruction_label.text = "Build webs and claim abandoned homes."
	if level == 1 and step == 1 and bugs_caught >= 3:
		step = 2
		instruction_label.text = "Find a place to build your home."
		queue_redraw()
	elif level == 1 and step == 1:
		instruction_label.text = "Great catch! Find another fly."
	if level >= 2 or silk < HOME_COST:
		get_tree().create_timer(3.0).timeout.connect(func() -> void:
			if is_instance_valid(bug): bug.respawn())

func show_bug_catch(bug: GardenBug, eater: Spider, team: int) -> void:
	eater.play_catch()
	var effect = CatchEffectScript.new()
	effect.position = bug.position
	effect.z_index = 13
	effect.setup(team)
	add_child(effect)
	var morsel := Sprite2D.new()
	morsel.texture = bug.sprite.texture
	morsel.scale = bug.sprite.scale
	morsel.position = bug.position
	morsel.z_index = 12
	add_child(morsel)
	var bite := create_tween()
	bite.tween_property(morsel, "position", eater.position, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	bite.parallel().tween_property(morsel, "scale", Vector2.ZERO, 0.22)
	bite.parallel().tween_property(morsel, "modulate:a", 0.0, 0.22)
	bite.finished.connect(morsel.queue_free)

func show_popup(message: String, at: Vector2) -> void:
	var label := make_label(message, 32, Color(0.95, 0.99, 1.0))
	label.position = at + Vector2(-55, -90)
	label.z_index = 10
	add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "position:y", label.position.y - 65.0, 0.8)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
	tween.finished.connect(label.queue_free)

func begin_nest() -> void:
	if step != 2 or constructing or player.position.distance_to(HOME_POSITION) >= 125.0:
		return
	if silk < HOME_COST:
		instruction_label.text = "Catch more bugs to gather silk."
		return
	silk -= HOME_COST
	constructing = true
	play_sound(build_sound)
	build_button.visible = false
	player.desired_direction = Vector2.ZERO
	instruction_label.text = "Weaving your first home..."
	home_sprite.visible = true
	home_sprite.modulate.a = 0.0
	update_hud()
	var tween := create_tween()
	tween.tween_property(self, "home_ring", 1.0, 3.0)
	tween.parallel().tween_property(home_sprite, "modulate:a", 1.0, 3.0)
	tween.finished.connect(finish_nest)

func finish_nest() -> void:
	nest_built = true
	play_sound(win_sound)
	constructing = false
	step = 3
	instruction_label.text = "HOME SWEET HOME!"
	player.desired_direction = Vector2.ZERO
	victory_panel.visible = true
	var save := ConfigFile.new()
	save.load("user://spider_wars.cfg")
	save.set_value("campaign", "highest_unlocked", maxi(2, int(save.get_value("campaign", "highest_unlocked", 1))))
	save.set_value("campaign", "level_1_stars", 3)
	save.save("user://spider_wars.cfg")
	queue_redraw()

func next_level() -> void:
	if level < 4:
		level += 1
		start_level()
	else:
		start_level()

func update_hud() -> void:
	if level == 1:
		stat_label.text = "Silk  %d / %d" % [silk, HOME_COST]
		progress_label.text = "Bugs Collected: %d/3" % mini(bugs_caught, 3)
	else:
		stat_label.text = "Silk  %d     Territory  %.0f%%" % [silk, graph.territory_percent()]
		var claimed := 0
		for home in homes:
			if home.owner == 1:
				claimed += 1
		progress_label.text = "Homes %d/%d   ·   Webs %d" % [claimed, 1 if level == 2 else 2, graph.active_edge_count()]
		if level == 4:
			progress_label.text = "Homes %d/2   ·   Hold %.0f/10s" % [claimed, hold_time]

func _draw() -> void:
	if level >= 2 and graph != null:
		draw_web_level()
	elif level == 1:
		for at in [Vector2(180, 470), Vector2(875, 560), Vector2(785, 1340), Vector2(260, 1450)]:
			draw_circle(at, 18.0, Color(0.56, 0.85, 0.91, 0.55))
			draw_circle(at, 9.0, Color(0.91, 0.99, 1.0, 0.85))
	# The home site appears only after the movement and collection lessons.
	if step == 2 or constructing:
		var radius := 93.0 + sin(pulse * 3.2) * 7.0
		draw_circle(HOME_POSITION, radius, Color(0.17, 0.74, 0.97, 0.18))
		draw_arc(HOME_POSITION, radius, -PI / 2.0, -PI / 2.0 + TAU * maxf(home_ring, 0.06), 80, Color(0.60, 0.94, 1.0), 8.0, true)
		if constructing:
			for i in 8:
				var angle := TAU * float(i) / 8.0
				var end := HOME_POSITION + Vector2.from_angle(angle) * radius * home_ring
				draw_line(HOME_POSITION, end, Color(0.84, 0.96, 1.0, 0.85), 3.0)
	if nest_built:
		draw_arc(HOME_POSITION, 94.0, 0.0, TAU, 80, Color(0.25, 0.74, 1.0, 0.8), 5.0, true)

func setup_web_level() -> void:
	var points: Array[Vector2] = []
	if level == 2:
		title_label.text = "LEVEL 2  ·  GROWING TERRITORY"
		points = [Vector2(235, 460), Vector2(540, 405), Vector2(845, 480), Vector2(875, 830), Vector2(810, 1250), Vector2(520, 1350), Vector2(210, 1180), Vector2(175, 790)]
		homes = [{"position": Vector2(520, 945), "owner": 0, "progress": 0.0}]
		instruction_label.text = "Catch bugs, then connect anchors into a loop."
	elif level == 3:
		title_label.text = "LEVEL 3  ·  WEB MASTER"
		points = [Vector2(145, 390), Vector2(405, 350), Vector2(670, 350), Vector2(925, 420), Vector2(945, 705), Vector2(945, 1050), Vector2(905, 1495), Vector2(650, 1510), Vector2(395, 1490), Vector2(135, 1415), Vector2(125, 1070), Vector2(125, 730)]
		homes = [
			{"position": Vector2(335, 850), "owner": 0, "progress": 0.0},
			{"position": Vector2(765, 835), "owner": 0, "progress": 0.0},
			{"position": Vector2(550, 1215), "owner": 0, "progress": 0.0}
		]
		instruction_label.text = "Build your network and claim two homes."
	else:
		title_label.text = "LEVEL 4  ·  THE RIVAL ARRIVES"
		points = [Vector2(135, 420), Vector2(390, 370), Vector2(620, 480), Vector2(625, 810), Vector2(495, 1240), Vector2(165, 1200), Vector2(125, 820)]
		homes = [
			{"position": Vector2(350, 760), "owner": 0, "progress": 0.0},
			{"position": Vector2(750, 850), "owner": 0, "progress": 0.0},
			{"position": Vector2(560, 1160), "owner": 0, "progress": 0.0}
		]
		instruction_label.text = "Watch out! Capture homes before your rival."
	graph.configure(points, PLAY_BOUNDS.size.x * PLAY_BOUNDS.size.y)
	player.position = Vector2(250, 570)
	home_sprite.position = points[0] + Vector2(0, 60)
	home_sprite.scale = Vector2(0.22, 0.22)
	home_sprite.visible = true
	silk = 45
	queue_redraw()

func toggle_web_mode() -> void:
	if level < 2 or level_completed:
		return
	web_mode = not web_mode
	web_start = -1
	web_pointer = -2
	build_web_button.text = "CANCEL WEB" if web_mode else "BUILD WEB"
	instruction_label.text = "Drag from a glowing anchor to another anchor." if web_mode else "Explore, collect silk, and claim homes."
	queue_redraw()

func nearest_anchor(at: Vector2) -> int:
	if graph == null:
		return -1
	var closest := -1
	var distance := 78.0
	for i in graph.nodes.size():
		var candidate := at.distance_to(graph.nodes[i])
		if candidate < distance:
			closest = i
			distance = candidate
	return closest

func _input(event: InputEvent) -> void:
	if repair_mode and level == 3:
		if event is InputEventScreenTouch and event.pressed:
			select_damaged_web(event.position)
		elif event is InputEventMouseButton and event.pressed:
			select_damaged_web(event.position)
		return
	if not web_mode or level < 2 or level_completed:
		return
	if event is InputEventScreenTouch:
		if event.pressed and web_pointer == -2:
			var index := nearest_anchor(event.position)
			if index >= 0:
				web_pointer = event.index
				web_start = index
				web_end = event.position
				queue_redraw()
		elif not event.pressed and web_pointer == event.index:
			finish_web_gesture(event.position)
	elif event is InputEventScreenDrag and web_pointer == event.index:
		web_end = event.position
		update_web_preview()
		queue_redraw()
	elif event is InputEventMouseButton:
		if event.pressed and web_pointer == -2:
			var index := nearest_anchor(event.position)
			if index >= 0:
				web_pointer = -1
				web_start = index
				web_end = event.position
				queue_redraw()
		elif not event.pressed and web_pointer == -1:
			finish_web_gesture(event.position)
	elif event is InputEventMouseMotion and web_pointer == -1:
		web_end = event.position
		update_web_preview()
		queue_redraw()

func update_web_preview() -> void:
	var target := nearest_anchor(web_end)
	if web_start >= 0 and target >= 0 and target != web_start:
		var price := graph.cost(web_start, target)
		instruction_label.text = "Web cost: %d silk" % price

func finish_web_gesture(at: Vector2) -> void:
	var target := nearest_anchor(at)
	if web_start >= 0 and target >= 0 and graph.can_build(web_start, target):
		var price := graph.cost(web_start, target)
		if silk >= price:
			silk -= price
			graph.build(web_start, target)
			play_sound(build_sound)
			if graph.regions.size() > 0:
				show_popup("TERRITORY CAPTURED!", at)
				silk += 15
				instruction_label.text = "Territory captured! Claim abandoned homes."
			elif graph.active_edge_count() == 1:
				instruction_label.text = "Good! Continue around the anchors."
			if level == 3 and graph.territory_percent() >= 60.0 and not damage_triggered:
				trigger_web_damage()
			update_hud()
		else:
			instruction_label.text = "Need %d silk. Catch more bugs!" % price
	else:
		instruction_label.text = "Connect different anchors without crossing webs."
	web_start = -1
	web_pointer = -2
	queue_redraw()

func update_homes(delta: float) -> void:
	home_production_timer += delta
	if home_production_timer >= 8.0:
		home_production_timer = 0.0
		for home in homes:
			if home.owner == 1:
				silk += 5
				show_popup("+5 Silk", home.position)
			elif home.owner == 2 and is_instance_valid(enemy_ai):
				enemy_ai.silk += 5
		update_hud()
	for home in homes:
		var blue_here := player.position.distance_to(home.position) <= 70.0
		var red_here := level == 4 and is_instance_valid(enemy) and enemy.position.distance_to(home.position) <= 70.0
		if blue_here and red_here:
			continue
		if home.owner == 1 and not red_here:
			continue
		if home.owner == 2 and not blue_here:
			continue
		if blue_here or red_here:
			var challenger := 1 if blue_here else 2
			if home.owner == challenger:
				continue
			if home.get("capturer", 0) != challenger:
				home.capturer = challenger
				home.progress = 0.0
			var duration := 6.0 if home.owner != 0 else 4.0
			home.progress = minf(1.0, float(home.progress) + delta / duration)
			if home.progress >= 1.0:
				if home.owner != 0:
					home.owner = 0
					home.progress = 0.0
					show_popup("HOME NEUTRALIZED!", home.position)
				else:
					home.owner = challenger
					play_sound(win_sound if challenger == 1 else build_sound)
					show_popup("NEW HOME CAPTURED!", home.position)
					if challenger == 1:
						instruction_label.text = "New home captured! It produces silk."
						var nearest := nearest_anchor(home.position)
						if nearest >= 0 and not graph.roots.has(nearest):
							graph.roots.append(nearest)
					update_hud()
		else:
			home.progress = maxf(0.0, float(home.progress) - delta / 8.0)
	queue_redraw()

func trigger_web_damage() -> void:
	damage_triggered = true
	graph.damage(0, 1)
	instruction_label.text = "Your web is damaged! Repair it."
	repair_button.visible = true
	update_hud()

func begin_repair_selection() -> void:
	if level != 3 or not damage_triggered or repaired:
		return
	repair_mode = true
	web_mode = false
	build_web_button.text = "BUILD WEB"
	instruction_label.text = "Tap the red broken web to repair it."

func select_damaged_web(at: Vector2) -> void:
	var closest := Geometry2D.get_closest_point_to_segment(at, graph.nodes[0], graph.nodes[1])
	if closest.distance_to(at) <= 55.0:
		repair_web()
	else:
		instruction_label.text = "Tap the red broken connection."

func repair_web() -> void:
	if level != 3 or not damage_triggered or repaired:
		return
	if silk < 10:
		instruction_label.text = "Catch bugs to earn 10 silk for repair."
		return
	if graph.repair(0, 1):
		silk -= 10
		repaired = true
		repair_mode = false
		repair_button.visible = false
		instruction_label.text = "Web restored! Capture two homes and 60% territory."
		update_hud()
		queue_redraw()

func check_web_level_completion() -> void:
	if level_completed:
		return
	var claimed := 0
	for home in homes:
		if home.owner == 1:
			claimed += 1
	if level == 2 and claimed >= 1 and graph.territory_percent() >= 25.0:
		complete_web_level()
	elif level == 3 and claimed >= 2 and repaired and graph.territory_percent() >= 60.0:
		complete_web_level()
	elif level == 4:
		if claimed >= 2:
			hold_time += get_process_delta_time()
		else:
			hold_time = 0.0
		update_hud()
		if hold_time >= 10.0:
			complete_web_level()

func complete_web_level() -> void:
	level_completed = true
	play_sound(win_sound)
	web_mode = false
	build_web_button.visible = false
	player.desired_direction = Vector2.ZERO
	if level == 2:
		victory_title.text = "GARDEN EXPANDED!"
		victory_note.text = "Your kingdom is growing."
	elif level == 3:
		victory_title.text = "WEB MASTER!"
		victory_note.text = "Someone has discovered your kingdom..."
	else:
		victory_title.text = "RIVAL OUTSMARTED!"
		victory_note.text = "You held the homes against the red spider."
	victory_panel.visible = true
	var save := ConfigFile.new()
	save.load("user://spider_wars.cfg")
	save.set_value("campaign", "highest_unlocked", maxi(level + 1, int(save.get_value("campaign", "highest_unlocked", 1))))
	save.set_value("campaign", "level_%d_stars" % level, 3)
	save.save("user://spider_wars.cfg")
	if level == 3:
		instruction_label.text = "A new challenger approaches!"
		cinematic_red = Sprite2D.new()
		cinematic_red.texture = RED_SPIDER
		cinematic_red.position = Vector2(880, 440)
		cinematic_red.scale = Vector2(0.13, 0.13)
		cinematic_red.modulate.a = 0.0
		add_child(cinematic_red)
		create_tween().tween_property(cinematic_red, "modulate:a", 1.0, 1.5)

func draw_web_level() -> void:
	if level == 4 and red_graph != null:
		for region in red_graph.regions:
			draw_colored_polygon(region, Color(0.95, 0.12, 0.12, 0.18))
		for record in red_graph.edges.values():
			var red_from: Vector2 = red_graph.nodes[int(record.a)]
			var red_to: Vector2 = red_graph.nodes[int(record.b)]
			draw_line(red_from, red_to, Color(0.9, 0.16, 0.12, 0.9), 7.0, true)
		for at in red_graph.nodes:
			draw_circle(at, 12.0, Color(1.0, 0.37, 0.29, 0.9))
	for region in graph.regions:
		draw_colored_polygon(region, Color(0.11, 0.54, 0.98, 0.20))
	for record in graph.edges.values():
		var from: Vector2 = graph.nodes[int(record.a)]
		var to: Vector2 = graph.nodes[int(record.b)]
		var color := Color(0.62, 0.92, 1.0, 0.95) if record.active else Color(0.9, 0.2, 0.15, 0.9)
		draw_line(from, to, Color(0.08, 0.29, 0.55, 0.42), 16.0, true)
		draw_line(from, to, color, 6.0, true)
	for i in graph.nodes.size():
		var at: Vector2 = graph.nodes[i]
		var glow := 25.0 + sin(pulse * 3.0 + i) * 3.0
		draw_circle(at, glow, Color(0.2, 0.75, 1.0, 0.25))
		draw_circle(at, 13.0, Color(0.85, 0.98, 1.0))
		draw_arc(at, 16.0, 0.0, TAU, 32, Color(0.10, 0.46, 0.83), 4.0, true)
	for home in homes:
		var at: Vector2 = home.position
		var tint := Color(0.4, 0.8, 1.0, 0.75) if home.owner == 1 else (Color(1.0, 0.35, 0.35, 0.85) if home.owner == 2 else Color(0.82, 0.82, 0.77, 0.78))
		draw_circle(at, 62.0, Color(tint.r, tint.g, tint.b, 0.17))
		draw_arc(at, 65.0, -PI / 2.0, -PI / 2.0 + TAU * float(home.progress), 48, tint, 7.0, true)
		draw_texture_rect_region(ATLAS, Rect2(at - Vector2(56, 55), Vector2(112, 110)), Rect2(0, 765, 475, 515), tint)
	if web_start >= 0:
		var from: Vector2 = graph.nodes[web_start]
		var target := nearest_anchor(web_end)
		var price := graph.cost(web_start, target) if target >= 0 and target != web_start else 0
		var valid := target >= 0 and graph.can_build(web_start, target) and silk >= price
		draw_line(from, web_end, Color(0.38, 0.9, 1.0, 0.85) if valid else Color(1.0, 0.45, 0.4, 0.7), 5.0, true)

func setup_enemy() -> void:
	red_graph = WebGraphScript.new()
	var red_points: Array[Vector2] = [Vector2(910, 1270), Vector2(865, 1060), Vector2(710, 990), Vector2(655, 1280), Vector2(790, 1480)]
	red_graph.configure(red_points, PLAY_BOUNDS.size.x * PLAY_BOUNDS.size.y)
	enemy = SpiderScript.new()
	enemy.name = "RedSpider"
	enemy.position = Vector2(870, 1280)
	enemy.bounds = PLAY_BOUNDS
	enemy.speed = 205.0
	enemy.setup(RED_SPIDER, 2)
	enemy.visual.scale = Vector2(0.16, 0.16)
	enemy.add_to_group("enemy_spiders")
	add_child(enemy)
	red_nest = Sprite2D.new()
	red_nest.texture = home_sprite.texture
	red_nest.position = red_points[0]
	red_nest.scale = Vector2(0.18, 0.18)
	red_nest.modulate = Color(1.0, 0.45, 0.45)
	red_nest.z_index = -1
	add_child(red_nest)
	enemy_ai = EnemyAIScript.new()
	enemy_ai.configure(enemy, red_graph, bugs, homes)
	enemy_ai.build_requested.connect(on_enemy_build_requested)
	add_child(enemy_ai)
	instruction_label.text = "Watch out! A rival spider has arrived!"

func setup_obstacles() -> void:
	var locations: Array[Vector2] = []
	match level:
		1:
			locations = [Vector2(865, 415), Vector2(155, 690)]
		2:
			locations = [Vector2(385, 790), Vector2(760, 1030)]
		3:
			locations = [Vector2(310, 620), Vector2(815, 1120), Vector2(300, 1300)]
		4:
			locations = [Vector2(490, 690), Vector2(760, 1330)]
	for at in locations:
		var body := StaticBody2D.new()
		body.position = at
		body.collision_layer = 1
		body.collision_mask = 0
		var sprite := Sprite2D.new()
		sprite.texture = ROCK
		sprite.scale = Vector2(0.145, 0.145)
		body.add_child(sprite)
		var shape := CircleShape2D.new()
		shape.radius = 60.0
		var collider := CollisionShape2D.new()
		collider.shape = shape
		body.add_child(collider)
		add_child(body)
		obstacle_nodes.append(body)
		obstacles.append({"position": at, "radius": 60.0})
	if level >= 2:
		graph.obstacles = obstacles
		graph.capturable_area = PLAY_BOUNDS.size.x * PLAY_BOUNDS.size.y - float(obstacles.size()) * PI * 60.0 * 60.0
	if level == 4:
		red_graph.obstacles = obstacles
		red_graph.capturable_area = graph.capturable_area

func play_sound(stream: AudioStreamWAV) -> void:
	var settings := get_node_or_null("/root/AppSettings")
	if settings != null and not settings.sfx_enabled:
		return
	var player_node := AudioStreamPlayer.new()
	player_node.stream = stream
	player_node.volume_db = -12.0
	add_child(player_node)
	player_node.play()
	player_node.finished.connect(player_node.queue_free)

func on_enemy_build_requested(a: int, b: int) -> void:
	var price := red_graph.cost(a, b)
	if enemy_ai.silk < price or not red_graph.can_build(a, b):
		return
	enemy_ai.silk -= price
	red_graph.build(a, b, 2)
	queue_redraw()
