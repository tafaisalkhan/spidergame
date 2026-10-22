extends SceneTree

const FIRST_HUNT = preload("res://scenes/first_hunt_2.tscn")
const SECOND_HUNT = preload("res://scenes/first_hunt.tscn")

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	var game = FIRST_HUNT.instantiate()
	root.add_child(game)
	await process_frame
	game.finish_intro_reveal()
	game.spider.position = game.rival.position
	assert(game.choose_rival_next_node() == game.escape_step_from(game.rival_node, game.spider.position))
	var edge: Vector2i = game.web_edges[0]
	game.spider_node = edge.x
	game.spider_target = edge.y
	game.spider_progress = 0.47
	game.spider.position = game.web_position(edge.x, edge.y, game.spider_progress)
	game.spider.desired_direction = (game.web_points[edge.y] - game.web_points[edge.x]).normalized()
	game.rival_node = edge.y
	game.rival_target = edge.x
	game.rival_progress = 0.47
	game.rival.position = game.web_position(edge.y, edge.x, game.rival_progress)
	game.player_power = 0
	game.rival_power = 0
	var blue_before: Vector2 = game.spider.position
	var red_before: Vector2 = game.rival.position
	assert(blue_before.distance_to(red_before) < game.SPIDER_SEPARATION)
	game._physics_process(0.016)
	assert(game.spider.position != blue_before)
	assert(game.rival.position != red_before)
	assert(game.player_active and not game.rival_active)
	assert(game.player_rival_eat_remaining > 0.0 and game.player_power == 0)
	game._physics_process(game.RIVAL_EAT_DURATION + 0.01)
	assert(game.player_power == 1)
	assert(not game.finished and game.caught_count == 0)
	game.queue_free()
	await process_frame
	set_meta("first_hunt_level", 6)
	var second = SECOND_HUNT.instantiate()
	root.add_child(second)
	await process_frame
	var hunter = second.extra_rivals[0]
	second.spider.position = hunter.spider.position
	assert(second.extra_rival_destination(hunter) == second.escape_step_from(hunter.node, second.spider.position))
	second.resolve_player_rival_collision(hunter.spider)
	assert(second.player_active and not hunter.active)
	assert(second.player_rival_eat_remaining > 0.0)
	second._physics_process(second.RIVAL_EAT_DURATION + 0.01)
	assert(second.player_power == 1 and second.caught_count == 0 and not second.finished)
	print("SPIDER_WARS_FACE_TO_FACE_PASS")
	quit()
