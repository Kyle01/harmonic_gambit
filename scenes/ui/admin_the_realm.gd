class_name AdminTheRealm
extends Control

## Realm map view. Renders the run-level meta-map (12 nodes in 1-2-3-3-2-1
## columns) over an abstract color-field background. Player picks a
## reachable next node; we advance the realm and dispatch the chosen
## region into RegionRunTest. When that region finishes, control returns
## here for the next pick.
##
## admin_preview_realm is a static var so it persists across scene changes back
## from RegionRunTest. Same cross-scene-state pattern RegionRunTest uses
## for target_region.

const ADMIN_HUB_PATH: String = "res://scenes/ui/admin_hub.tscn"
const REGION_RUN_PATH: String = "res://scenes/ui/region_run_test.tscn"
const DEFAULT_REALM_DEF_PATH: String = "res://resources/realm/the_realm.tres"

const _EDGE_DEFAULT_COLOR: Color = Color(0.95, 0.93, 0.84, 0.55)
const _EDGE_VISITED_COLOR: Color = Color(0.60, 0.56, 0.48, 0.5)
const _EDGE_AVAILABLE_COLOR: Color = Color(1.0, 0.95, 0.55, 0.95)
const _EDGE_DEFAULT_WIDTH: float = 2.0
const _EDGE_AVAILABLE_WIDTH: float = 3.5

const REALM_NODE_SCENE: PackedScene = preload("res://scenes/ui/components/realm_node_button.tscn")

## Admin-tile preview realm. Planned fresh on each admin-hub entry,
## persists across scene changes back from RegionRunTest within the
## admin path, and is cleared on Back to admin hub. The run-path realm
## lives on `GameState.active_realm` and is wired up in PR3 — these
## two homes deliberately never share state.
static var admin_preview_realm: Realm = null

var _controller: RealmRunController = null
var _node_buttons: Dictionary = {}  # int -> RealmNodeButton
var _catalog_by_id: Dictionary = {}  # StringName -> RegionDef

@onready var background_rect: TextureRect = $Background
@onready var edge_layer: Node2D = $EdgeLayer
@onready var node_layer: Control = $NodeLayer
@onready var title_label: Label = $TitleLabel
@onready var current_label: Label = $CurrentLabel
@onready var back_button: Button = $BackButton


func _ready() -> void:
	back_button.pressed.connect(_on_back)

	_load_catalog()
	if admin_preview_realm == null:
		_plan_new_realm()
	else:
		title_label.text = admin_preview_realm.def.display_name.to_upper()

	_apply_background()
	_install_controller()
	_build_map()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back()


func _load_catalog() -> void:
	_catalog_by_id.clear()
	for region: RegionDef in RegionCatalog.get_all():
		_catalog_by_id[region.id] = region


func _plan_new_realm() -> void:
	var def: RealmDef = load(DEFAULT_REALM_DEF_PATH) as RealmDef
	if def == null:
		push_error("AdminTheRealm: failed to load %s" % DEFAULT_REALM_DEF_PATH)
		return
	var regions: Array[RegionDef] = RegionCatalog.get_all()
	var stream: RandomNumberGenerator = RNG.get_stream("realm")
	admin_preview_realm = RealmPlanner.plan(def, regions, stream)
	title_label.text = def.display_name.to_upper()
	EventBus.realm_built.emit(admin_preview_realm)


func _apply_background() -> void:
	if admin_preview_realm != null and admin_preview_realm.def.background != null:
		background_rect.texture = admin_preview_realm.def.background


func _install_controller() -> void:
	_controller = RealmRunController.new()
	_controller.set_realm(admin_preview_realm)
	add_child(_controller)
	EventBus.realm_advanced.connect(_on_realm_advanced)


func _exit_tree() -> void:
	if EventBus.realm_advanced.is_connected(_on_realm_advanced):
		EventBus.realm_advanced.disconnect(_on_realm_advanced)


func _build_map() -> void:
	if admin_preview_realm == null:
		return
	for node: RealmNode in admin_preview_realm.nodes.values():
		var region: RegionDef = _catalog_by_id.get(node.region_id, null)
		var button: RealmNodeButton = REALM_NODE_SCENE.instantiate()
		node_layer.add_child(button)
		button.setup(node, region)
		button.position = node.position - (button.size * 0.5)
		button.node_pressed.connect(_on_node_pressed)
		_node_buttons[node.id] = button
	_redraw_edges()
	_refresh_node_states()
	_refresh_current_label()


func _on_node_pressed(node_id: int) -> void:
	# UI emits intent on the bus; RealmRunController validates and
	# advances. We listen to realm_advanced (below) for the result.
	EventBus.realm_node_chosen.emit(node_id)


func _on_realm_advanced(_prev_id: int, _new_id: int, region_id: StringName) -> void:
	_redraw_edges()
	_refresh_node_states()
	_refresh_current_label()
	# Hand control to the in-region run for the new region. When the
	# player completes that region, RegionRunTest returns us here.
	var region: RegionDef = _catalog_by_id.get(region_id, null)
	if region == null:
		push_warning("AdminTheRealm: chosen region '%s' not in catalog" % str(region_id))
		return
	RegionRunTest.target_region = region
	RegionRunTest.return_to_realm = true
	get_tree().change_scene_to_file(REGION_RUN_PATH)


func _refresh_node_states() -> void:
	if admin_preview_realm == null:
		return
	var available_ids: Dictionary = {}
	for option: RealmNode in admin_preview_realm.available_neighbors():
		available_ids[option.id] = true
	for id: int in _node_buttons:
		var btn: RealmNodeButton = _node_buttons[id]
		(
			btn
			. set_state(
				id == admin_preview_realm.current_node_id,
				available_ids.has(id),
				(
					admin_preview_realm.visited_ids.has(id)
					and id != admin_preview_realm.current_node_id
				),
			)
		)


func _refresh_current_label() -> void:
	if admin_preview_realm == null or current_label == null:
		return
	var node: RealmNode = admin_preview_realm.current_node()
	if node == null:
		current_label.text = ""
		return
	var region: RegionDef = _catalog_by_id.get(node.region_id, null)
	if region == null:
		current_label.text = str(node.region_id)
	else:
		current_label.text = region.display_name


func _redraw_edges() -> void:
	for child: Node in edge_layer.get_children():
		child.queue_free()
	if admin_preview_realm == null:
		return
	var available_ids: Dictionary = {}
	for option: RealmNode in admin_preview_realm.available_neighbors():
		available_ids[option.id] = true
	var current_id: int = admin_preview_realm.current_node_id
	for node: RealmNode in admin_preview_realm.nodes.values():
		for next_id: int in node.next_ids:
			var line: Line2D = Line2D.new()
			line.add_point(node.position)
			line.add_point(admin_preview_realm.nodes[next_id].position)
			var is_available: bool = node.id == current_id and available_ids.has(next_id)
			var both_visited: bool = (
				admin_preview_realm.visited_ids.has(node.id)
				and admin_preview_realm.visited_ids.has(next_id)
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


func _on_back() -> void:
	# Leaving the realm view ends the run. Clear state so re-entering
	# replans a fresh realm.
	admin_preview_realm = null
	get_tree().change_scene_to_file(ADMIN_HUB_PATH)
