extends SceneTree

const GameScene = preload("res://scenes/game.tscn")
const GraphScript = preload("res://scripts/web_graph.gd")

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	var game := GameScene.instantiate()
	root.add_child(game)
	await process_frame
	assert(game.player != null)
	assert(game.level == 1)
	assert(game.bugs.size() == 3)
	assert(not game.nest_built)
	assert(game.get_tree().get_nodes_in_group("enemy_spiders").is_empty())
	game.on_player_moved(121.0)
	assert(game.step == 1)
	for bug in game.bugs:
		game.on_bug_caught(bug, 1)
	assert(game.step == 2)
	assert(game.silk == 30)
	game.player.position = game.HOME_POSITION
	game.begin_nest()
	assert(game.constructing)
	assert(game.silk == 0)
	game.finish_nest()
	assert(game.nest_built)
	game.level = 2
	game.start_level()
	assert(game.player.owner_id == 1)
	assert(game.graph.nodes.size() == 8)
	assert(game.get_tree().get_nodes_in_group("enemy_spiders").is_empty())
	game.level = 3
	game.start_level()
	assert(game.graph.nodes.size() == 12)
	assert(game.get_tree().get_nodes_in_group("enemy_spiders").is_empty())
	game.level = 4
	game.start_level()
	assert(game.enemy != null)
	assert(game.enemy.owner_id == 2)
	assert(game.get_tree().get_nodes_in_group("enemy_spiders").size() == 1)
	var old_silk: int = game.enemy_ai.silk
	game.on_bug_caught(game.bugs[0], 2)
	assert(game.enemy_ai.silk == old_silk + 10)
	game.enemy_ai.silk = 100
	game.on_enemy_build_requested(0, 1)
	assert(game.red_graph.active_edge_count() == 1)
	var graph = GraphScript.new()
	var points: Array[Vector2] = [Vector2(0, 0), Vector2(100, 0), Vector2(100, 100), Vector2(0, 100)]
	graph.configure(points, 10000.0)
	assert(graph.build(0, 1))
	assert(graph.build(1, 2))
	assert(graph.build(2, 3))
	assert(graph.build(3, 0))
	assert(graph.territory_percent() >= 99.0)
	graph.damage(0, 1)
	assert(graph.territory_percent() == 0.0)
	assert(graph.repair(0, 1))
	assert(graph.territory_percent() >= 99.0)
	assert(graph.build(0, 2))
	assert(not graph.can_build(1, 3))
	print("SPIDER_WARS_CORE_PASS")
	game.free()
	quit()
