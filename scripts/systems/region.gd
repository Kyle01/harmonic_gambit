class_name Region
extends RefCounted

## Runtime counterpart of RegionDef. Holds the generated RegionMap and
## the player's walk state (current node + history). Created by
## RegionPlanner.plan(). RegionDef is the template; Region is the live
## thing.
##
## There is no defined exit; the run scene shows "Go to next region" as
## an always-available escape. Termination is the player's call.

var def: RegionDef = null
var map: RegionMap = null
var current_node_id: int = -1
var visited_ids: Array[int] = []


func current_node() -> MapNode:
	if map == null or not map.nodes.has(current_node_id):
		return null
	return map.nodes[current_node_id]


func available_next() -> Array[MapNode]:
	var result: Array[MapNode] = []
	var node: MapNode = current_node()
	if node == null:
		return result
	for next_id: int in node.next_ids:
		if visited_ids.has(next_id):
			continue
		if map.nodes.has(next_id):
			result.append(map.nodes[next_id])
	return result


func advance_to(node_id: int) -> void:
	for option: MapNode in available_next():
		if option.id == node_id:
			current_node_id = node_id
			visited_ids.append(node_id)
			return


func has_started() -> bool:
	return visited_ids.size() > 1
