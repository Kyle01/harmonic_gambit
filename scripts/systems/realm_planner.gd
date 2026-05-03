class_name RealmPlanner
extends RefCounted

## Builds a runtime Realm from a RealmDef + RegionCatalog + RNG stream.
## The realm shape is fixed: 1-2-3-3-2-1 columns. Region assignment for
## the four middle columns is weighted-random; col 0 and col 5 are
## hard-coded by RealmDef.intro_region_id / finale_region_id.
##
## Edges are derived geometrically:
##   - Within each half (cols 0..3 and cols 3..5 at the boundary), nodes
##     connect via "lane segment overlap" — a source row's lane segment
##     is [row/count, (row+1)/count]; it connects to every dst row whose
##     lane segment overlaps. Cleanly produces top->{top,mid}, mid->{all},
##     bot->{mid,bot} for 2->3 fan-outs and the symmetric narrowings.
##   - Between cols 2 and 3 (the third and fourth columns), edges are
##     1:1 by row only. This is the lane lock — the player commits to a
##     path before the second half.
##
## Stateless; static-only entry points.

## Match the project viewport (1280x720). The realm map scene anchors
## full-rect, so this is the canvas the planner places nodes into.
const _CANVAS_SIZE: Vector2 = Vector2(1280, 720)
const _MARGIN_X: float = 140.0
const _MARGIN_Y: float = 120.0
const _LANE_OVERLAP_EPS: float = 1e-4


static func plan(
	def: RealmDef, catalog_regions: Array[RegionDef], stream: RandomNumberGenerator
) -> Realm:
	var realm: Realm = Realm.new()
	realm.def = def

	var by_id: Dictionary = {}
	for region_def: RegionDef in catalog_regions:
		by_id[region_def.id] = region_def

	# Step 1+2: allocate and position nodes by column/row.
	var grid: Array[Array] = []  # grid[column][row] = RealmNode
	var next_id: int = 0
	for c: int in range(RealmDef.COLUMN_COUNTS.size()):
		var count: int = RealmDef.COLUMN_COUNTS[c]
		var column_nodes: Array[RealmNode] = []
		for r: int in range(count):
			var node: RealmNode = RealmNode.new()
			node.id = next_id
			node.column = c
			node.row = r
			node.position = _layout(c, r, count)
			realm.nodes[next_id] = node
			column_nodes.append(node)
			next_id += 1
		grid.append(column_nodes)

	# Step 3: assign region ids per column.
	for c: int in range(RealmDef.COLUMN_COUNTS.size()):
		for node: RealmNode in grid[c]:
			node.region_id = _pick_region_id(def, c, by_id, stream)

	# Step 4: wire edges.
	_wire_edges(grid)

	realm.entry_id = grid[0][0].id
	realm.current_node_id = realm.entry_id
	realm.visited_ids.append(realm.entry_id)
	return realm


# Position a node at (column c, row r out of count). Columns are evenly
# spaced between the horizontal margins; rows are evenly spaced within
# each column's vertical band so a single node sits centered, two nodes
# occupy the upper/lower thirds, three nodes top/mid/bot quarters.
static func _layout(c: int, r: int, count: int) -> Vector2:
	var col_count: int = RealmDef.COLUMN_COUNTS.size()
	var x: float
	if col_count <= 1:
		x = _CANVAS_SIZE.x * 0.5
	else:
		x = _MARGIN_X + (float(c) / float(col_count - 1)) * (_CANVAS_SIZE.x - 2.0 * _MARGIN_X)
	var y: float
	if count <= 1:
		y = _CANVAS_SIZE.y * 0.5
	else:
		var span: float = _CANVAS_SIZE.y - 2.0 * _MARGIN_Y
		y = _MARGIN_Y + (float(r) / float(count - 1)) * span
	return Vector2(x, y)


# Weighted-random region pick from the appropriate column. Mirrors the
# RegionPlanner._sample_kind pattern but at the realm level. Cols 0 and
# 5 are fixed (intro / finale); cols 1..4 sample from
# def.middle_column_weights[c-1].
static func _pick_region_id(
	def: RealmDef, c: int, by_id: Dictionary, stream: RandomNumberGenerator
) -> StringName:
	if c == 0:
		_assert_in_catalog(def.intro_region_id, by_id, "intro_region_id")
		return def.intro_region_id
	if c == RealmDef.COLUMN_COUNTS.size() - 1:
		_assert_in_catalog(def.finale_region_id, by_id, "finale_region_id")
		return def.finale_region_id
	var weights: Dictionary = def.middle_column_weights[c - 1]
	var total: float = 0.0
	for v: Variant in weights.values():
		total += float(v)
	if total <= 0.0:
		push_warning("RealmPlanner: column %d has zero total weight" % c)
		return def.intro_region_id
	var pick: float = stream.randf() * total
	var running: float = 0.0
	for key: Variant in weights.keys():
		running += float(weights[key])
		if pick < running:
			var rid: StringName = StringName(str(key))
			_assert_in_catalog(rid, by_id, "middle_column_weights[%d]" % (c - 1))
			return rid
	# Fallback for floating-point edge case.
	var fallback: StringName = StringName(str(weights.keys()[weights.size() - 1]))
	_assert_in_catalog(fallback, by_id, "middle_column_weights[%d] fallback" % (c - 1))
	return fallback


static func _assert_in_catalog(rid: StringName, by_id: Dictionary, where: String) -> void:
	if not by_id.has(rid):
		push_error(
			"RealmPlanner: region id '%s' (from %s) is not in RegionCatalog" % [str(rid), where]
		)


# For each adjacent column pair: between cols 2 and 3 use 1:1 lane lock;
# everywhere else use lane-segment overlap.
static func _wire_edges(grid: Array[Array]) -> void:
	for c: int in range(grid.size() - 1):
		var src_col: Array = grid[c]
		var dst_col: Array = grid[c + 1]
		if c == 2:
			# 1:1 lock between col 2 (third column) and col 3 (fourth).
			# Cols here have 3 nodes each; row r -> row r.
			for r: int in range(src_col.size()):
				_link(src_col[r], dst_col[r])
		else:
			for src_node: RealmNode in src_col:
				var targets: Array[int] = _lane_neighbors(
					src_col.size(), dst_col.size(), src_node.row
				)
				for t: int in targets:
					_link(src_node, dst_col[t])


# Returns dst rows whose lane segment overlaps the src row's segment.
# Treat each row r in count as occupying [r/count, (r+1)/count]. A src
# segment overlaps a dst segment iff their intervals intersect.
static func _lane_neighbors(src_count: int, dst_count: int, src_row: int) -> Array[int]:
	var result: Array[int] = []
	var src_lo: float = float(src_row) / float(src_count)
	var src_hi: float = float(src_row + 1) / float(src_count)
	for r: int in range(dst_count):
		var dst_lo: float = float(r) / float(dst_count)
		var dst_hi: float = float(r + 1) / float(dst_count)
		if dst_hi > src_lo + _LANE_OVERLAP_EPS and dst_lo + _LANE_OVERLAP_EPS < src_hi:
			result.append(r)
	if result.is_empty():
		# Degenerate fallback: nearest dst row by lane center.
		var src_center: float = (src_lo + src_hi) * 0.5
		var best_r: int = 0
		var best_d: float = INF
		for r: int in range(dst_count):
			var dst_center: float = (float(r) + 0.5) / float(dst_count)
			var d: float = absf(dst_center - src_center)
			if d < best_d:
				best_d = d
				best_r = r
		result.append(best_r)
	return result


static func _link(parent: RealmNode, child: RealmNode) -> void:
	if parent.next_ids.has(child.id):
		return
	parent.next_ids.append(child.id)
	child.prev_ids.append(parent.id)
