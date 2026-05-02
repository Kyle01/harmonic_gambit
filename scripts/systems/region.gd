class_name Region
extends Resource

## Runtime counterpart of RegionDef. Holds the generated RegionMap and
## the player's walk state (current node + history). Created by
## RegionPlanner.plan(). RegionDef is the template; Region is the live
## thing. Mutated by RegionRunController in response to EventBus
## signals — UI never calls advance_to() directly.
##
## Navigation is undirected: from the current node you can move to any
## connected neighbor (forward or backward), and visited nodes can be
## revisited. The DAG structure in MapNode.next_ids / prev_ids only
## defines the visual layout flow and the planner's left->right depth
## ordering — it does not constrain the player's walk.
##
## There is no defined exit; the run scene shows "Go to next region" as
## an always-available escape. Termination is the player's call.
##
## Resource (not RefCounted) per CLAUDE.md migrability rule. Methods
## are pure interpretation of the held state — same precedent as
## CharacterDef.stat_at_level.

var def: RegionDef = null
var map: RegionMap = null
var current_node_id: int = -1
var visited_ids: Array[int] = []


func current_node() -> MapNode:
	if map == null or not map.nodes.has(current_node_id):
		return null
	return map.nodes[current_node_id]


func available_neighbors() -> Array[MapNode]:
	var result: Array[MapNode] = []
	var node: MapNode = current_node()
	if node == null:
		return result
	var seen: Dictionary = {}
	for neighbor_id: int in node.next_ids:
		if seen.has(neighbor_id):
			continue
		seen[neighbor_id] = true
		if map.nodes.has(neighbor_id):
			result.append(map.nodes[neighbor_id])
	for neighbor_id: int in node.prev_ids:
		if seen.has(neighbor_id):
			continue
		seen[neighbor_id] = true
		if map.nodes.has(neighbor_id):
			result.append(map.nodes[neighbor_id])
	return result


func advance_to(node_id: int) -> void:
	for option: MapNode in available_neighbors():
		if option.id == node_id:
			current_node_id = node_id
			if not visited_ids.has(node_id):
				visited_ids.append(node_id)
			return


func has_started() -> bool:
	return visited_ids.size() > 1
