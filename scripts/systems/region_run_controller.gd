class_name RegionRunController
extends Node

## System-layer mediator for region-run state. Listens on
## EventBus.region_node_chosen (player intent), validates against the
## active Region, mutates run state via Region.advance_to, and emits
## EventBus.region_advanced so any subscriber (UI redraw, music,
## telemetry, save state, achievements) can react.
##
## The architecture rule is "UI never mutates state directly"; this
## controller is what holds that line. The run scene instantiates one,
## hands it the planned Region, and only ever emits intent on the bus.
## EventBus is an autoload (effectively forever-lived), so we explicitly
## disconnect on _exit_tree to avoid stale handlers surviving scene
## churn and double-firing region-advance.

var region: Region = null


func set_region(r: Region) -> void:
	region = r


func _ready() -> void:
	EventBus.region_node_chosen.connect(_on_node_chosen)


func _exit_tree() -> void:
	if EventBus.region_node_chosen.is_connected(_on_node_chosen):
		EventBus.region_node_chosen.disconnect(_on_node_chosen)


func _on_node_chosen(node_id: int) -> void:
	if region == null:
		return
	var prev_id: int = region.current_node_id
	var found: bool = false
	for option: MapNode in region.available_neighbors():
		if option.id == node_id:
			found = true
			break
	if not found:
		return
	region.advance_to(node_id)
	var kind: int = region.current_node().kind
	EventBus.region_advanced.emit(prev_id, node_id, kind)
