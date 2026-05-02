class_name RegionRunTest
extends Control

const ADMIN_REGIONS_PATH: String = "res://scenes/ui/admin_regions.tscn"
const MAP_NODE_SCENE: PackedScene = preload("res://scenes/ui/components/map_node_button.tscn")

const _EDGE_DEFAULT_COLOR: Color = Color(0.95, 0.93, 0.84, 0.7)
const _EDGE_VISITED_COLOR: Color = Color(0.60, 0.56, 0.48, 0.55)
const _EDGE_LOCKED_COLOR: Color = Color(0.10, 0.10, 0.12, 0.45)
const _EDGE_AVAILABLE_COLOR: Color = Color(1.0, 0.95, 0.55, 0.95)
const _EDGE_DEFAULT_WIDTH: float = 2.0
const _EDGE_AVAILABLE_WIDTH: float = 3.0

static var target_region: RegionDef = null

var _region: Region = null
var _node_buttons: Dictionary = {}  # MapNode.id (int) -> MapNodeButton
var _controller: RegionRunController = null

@onready var background_rect: TextureRect = $Background
@onready var edge_layer: Node2D = $EdgeLayer
@onready var node_layer: Control = $NodeLayer
@onready var next_region_button: Button = $NextRegionButton


func _ready() -> void:
	if target_region != null and target_region.background != null:
		background_rect.texture = target_region.background
	next_region_button.pressed.connect(_on_next_region)
	EventBus.region_advanced.connect(_on_region_advanced)
	if target_region != null:
		_build_map()
	next_region_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_next_region()


func _build_map() -> void:
	var stream: RandomNumberGenerator = RNG.get_stream("region_%s" % str(target_region.id))
	_region = RegionPlanner.plan(target_region, stream)
	_controller = RegionRunController.new()
	_controller.set_region(_region)
	add_child(_controller)
	for node: MapNode in _region.map.nodes.values():
		var button: MapNodeButton = MAP_NODE_SCENE.instantiate()
		node_layer.add_child(button)
		button.setup(node)
		button.position = node.position - (button.size * 0.5)
		button.pressed_with_id.connect(_on_node_pressed)
		_node_buttons[node.id] = button
	_redraw_edges()
	_refresh_node_states()


func _on_node_pressed(node_id: int) -> void:
	# UI emits intent on the bus; RegionRunController handles the mutation.
	EventBus.region_node_chosen.emit(node_id)


func _on_region_advanced(_prev_node_id: int, _new_node_id: int, _kind: int) -> void:
	_redraw_edges()
	_refresh_node_states()


func _refresh_node_states() -> void:
	if _region == null:
		return
	var available_ids: Dictionary = {}
	for option: MapNode in _region.available_neighbors():
		available_ids[option.id] = true
	for id: int in _node_buttons:
		var btn: MapNodeButton = _node_buttons[id]
		(
			btn
			. set_state(
				id == _region.current_node_id,
				available_ids.has(id),
				_region.visited_ids.has(id) and id != _region.current_node_id,
			)
		)


func _redraw_edges() -> void:
	for child: Node in edge_layer.get_children():
		child.queue_free()
	if _region == null:
		return
	var available_ids: Dictionary = {}
	for option: MapNode in _region.available_neighbors():
		available_ids[option.id] = true
	var current_id: int = _region.current_node_id
	for node: MapNode in _region.map.nodes.values():
		for next_id: int in node.next_ids:
			var line: Line2D = Line2D.new()
			line.add_point(node.position)
			line.add_point(_region.map.nodes[next_id].position)
			# Available = edge incident to current; the *other* endpoint is in
			# the neighbor set. Symmetric since navigation is undirected.
			var is_available: bool = (
				(node.id == current_id and available_ids.has(next_id))
				or (next_id == current_id and available_ids.has(node.id))
			)
			var both_visited: bool = (
				_region.visited_ids.has(node.id) and _region.visited_ids.has(next_id)
			)
			if is_available:
				line.default_color = _EDGE_AVAILABLE_COLOR
				line.width = _EDGE_AVAILABLE_WIDTH
			elif both_visited:
				line.default_color = _EDGE_VISITED_COLOR
				line.width = _EDGE_DEFAULT_WIDTH
			else:
				line.default_color = _EDGE_DEFAULT_COLOR
				line.width = _EDGE_DEFAULT_WIDTH
			edge_layer.add_child(line)


func _on_next_region() -> void:
	target_region = null
	get_tree().change_scene_to_file(ADMIN_REGIONS_PATH)
