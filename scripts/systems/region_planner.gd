class_name RegionPlanner
extends RefCounted

## Builds a runtime Region from a RegionDef + RNG stream. Generates an
## organic node-graph map (no rows/columns): scatter nodes by Poisson-
## disc-lite, sort by x, build a DAG with reconvergence and branching
## driven by RegionDef tunables, sweep for orphans, smooth with light
## force-directed iteration. Stateless; static-only entry point.

const _PLAY_AREA_RECT: Rect2 = Rect2(80, 80, 1200 - 80, 640 - 80)
const _ENTRY_POSITION: Vector2 = Vector2(160, 360)
const _MIN_NODE_SPACING: float = 80.0
const _MAX_PLACEMENT_TRIES: int = 200
const _PARENT_X_RANGE: float = 380.0
const _PARENT_Y_RANGE: float = 220.0
const _SMOOTH_ITERATIONS: int = 30
const _SMOOTH_REPULSION: float = 4000.0
const _SMOOTH_SPRING: float = 0.02
const _SMOOTH_REST_LENGTH: float = 180.0


static func plan(def: RegionDef, stream: RandomNumberGenerator) -> Region:
	var n: int = clampi(def.node_count + stream.randi_range(-2, 2), 6, 24)

	var positions: Array[Vector2] = _scatter_positions(n, stream)
	var ordered: Array[int] = _order_by_x(positions)
	var map: RegionMap = _build_graph(positions, ordered, def, stream)
	_smooth_layout(map)
	_assign_kinds(map, def, stream)

	var region: Region = Region.new()
	region.def = def
	region.map = map
	region.current_node_id = map.entry_id
	# Use append rather than untyped Array literal to preserve Array[int] type.
	region.visited_ids.append(map.entry_id)
	return region


# Random scatter with min-distance rejection sampling. Entry is pinned.
static func _scatter_positions(n: int, stream: RandomNumberGenerator) -> Array[Vector2]:
	var result: Array[Vector2] = [_ENTRY_POSITION]
	var tries: int = 0
	while result.size() < n and tries < _MAX_PLACEMENT_TRIES * n:
		tries += 1
		var candidate: Vector2 = Vector2(
			stream.randf_range(_PLAY_AREA_RECT.position.x, _PLAY_AREA_RECT.end.x),
			stream.randf_range(_PLAY_AREA_RECT.position.y, _PLAY_AREA_RECT.end.y)
		)
		var ok: bool = true
		for existing: Vector2 in result:
			if candidate.distance_to(existing) < _MIN_NODE_SPACING:
				ok = false
				break
		if ok:
			result.append(candidate)
	# Fall through if we couldn't find enough spots — accept whatever we have.
	return result


# Returns indices into positions, with entry first and the rest sorted
# by ascending x. This gives a left->right "depth" without imposing
# columns.
static func _order_by_x(positions: Array[Vector2]) -> Array[int]:
	var indices: Array[int] = []
	for i: int in range(positions.size()):
		indices.append(i)
	# Drop entry (index 0) from the sort body, keep it at front.
	# Array.slice() returns an untyped Array — assign() preserves Array[int].
	var rest: Array[int] = []
	rest.assign(indices.slice(1))
	rest.sort_custom(func(a: int, b: int) -> bool: return positions[a].x < positions[b].x)
	var ordered: Array[int] = [0]
	ordered.append_array(rest)
	return ordered


static func _build_graph(
	positions: Array[Vector2],
	ordered: Array[int],
	def: RegionDef,
	stream: RandomNumberGenerator,
) -> RegionMap:
	var map: RegionMap = RegionMap.new()
	for idx: int in range(positions.size()):
		var node: MapNode = MapNode.new()
		node.id = idx
		node.position = positions[idx]
		map.nodes[idx] = node
	map.entry_id = 0

	# Step 4: build DAG edges using ordered as left->right depth.
	for rank: int in range(1, ordered.size()):
		var node_id: int = ordered[rank]
		var node: MapNode = map.nodes[node_id]
		var candidates: Array[int] = _parent_candidates(node, ordered, rank, map)
		if candidates.is_empty():
			# Step 6 fallback: nearest leftward node, unconditionally.
			var fallback: int = _nearest_leftward(node, ordered, rank, map)
			if fallback != -1:
				_link(map, fallback, node_id)
			continue
		# Default: 1 parent, nearest by Euclidean distance.
		candidates.sort_custom(
			func(a: int, b: int) -> bool:
				return (
					map.nodes[a].position.distance_to(node.position)
					< map.nodes[b].position.distance_to(node.position)
				)
		)
		_link(map, candidates[0], node_id)
		# With reconvergence_bias, pick a 2nd parent.
		if candidates.size() >= 2 and stream.randf() < def.reconvergence_bias:
			_link(map, candidates[1], node_id)

	# Step 5: outgoing-edge boost (branching intensity).
	for rank: int in range(1, ordered.size() - 1):
		var node_id: int = ordered[rank]
		var node: MapNode = map.nodes[node_id]
		if stream.randf() >= def.branching_bias:
			continue
		var forward_candidates: Array[int] = _forward_candidates(node, ordered, rank, map)
		if forward_candidates.is_empty():
			continue
		var pick: int = forward_candidates[stream.randi() % forward_candidates.size()]
		_link(map, node_id, pick)

	return map


static func _parent_candidates(
	node: MapNode, ordered: Array[int], rank: int, map: RegionMap
) -> Array[int]:
	var result: Array[int] = []
	for prev_rank: int in range(rank):
		var pid: int = ordered[prev_rank]
		var p: MapNode = map.nodes[pid]
		var dx: float = node.position.x - p.position.x
		if dx < 0.0 or dx > _PARENT_X_RANGE:
			continue
		if absf(node.position.y - p.position.y) > _PARENT_Y_RANGE:
			continue
		result.append(pid)
	return result


static func _forward_candidates(
	node: MapNode, ordered: Array[int], rank: int, map: RegionMap
) -> Array[int]:
	var result: Array[int] = []
	for next_rank: int in range(rank + 1, ordered.size()):
		var nid: int = ordered[next_rank]
		var c: MapNode = map.nodes[nid]
		var dx: float = c.position.x - node.position.x
		if dx <= 0.0 or dx > _PARENT_X_RANGE:
			continue
		if absf(node.position.y - c.position.y) > _PARENT_Y_RANGE:
			continue
		if node.next_ids.has(nid):
			continue
		result.append(nid)
	return result


static func _nearest_leftward(node: MapNode, ordered: Array[int], rank: int, map: RegionMap) -> int:
	var best_id: int = -1
	var best_dist: float = INF
	for prev_rank: int in range(rank):
		var pid: int = ordered[prev_rank]
		var d: float = map.nodes[pid].position.distance_to(node.position)
		if d < best_dist:
			best_dist = d
			best_id = pid
	return best_id


static func _link(map: RegionMap, parent_id: int, child_id: int) -> void:
	var parent: MapNode = map.nodes[parent_id]
	var child: MapNode = map.nodes[child_id]
	if parent.next_ids.has(child_id):
		return
	parent.next_ids.append(child_id)
	child.prev_ids.append(parent_id)


# Step 7: light force-directed smoothing. Entry is pinned; everyone else
# repels everyone else and is attracted along edges.
static func _smooth_layout(map: RegionMap) -> void:
	# Dictionary.keys() returns an untyped Array — assign() preserves Array[int].
	var ids: Array[int] = []
	ids.assign(map.nodes.keys())
	for _iter: int in range(_SMOOTH_ITERATIONS):
		var forces: Dictionary = {}
		for id: int in ids:
			forces[id] = Vector2.ZERO
		# Repulsion between every pair.
		for i: int in range(ids.size()):
			for j: int in range(i + 1, ids.size()):
				var a: MapNode = map.nodes[ids[i]]
				var b: MapNode = map.nodes[ids[j]]
				var delta: Vector2 = a.position - b.position
				var dist: float = maxf(delta.length(), 1.0)
				var force: Vector2 = delta.normalized() * (_SMOOTH_REPULSION / (dist * dist))
				forces[a.id] += force
				forces[b.id] -= force
		# Attraction along edges.
		for id: int in ids:
			var node: MapNode = map.nodes[id]
			for next_id: int in node.next_ids:
				var other: MapNode = map.nodes[next_id]
				var delta: Vector2 = other.position - node.position
				var dist: float = delta.length()
				var stretch: float = dist - _SMOOTH_REST_LENGTH
				var force: Vector2 = delta.normalized() * (stretch * _SMOOTH_SPRING)
				forces[id] += force
				forces[next_id] -= force
		# Apply, except entry (pinned) and clamp to play area.
		for id: int in ids:
			if id == map.entry_id:
				continue
			var node: MapNode = map.nodes[id]
			node.position += forces[id]
			node.position.x = clampf(
				node.position.x, _PLAY_AREA_RECT.position.x, _PLAY_AREA_RECT.end.x
			)
			node.position.y = clampf(
				node.position.y, _PLAY_AREA_RECT.position.y, _PLAY_AREA_RECT.end.y
			)


static func _assign_kinds(map: RegionMap, def: RegionDef, stream: RandomNumberGenerator) -> void:
	for id: int in map.nodes.keys():
		if id == map.entry_id:
			if def.starter_event_id != &"":
				map.nodes[id].kind = EventNode.Kind.EVENT
				map.nodes[id].pinned_event_id = def.starter_event_id
			else:
				map.nodes[id].kind = EventNode.Kind.COMBAT
		else:
			map.nodes[id].kind = _sample_kind(def.encounter_distribution, stream)


# Weighted-random Kind sample. Same algorithm as the previous flat-list
# generator, applied per-node.
static func _sample_kind(dist: Dictionary, stream: RandomNumberGenerator) -> int:
	var total: float = 0.0
	for kind: int in dist:
		total += float(dist[kind])
	if total <= 0.0:
		return EventNode.Kind.COMBAT
	var pick: float = stream.randf() * total
	var running: float = 0.0
	for kind: int in dist:
		running += float(dist[kind])
		if pick < running:
			return kind
	return dist.keys()[0]
