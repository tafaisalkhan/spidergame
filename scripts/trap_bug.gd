extends Node2D
class_name TrapBug

const MOTION_SHADER = preload("res://shaders/bug_motion.gdshader")
const HealthBarScript = preload("res://scripts/world_health_bar.gd")
const FREE_VOICE_CLIP = preload("res://assets/sound/bugs_free_voice_loop.ogg")
const FLY_SOUND = preload("res://assets/sound/bugfly.mp3")
const STUCK_SOUND = preload("res://assets/sound/bug_stcuk_with_web.mp3")

signal escaped(bug: TrapBug)
signal broke_free(bug: TrapBug)
signal web_cut_requested(bug: TrapBug)

enum MotionStyle { FLY, CRAWL, FLUTTER, HOP }

var points: Array[Vector2] = []
var route: Array[int] = []
var route_index := 0
var progress := 0.0
var speed := 15.0
var active := true
var sprite: Sprite2D
var health_bar: WorldHealthBar
var free_voice_player: AudioStreamPlayer
var flight_audio: AudioStreamPlayer
var stuck_audio: AudioStreamPlayer
var flight_sounds_enabled := false
var release_timer_label: Label
var phase := 0.0
var path_sampler: Callable
var length_sampler: Callable
var size_factor := 1.0
var eat_duration := 0.9
var motion_style := MotionStyle.FLY
var land_motion_style := MotionStyle.CRAWL
var species_id := -1
var base_scale := Vector2.ONE
var facing := 0.0
var motion_material: ShaderMaterial
var stuck := true
var permanently_trapped := false
var arriving := false
var arrival_start := Vector2.ZERO
var arrival_target := Vector2.ZERO
var arrival_progress := 0.0
var strong := false
var glue_duration := 4.0
var glue_remaining := 4.0
var release_flash := 0.0
var land_permanently := true
var flies_away_on_release := false
var escaping_flight := false
var flight_start := Vector2.ZERO
var flight_target := Vector2.ZERO
var flight_progress := 0.0
var landing_flash := 0.0
var web_cut_limit := 0
var web_cuts_done := 0
var web_cut_remaining := 0.0
var web_cut_edges: Array[int] = []
var web_needs_repair := false
var repeat_web_cuts := false
var web_cut_has_happened := false
var cut_flash_remaining := 0.0
var escape_panic := 0.0
var escape_panic_goal := 0.0
var approach_panic_played := false

func set_escape_panic(level: float) -> void:
	escape_panic_goal = clampf(level, 0.0, 1.0)

func start_free_voice() -> void:
	var settings := get_node_or_null("/root/AppSettings")
	if settings != null and not settings.sfx_enabled:
		return
	if free_voice_player == null:
		free_voice_player = AudioStreamPlayer.new()
		free_voice_player.name = "FreeBugVoice"
		var voice_loop := FREE_VOICE_CLIP.duplicate() as AudioStreamOggVorbis
		voice_loop.loop = true
		free_voice_player.stream = voice_loop
		free_voice_player.volume_db = -12.0
		add_child(free_voice_player)
	free_voice_player.play()

func stop_free_voice() -> void:
	if is_instance_valid(free_voice_player) and free_voice_player.playing:
		free_voice_player.stop()

func start_flight_sound() -> void:
	if not flight_sounds_enabled:
		return
	var settings := get_node_or_null("/root/AppSettings")
	if settings != null and not settings.sfx_enabled:
		return
	if flight_audio == null:
		flight_audio = AudioStreamPlayer.new()
		flight_audio.name = "BugFlightAudio"
		flight_audio.stream = FLY_SOUND
		flight_audio.volume_db = -15.0
		add_child(flight_audio)
	if not flight_audio.playing:
		flight_audio.play()

func stop_flight_sound() -> void:
	if is_instance_valid(flight_audio) and flight_audio.playing:
		flight_audio.stop()

func play_stuck_sound() -> void:
	if not flight_sounds_enabled:
		return
	var settings := get_node_or_null("/root/AppSettings")
	if settings != null and not settings.sfx_enabled:
		return
	if stuck_audio == null:
		stuck_audio = AudioStreamPlayer.new()
		stuck_audio.name = "BugStuckAudio"
		stuck_audio.stream = STUCK_SOUND
		stuck_audio.volume_db = -10.0
		add_child(stuck_audio)
	stuck_audio.play()

func stop_bug_sounds() -> void:
	stop_free_voice()
	stop_flight_sound()
	if is_instance_valid(stuck_audio) and stuck_audio.playing:
		stuck_audio.stop()

func flash_web_cut() -> void:
	cut_flash_remaining = 0.8
	sprite.modulate.a = 0.25
	queue_redraw()

func setup(texture: Texture2D, web_points: Array[Vector2], escape_route: Array[int], travel_speed: float, sample_path: Callable = Callable(), sample_length: Callable = Callable(), bug_size: float = 1.0, style: MotionStyle = MotionStyle.FLY, hold_time: float = 4.0, is_strong: bool = false) -> void:
	points = web_points
	route = escape_route
	speed = travel_speed
	path_sampler = sample_path
	length_sampler = sample_length
	size_factor = bug_size
	eat_duration = 0.35 + bug_size * 0.65
	motion_style = style
	land_motion_style = style
	strong = is_strong
	glue_duration = hold_time
	glue_remaining = hold_time
	stuck = true
	release_flash = 0.0
	position = points[route[0]]
	sprite = Sprite2D.new()
	if texture is AtlasTexture:
		texture = ImageTexture.create_from_image(texture.get_image())
	sprite.texture = texture
	base_scale = Vector2(0.15, 0.15) * size_factor
	sprite.scale = base_scale
	motion_material = ShaderMaterial.new()
	motion_material.shader = MOTION_SHADER
	motion_material.set_shader_parameter("motion_style", motion_style)
	sprite.material = motion_material
	add_child(sprite)
	health_bar = HealthBarScript.new()
	health_bar.name = "HealthBar"
	health_bar.bar_width = clampf(50.0 * size_factor, 38.0, 74.0)
	health_bar.bar_height = 7.0
	health_bar.fill_color = Color(0.89, 0.94, 0.37)
	health_bar.position = Vector2(0.0, -maxf(26.0, 32.0 * size_factor))
	add_child(health_bar)
	refresh_trap_bar()
	queue_redraw()

func refresh_trap_bar() -> void:
	if health_bar == null:
		return
	if release_timer_label != null:
		health_bar.hide()
		release_timer_label.visible = active and stuck and not arriving and not escaping_flight
		release_timer_label.text = "%d" % ceili(glue_remaining)
		release_timer_label.add_theme_color_override("font_color", Color(1.0, 0.47, 0.39) if glue_remaining <= 5.0 else Color(1.0, 0.96, 0.75))
		return
	if permanently_trapped:
		health_bar.fill_color = Color(0.89, 0.94, 0.37)
		health_bar.set_health(100.0)
	else:
		var silk_fraction := clampf(glue_remaining / maxf(glue_duration, 0.01), 0.0, 1.0)
		health_bar.fill_color = Color(1.0, 0.18 + 0.30 * silk_fraction, 0.08) if strong else Color(1.0, 0.35 + 0.38 * silk_fraction, 0.12)
		health_bar.set_health(100.0 * silk_fraction)

func show_release_timer() -> void:
	release_timer_label = Label.new()
	release_timer_label.name = "ReleaseTimer"
	release_timer_label.size = Vector2(104.0, 42.0)
	release_timer_label.position = health_bar.position + Vector2(-52.0, -21.0)
	release_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	release_timer_label.add_theme_font_size_override("font_size", 28)
	release_timer_label.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.06, 1.0))
	release_timer_label.add_theme_constant_override("outline_size", 7)
	release_timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(release_timer_label)
	refresh_trap_bar()
	queue_redraw()

func start_arrival(from: Vector2) -> void:
	land_permanently = permanently_trapped
	arrival_start = from
	arrival_target = position
	arrival_progress = 0.0
	position = from
	arriving = true
	active = false
	stuck = false
	permanently_trapped = false
	motion_style = MotionStyle.FLY
	motion_material.set_shader_parameter("motion_style", motion_style)
	health_bar.hide()
	if release_timer_label != null:
		release_timer_label.hide()
	queue_redraw()

func _draw() -> void:
	if release_timer_label != null and active and stuck and not arriving and not escaping_flight:
		var timer_center := health_bar.position
		var timer_fraction := clampf(glue_remaining / maxf(glue_duration, 0.01), 0.0, 1.0)
		draw_circle(timer_center, 29.0, Color(0.09, 0.13, 0.18, 0.94))
		draw_arc(timer_center, 29.0, 0.0, TAU, 40, Color(0.34, 0.40, 0.45, 0.95), 5.0, true)
		draw_arc(timer_center, 29.0, -PI / 2.0, -PI / 2.0 + TAU * timer_fraction, 40, Color(1.0, 0.37, 0.27) if glue_remaining <= 5.0 else Color(1.0, 0.82, 0.31), 6.0, true)
	if cut_flash_remaining > 0.0:
		draw_arc(Vector2.ZERO, 39.0 * size_factor, 0.0, TAU, 30, Color(1.0, 0.34, 0.23, cut_flash_remaining / 0.8), 4.0, true)
	if web_needs_repair and stuck:
		var marker := Vector2(-56.0 if release_timer_label != null else 0.0, -maxf(58.0, 56.0 * size_factor))
		draw_circle(marker, 15.0, Color(0.21, 0.04, 0.07, 0.9))
		draw_arc(marker, 13.0, 0.0, TAU, 24, Color(1.0, 0.37, 0.29), 3.0, true)
		draw_line(marker + Vector2(-7.0, -7.0), marker + Vector2(7.0, 7.0), Color(1.0, 0.88, 0.70), 3.0, true)
		draw_line(marker + Vector2(7.0, -7.0), marker + Vector2(-7.0, 7.0), Color(1.0, 0.88, 0.70), 3.0, true)
	if arriving or escaping_flight:
		var wing_open := 0.65 + 0.35 * absf(sin(phase * 29.0))
		for side in [-1.0, 1.0]:
			var wing := PackedVector2Array([
				Vector2(side * 7.0, -9.0),
				Vector2(side * (18.0 + 13.0 * wing_open), -26.0),
				Vector2(side * (25.0 + 16.0 * wing_open), -6.0),
				Vector2(side * 9.0, 4.0)
			])
			for index in wing.size():
				wing[index] *= size_factor
			draw_colored_polygon(wing, Color(0.77, 0.96, 1.0, 0.52))
	var radius := 17.0 * size_factor
	var shadow := PackedVector2Array()
	for i in 16:
		var angle := TAU * float(i) / 16.0
		shadow.append(Vector2(cos(angle) * radius, sin(angle) * radius * 0.32))
	draw_colored_polygon(shadow, Color(0.04, 0.13, 0.13, 0.28 if motion_style == MotionStyle.CRAWL else 0.16))
	if stuck:
		var tension := 0.0 if permanently_trapped else 1.0 - glue_remaining / maxf(glue_duration, 0.01)
		if strong:
			draw_arc(Vector2.ZERO, 35.0 * size_factor, 0.0, TAU, 32, Color(1.0, 0.48, 0.12, 0.62 + 0.15 * sin(phase * 9.0)), 3.0, true)
		for strand in 6:
			var angle := TAU * float(strand) / 6.0 + phase * 0.025
			var near := Vector2.from_angle(angle) * 10.0 * size_factor
			var far := Vector2.from_angle(angle) * (31.0 + 6.0 * sin(phase * 12.0 + float(strand))) * size_factor
			draw_line(near, far, Color(0.93, 1.0, 0.93, 0.78 - tension * 0.23), 2.2 if strong else 3.2, true)
		draw_arc(Vector2.ZERO, 24.0 * size_factor, -PI / 2.0, -PI / 2.0 + TAU * tension, 24, Color(1.0, 0.79, 0.32) if strong else Color(0.84, 0.97, 1.0), 3.0, true)
		if landing_flash > 0.0:
			draw_arc(Vector2.ZERO, (28.0 + (1.0 - landing_flash / 0.5) * 35.0) * size_factor, 0.0, TAU, 28, Color(0.91, 1.0, 1.0, landing_flash), 3.5, true)
	elif release_flash > 0.0:
		for strand in 8:
			var angle := TAU * float(strand) / 8.0
			var outward := Vector2.from_angle(angle)
			draw_line(outward * 22.0 * size_factor, outward * (22.0 + (1.0 - release_flash / 0.35) * 23.0) * size_factor, Color(0.97, 1.0, 0.95, release_flash / 0.35), 2.2, true)

func _process(delta: float) -> void:
	if arriving:
		start_flight_sound()
		phase += delta
		arrival_progress = minf(1.0, arrival_progress + delta / 1.7)
		var t := 1.0 - pow(1.0 - arrival_progress, 2.0)
		var before := position
		position = arrival_start.lerp(arrival_target, t) + Vector2(sin(phase * 8.0) * 24.0 * (1.0 - t), -sin(t * PI) * 48.0)
		motion_material.set_shader_parameter("motion_phase", phase)
		animate_motion(delta, position - before, arrival_target - arrival_start)
		if arrival_progress >= 1.0:
			position = arrival_target
			arriving = false
			active = true
			stuck = true
			stop_flight_sound()
			play_stuck_sound()
			permanently_trapped = land_permanently
			motion_style = land_motion_style
			motion_material.set_shader_parameter("motion_style", motion_style)
			refresh_trap_bar()
			if release_timer_label == null:
				health_bar.show()
			landing_flash = 0.5
		queue_redraw()
		return
	if not active:
		return
	if is_instance_valid(free_voice_player) and free_voice_player.playing:
		var settings := get_node_or_null("/root/AppSettings")
		if settings != null and not settings.sfx_enabled:
			stop_free_voice()
	if is_instance_valid(flight_audio) and flight_audio.playing:
		var flight_settings := get_node_or_null("/root/AppSettings")
		if flight_settings != null and not flight_settings.sfx_enabled:
			stop_flight_sound()
	if cut_flash_remaining > 0.0:
		cut_flash_remaining = maxf(0.0, cut_flash_remaining - delta)
		sprite.modulate.a = 0.25 if int(ceilf(cut_flash_remaining / 0.1)) % 2 == 0 else 1.0
		queue_redraw()
	elif sprite.modulate.a < 1.0:
		sprite.modulate.a = 1.0
	if not escaping_flight:
		escape_panic = move_toward(escape_panic, escape_panic_goal, delta * 3.0)
	phase += delta * (1.0 + escape_panic * 2.2 if stuck else 1.0)
	motion_material.set_shader_parameter("motion_phase", phase)
	if escaping_flight:
		start_flight_sound()
		flight_progress = minf(1.0, flight_progress + delta / lerpf(1.2, 0.75, escape_panic))
		var before := position
		var t := flight_progress * flight_progress
		position = flight_start.lerp(flight_target, t) + Vector2(sin(phase * 14.0) * 20.0 * (1.0 - t), -sin(t * PI) * 32.0)
		animate_motion(delta, position - before, flight_target - flight_start)
		queue_redraw()
		if flight_progress >= 1.0:
			escaping_flight = false
			active = false
			visible = false
			stop_free_voice()
			stop_flight_sound()
			escaped.emit(self)
		return
	if stuck:
		landing_flash = maxf(0.0, landing_flash - delta)
		if not permanently_trapped:
			glue_remaining = maxf(0.0, glue_remaining - delta * (1.0 + escape_panic * 0.75))
			refresh_trap_bar()
		if web_cuts_done < web_cut_limit and (not repeat_web_cuts or escape_panic_goal > 0.0):
			var cut_rate := 1.0 if repeat_web_cuts and web_cut_has_happened else 1.0 + escape_panic * 1.9
			web_cut_remaining -= delta * cut_rate
			if web_cut_remaining <= 0.0:
				web_cut_remaining = randf_range(3.0, 5.0) if repeat_web_cuts else randf_range(5.0, 8.0)
				web_cut_has_happened = true
				web_cut_requested.emit(self)
		animate_motion(delta, Vector2.ZERO, points[route[1]] - points[route[0]])
		sprite.position += Vector2(sin(phase * 31.0) * (4.0 if strong else 2.5) * (1.0 + escape_panic * 2.0), cos(phase * 23.0) * 1.8 * (1.0 + escape_panic * 2.0))
		sprite.rotation += sin(phase * 27.0) * (0.10 if strong else 0.06) * (1.0 + escape_panic * 1.5)
		queue_redraw()
		if not permanently_trapped and glue_remaining <= 0.0:
			release_glue()
		return
	if release_flash > 0.0:
		release_flash = maxf(0.0, release_flash - delta)
		queue_redraw()
	if route_index >= route.size() - 1:
		active = false
		visible = false
		stop_free_voice()
		escaped.emit(self)
		return
	var from := points[route[route_index]]
	var to := points[route[route_index + 1]]
	var length: float = length_sampler.call(route[route_index], route[route_index + 1]) if length_sampler.is_valid() else from.distance_to(to)
	var old_position := position
	progress += speed * delta * pace_multiplier() / maxf(length, 1.0)
	position = path_sampler.call(route[route_index], route[route_index + 1], minf(progress, 1.0)) if path_sampler.is_valid() else from.lerp(to, minf(progress, 1.0))
	animate_motion(delta, position - old_position, to - from)
	if progress >= 1.0:
		route_index += 1
		progress = 0.0
		if route_index >= route.size() - 1:
			active = false
			visible = false
			stop_free_voice()
			escaped.emit(self)

func release_glue() -> void:
	if not stuck or not active:
		return
	stuck = false
	release_flash = 0.35
	if flies_away_on_release:
		escaping_flight = true
		flight_progress = 0.0
		flight_start = position
		flight_target = position + Vector2(260.0 if position.x < 540.0 else -260.0, -480.0)
		motion_style = MotionStyle.FLY
		motion_material.set_shader_parameter("motion_style", motion_style)
		health_bar.hide()
		if release_timer_label != null:
			release_timer_label.hide()
		start_flight_sound()
	start_free_voice()
	broke_free.emit(self)
	queue_redraw()

func pace_multiplier() -> float:
	match motion_style:
		MotionStyle.FLY:
			return 1.0 + 0.18 * sin(phase * 8.0)
		MotionStyle.CRAWL:
			return 0.75 + 0.30 * maxf(0.0, sin(phase * 11.0))
		MotionStyle.FLUTTER:
			return 0.82 + 0.34 * sin(phase * 5.0 + 0.7)
		MotionStyle.HOP:
			var cycle := fposmod(phase, 0.82) / 0.82
			return 0.08 if cycle < 0.28 else (1.95 if cycle < 0.82 else 0.30)
	return 1.0

func animate_motion(delta: float, displacement: Vector2, route_direction: Vector2) -> void:
	var direction := displacement if displacement.length_squared() > 0.01 else route_direction
	facing = lerp_angle(facing, direction.angle(), minf(1.0, delta * 12.0))
	match motion_style:
		MotionStyle.FLY:
			var flutter := sin(phase * 35.0)
			sprite.position = Vector2(sin(phase * 14.0) * 2.5, -13.0 + sin(phase * 15.0) * 6.0)
			sprite.scale = base_scale * Vector2(1.0 + flutter * 0.06, 1.0 - flutter * 0.05)
			sprite.rotation = facing + sin(phase * 13.0) * 0.08
		MotionStyle.CRAWL:
			var step := sin(phase * 19.0)
			sprite.position = Vector2(step * 1.8, -absf(step) * 1.7)
			sprite.scale = base_scale * Vector2(1.0 + step * 0.045, 1.0 - step * 0.035)
			sprite.rotation = facing + step * 0.045
		MotionStyle.FLUTTER:
			var wings := sin(phase * 13.0)
			sprite.position = Vector2(sin(phase * 6.0) * 5.0, -16.0 + sin(phase * 9.0) * 9.0)
			sprite.scale = base_scale * Vector2(0.80 + 0.20 * absf(wings), 1.03 - 0.08 * absf(wings))
			sprite.rotation = facing + sin(phase * 5.0) * 0.15
		MotionStyle.HOP:
			var cycle := fposmod(phase, 0.82) / 0.82
			var airborne := clampf((cycle - 0.28) / 0.54, 0.0, 1.0)
			var lift := sin(airborne * PI) * 24.0 if cycle >= 0.28 and cycle < 0.82 else 0.0
			sprite.position = Vector2.ZERO if lift == 0.0 else Vector2(0.0, -lift)
			var squash := 0.14 if cycle < 0.28 else 0.0
			sprite.scale = base_scale * Vector2(1.0 + squash, 1.0 - squash)
			sprite.rotation = facing + sin(airborne * PI) * 0.08

func catch() -> void:
	health_bar.set_health(0.0)
	stop_bug_sounds()
	active = false
	visible = false
