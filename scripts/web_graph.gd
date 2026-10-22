extends RefCounted
class_name WebGraph

var nodes: Array[Vector2] = []
var edges: Dictionary = {}
var roots: Array[int] = [0]
var regions: Array[PackedVector2Array] = []
var capturable_area := 1.0
var obstacles: Array[Dictionary] = []

func configure(points: Array[Vector2], map_area: float) -> void:
	nodes = points.duplicate()
	edges.clear()
	regions.clear()
	roots = [0]
	capturable_area = maxf(1.0, map_area)

func key(a: int, b: int) -> String:
	return "%d:%d" % [mini(a, b), maxi(a, b)]

func cost(a: int, b: int) -> int:
	return ceili(nodes[a].distance_to(nodes[b]) / 40.0 * 5.0)

func can_build(a: int, b: int) -> bool:
	if a < 0 or b < 0 or a >= nodes.size() or b >= nodes.size() or a == b:
		return false
	if edges.has(key(a, b)):
		return false
	if not is_connected_to_root(a) and not is_connected_to_root(b):
		return false
	for record in edges.values():
		if int(record.a) == a or int(record.b) == a or int(record.a) == b or int(record.b) == b:
			continue
		if segments_cross(nodes[a], nodes[b], nodes[int(record.a)], nodes[int(record.b)]):
			return false
	for obstacle in obstacles:
		var closest := Geometry2D.get_closest_point_to_segment(obstacle.position, nodes[a], nodes[b])
		if closest.distance_to(obstacle.position) < float(obstacle.radius) + 8.0:
			return false
	return true

func build(a: int, b: int, owner_id: int = 1) -> bool:
	if not can_build(a, b):
		return false
	var previous_path := path_between(a, b)
	edges[key(a, b)] = {"a": a, "b": b, "owner": owner_id, "health": 100, "active": true}
	if previous_path.size() >= 3:
		var polygon := PackedVector2Array()
		for index in previous_path:
			polygon.append(nodes[index])
		if absf(polygon_area(polygon)) >= 100.0 and cycle_has_root(previous_path):
			regions.append(polygon)
	return true

func damage(a: int, b: int) -> void:
	var edge_key := key(a, b)
	if edges.has(edge_key):
		edges[edge_key].active = false
		edges[edge_key].health = 0
		recalculate_regions()

func repair(a: int, b: int) -> bool:
	var edge_key := key(a, b)
	if not edges.has(edge_key) or edges[edge_key].active:
		return false
	edges[edge_key].active = true
	edges[edge_key].health = 100
	recalculate_regions()
	return true

func recalculate_regions() -> void:
	regions.clear()
	var seen: Dictionary = {}
	for record in edges.values():
		if not record.active:
			continue
		var a: int = record.a
		var b: int = record.b
		var path := path_between(a, b, key(a, b))
		if path.size() < 3 or not cycle_has_root(path):
			continue
		var ids := path.duplicate()
		ids.sort()
		var signature := str(ids)
		if seen.has(signature):
			continue
		seen[signature] = true
		var polygon := PackedVector2Array()
		for index in path:
			polygon.append(nodes[index])
		if absf(polygon_area(polygon)) >= 100.0:
			regions.append(polygon)

func territory_percent() -> float:
	var total := 0.0
	for polygon in regions:
		total += absf(polygon_area(polygon))
		for obstacle in obstacles:
			if Geometry2D.is_point_in_polygon(obstacle.position, polygon):
				total -= PI * float(obstacle.radius) * float(obstacle.radius)
	return minf(100.0, total / capturable_area * 100.0)

func active_edge_count() -> int:
	var count := 0
	for record in edges.values():
		if record.active:
			count += 1
	return count

func is_connected_to_root(index: int) -> bool:
	if roots.has(index):
		return true
	for root in roots:
		if not path_between(root, index).is_empty():
			return true
	return false

func cycle_has_root(path: Array[int]) -> bool:
	for index in path:
		if is_connected_to_root(index):
			return true
	return false

func path_between(start: int, target: int, excluded_edge := "") -> Array[int]:
	if start == target:
		return [start]
	var queue: Array[int] = [start]
	var parent: Dictionary = {start: -1}
	while not queue.is_empty():
		var current: int = queue.pop_front()
		for record in edges.values():
			if not record.active or key(int(record.a), int(record.b)) == excluded_edge:
				continue
			var neighbor := -1
			if int(record.a) == current:
				neighbor = int(record.b)
			elif int(record.b) == current:
				neighbor = int(record.a)
			if neighbor < 0 or parent.has(neighbor):
				continue
			parent[neighbor] = current
			if neighbor == target:
				var path: Array[int] = [target]
				var cursor := target
				while cursor != start:
					cursor = parent[cursor]
					path.push_front(cursor)
				return path
			queue.append(neighbor)
	return []

func segments_cross(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> bool:
	var ab_c := (b - a).cross(c - a)
	var ab_d := (b - a).cross(d - a)
	var cd_a := (d - c).cross(a - c)
	var cd_b := (d - c).cross(b - c)
	return ab_c * ab_d < -0.001 and cd_a * cd_b < -0.001

func polygon_area(polygon: PackedVector2Array) -> float:
	var total := 0.0
	for i in polygon.size():
		var next := (i + 1) % polygon.size()
		total += polygon[i].cross(polygon[next])
	return total * 0.5
