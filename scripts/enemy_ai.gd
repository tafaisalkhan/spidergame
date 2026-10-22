extends Node
class_name EnemySpiderAI

signal build_requested(a: int, b: int)

var spider: Spider
var graph: WebGraph
var bugs: Array[GardenBug] = []
var homes: Array[Dictionary] = []
var silk := 45
var think_timer := 0.0
var build_timer := 3.0
var target := Vector2.ZERO
var state := "EXPLORE"

func configure(actor: Spider, web: WebGraph, available_bugs: Array[GardenBug], available_homes: Array[Dictionary]) -> void:
	spider = actor
	graph = web
	bugs = available_bugs
	homes = available_homes
	target = spider.position

func _process(delta: float) -> void:
	if spider == null:
		return
	think_timer -= delta
	build_timer -= delta
	if think_timer <= 0.0:
		think_timer = 0.55
		choose_target()
	if spider.position.distance_to(target) > 20.0:
		spider.desired_direction = (target - spider.position).normalized()
	else:
		spider.desired_direction = Vector2.ZERO
	if build_timer <= 0.0:
		build_timer = 4.0
		try_build()

func choose_target() -> void:
	var best_score := -INF
	var best := spider.position
	var best_state := "EXPLORE"
	for home in homes:
		if home.owner == 2:
			continue
		var distance := spider.position.distance_to(home.position)
		var score := 500.0 - distance * 0.35
		if silk < 20:
			score -= 300.0
		if score > best_score:
			best_score = score
			best = home.position
			best_state = "CAPTURE_HOME"
	for bug in bugs:
		if not bug.active:
			continue
		var distance := spider.position.distance_to(bug.position)
		var score := (650.0 if silk < 25 else 260.0) + float(bug.reward) * 2.0 - distance * 0.6
		if score > best_score:
			best_score = score
			best = bug.position
			best_state = "COLLECT_BUGS"
	target = best
	state = best_state

func try_build() -> void:
	if silk < 15:
		return
	for a in graph.nodes.size():
		if spider.position.distance_to(graph.nodes[a]) > 260.0:
			continue
		var b := (a + 1) % graph.nodes.size()
		if graph.can_build(a, b) and silk >= graph.cost(a, b):
			build_requested.emit(a, b)
			return
