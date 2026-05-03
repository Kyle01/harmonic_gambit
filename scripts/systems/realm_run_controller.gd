class_name RealmRunController
extends Node

## System-layer mediator for realm-run state. Listens on
## EventBus.realm_node_chosen (player intent), validates against the
## active Realm, mutates run state via Realm.advance_to, and emits
## EventBus.realm_advanced so any subscriber (UI redraw, music,
## telemetry, save state) can react.
##
## Mirrors RegionRunController, but at the run-level above Region.
## EventBus is an autoload; we explicitly disconnect on _exit_tree to
## avoid stale handlers surviving scene churn.

var realm: Realm = null


func set_realm(r: Realm) -> void:
	realm = r


func _ready() -> void:
	EventBus.realm_node_chosen.connect(_on_node_chosen)


func _exit_tree() -> void:
	if EventBus.realm_node_chosen.is_connected(_on_node_chosen):
		EventBus.realm_node_chosen.disconnect(_on_node_chosen)


func _on_node_chosen(node_id: int) -> void:
	if realm == null:
		return
	var prev_id: int = realm.current_node_id
	if not realm.advance_to(node_id):
		return
	var node: RealmNode = realm.current_node()
	EventBus.realm_advanced.emit(prev_id, node_id, node.region_id)
