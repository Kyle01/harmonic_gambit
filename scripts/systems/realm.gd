class_name Realm
extends Resource

## Runtime counterpart of RealmDef. Holds the generated graph of
## RealmNodes and the player's run state (current node + history).
## Created by RealmPlanner.plan(). RealmDef is the template; Realm is
## the live thing. Mutated by RealmRunController in response to
## EventBus signals — UI never calls advance_to() directly.
##
## Navigation is forward-only along next_ids. Unlike Region's
## undirected walk, the Realm does not allow backtracking — committing
## to a region means the run flows forward through the realm.
##
## Resource (not RefCounted) per CLAUDE.md migrability rule.

@export var def: RealmDef = null
@export var nodes: Dictionary = {}  # int -> RealmNode
@export var entry_id: int = 0
@export var current_node_id: int = -1
@export var visited_ids: Array[int] = []


func current_node() -> RealmNode:
	if not nodes.has(current_node_id):
		return null
	return nodes[current_node_id]


func available_neighbors() -> Array[RealmNode]:
	var result: Array[RealmNode] = []
	var node: RealmNode = current_node()
	if node == null:
		return result
	for next_id: int in node.next_ids:
		if nodes.has(next_id):
			result.append(nodes[next_id])
	return result


func advance_to(node_id: int) -> bool:
	for option: RealmNode in available_neighbors():
		if option.id == node_id:
			current_node_id = node_id
			if not visited_ids.has(node_id):
				visited_ids.append(node_id)
			return true
	return false


func is_at_finale() -> bool:
	var node: RealmNode = current_node()
	if node == null:
		return false
	return node.next_ids.is_empty()
