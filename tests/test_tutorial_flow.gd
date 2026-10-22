extends SceneTree

const GameScene = preload("res://scenes/game.tscn")

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	var game := GameScene.instantiate()
	root.add_child(game)
	await process_frame
	game.level = 2
	game.start_level()
	for i in game.graph.nodes.size():
		assert(game.graph.build(i, (i + 1) % game.graph.nodes.size()))
	assert(game.graph.territory_percent() >= 25.0)
	game.player.position = game.homes[0].position
	game.update_homes(4.1)
	assert(game.homes[0].owner == 1)
	game.check_web_level_completion()
	assert(game.level_completed)
	game.level = 3
	game.start_level()
	for i in game.graph.nodes.size():
		assert(game.graph.build(i, (i + 1) % game.graph.nodes.size()))
	assert(game.graph.territory_percent() >= 60.0)
	game.trigger_web_damage()
	assert(game.graph.territory_percent() < 60.0)
	game.silk = 100
	game.repair_web()
	assert(game.repaired)
	for i in 2:
		game.player.position = game.homes[i].position
		game.update_homes(4.1)
	assert(game.homes[0].owner == 1 and game.homes[1].owner == 1)
	game.check_web_level_completion()
	assert(game.level_completed)
	assert(game.cinematic_red != null)
	game.level = 4
	game.start_level()
	game.player.position = game.homes[0].position
	game.enemy.position = game.homes[0].position
	game.update_homes(4.1)
	assert(game.homes[0].owner == 0)
	assert(game.homes[0].progress == 0.0)
	game.enemy.position = Vector2(900, 1450)
	game.update_homes(4.1)
	assert(game.homes[0].owner == 1)
	game.player.position = Vector2(100, 400)
	game.enemy.position = game.homes[1].position
	game.update_homes(4.1)
	assert(game.homes[1].owner == 2)
	print("SPIDER_WARS_TUTORIAL_FLOW_PASS")
	game.free()
	quit()
