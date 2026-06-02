class_name AdminTheRealm
extends Control

## Realm map view. Two homes per `wire-run-start` design:
##   - Admin entry: hub tile loads this scene, we plan a fresh realm into
##     `admin_preview_realm`, traversal does not mutate `GameState`. Back
##     returns to the admin hub.
##   - Run entry: `GameState.active_realm` is non-null. We render that
##     realm; in-region traversal is the active run, kinds fire, Inventory
##     + Quit are visible; the admin Back button is hidden.
##
## `admin_preview_realm` is a static var so it persists across scene
## changes back from `RegionRunTest` within the admin path. The two homes
## deliberately never share state — admin_preview_realm is never written
## to `GameState.active_realm` and vice versa.

const ADMIN_HUB_PATH: String = "res://scenes/ui/admin_hub.tscn"
const REGION_RUN_PATH: String = "res://scenes/ui/region_run_test.tscn"
const INVENTORY_PATH: String = "res://scenes/ui/inventory.tscn"
const MAIN_MENU_PATH: String = "res://scenes/ui/main_menu.tscn"
const SELF_PATH: String = "res://scenes/ui/admin_the_realm.tscn"
const DEFAULT_REALM_DEF_PATH: String = "res://resources/realm/the_realm.tres"

const _EDGE_DEFAULT_COLOR: Color = Color(0.95, 0.93, 0.84, 0.55)
const _EDGE_VISITED_COLOR: Color = Color(0.60, 0.56, 0.48, 0.5)
const _EDGE_AVAILABLE_COLOR: Color = Color(1.0, 0.95, 0.55, 0.95)
const _EDGE_DEFAULT_WIDTH: float = 2.0
const _EDGE_AVAILABLE_WIDTH: float = 3.5

const REALM_NODE_SCENE: PackedScene = preload("res://scenes/ui/components/realm_node_button.tscn")

static var admin_preview_realm: Realm = null

var _realm: Realm = null
var _is_run: bool = false
var _controller: RealmRunController = null
var _node_buttons: Dictionary = {}  # int -> RealmNodeButton
var _catalog_by_id: Dictionary = {}  # StringName -> RegionDef

@onready var background_rect: TextureRect = $Background
@onready var edge_layer: Node2D = $EdgeLayer
@onready var node_layer: Control = $NodeLayer
@onready var title_label: Label = $TitleLabel
@onready var current_label: Label = $CurrentLabel
@onready var back_button: Button = $BackButton
@onready var inventory_button: Button = $InventoryButton
@onready var quit_button: Button = $QuitButton


func _ready() -> void:
	back_button.pressed.connect(_on_back)
	inventory_button.pressed.connect(_on_inventory_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	_load_catalog()
	_is_run = GameState.active_realm != null
	if _is_run:
		_realm = GameState.active_realm
	else:
		if admin_preview_realm == null:
			_plan_new_admin_realm()
		_realm = admin_preview_realm

	if _realm != null:
		title_label.text = _realm.def.display_name.to_upper()

	back_button.visible = not _is_run
	inventory_button.visible = _is_run
	quit_button.visible = _is_run

	_apply_background()
	_install_controller()
	_build_map()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _is_run:
			return
		_on_back()


func _load_catalog() -> void:
	_catalog_by_id.clear()
	for region: RegionDef in RegionCatalog.get_all():
		_catalog_by_id[region.id] = region


func _plan_new_admin_realm() -> void:
	var def: RealmDef = load(DEFAULT_REALM_DEF_PATH) as RealmDef
	if def == null:
		push_error("AdminTheRealm: failed to load %s" % DEFAULT_REALM_DEF_PATH)
		return
	var regions: Array[RegionDef] = RegionCatalog.get_all()
	var stream: RandomNumberGenerator = RNG.get_stream("realm")
	admin_preview_realm = RealmPlanner.plan(def, regions, stream)
	EventBus.realm_built.emit(admin_preview_realm)


func _apply_background() -> void:
	if _realm != null and _realm.def.background != null:
		background_rect.texture = _realm.def.background


func _install_controller() -> void:
	_controller = RealmRunController.new()
	_controller.set_realm(_realm)
	add_child(_controller)
	EventBus.realm_advanced.connect(_on_realm_advanced)


func _exit_tree() -> void:
	if EventBus.realm_advanced.is_connected(_on_realm_advanced):
		EventBus.realm_advanced.disconnect(_on_realm_advanced)


func _build_map() -> void:
	if _realm == null:
		return
	for node: RealmNode in _realm.nodes.values():
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
	var current_node: RealmNode = _realm.current_node()
	RegionRunTest.target_region = region
	RegionRunTest.return_to_realm = true
	RegionRunTest.is_run = _is_run
	RegionRunTest.target_realm_column = current_node.column if current_node != null else 0
	get_tree().change_scene_to_file(REGION_RUN_PATH)


func _refresh_node_states() -> void:
	if _realm == null:
		return
	var available_ids: Dictionary = {}
	for option: RealmNode in _realm.available_neighbors():
		available_ids[option.id] = true
	for id: int in _node_buttons:
		var btn: RealmNodeButton = _node_buttons[id]
		(
			btn
			. set_state(
				id == _realm.current_node_id,
				available_ids.has(id),
				_realm.visited_ids.has(id) and id != _realm.current_node_id,
			)
		)


func _refresh_current_label() -> void:
	if _realm == null or current_label == null:
		return
	var node: RealmNode = _realm.current_node()
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
	if _realm == null:
		return
	var available_ids: Dictionary = {}
	for option: RealmNode in _realm.available_neighbors():
		available_ids[option.id] = true
	var current_id: int = _realm.current_node_id
	for node: RealmNode in _realm.nodes.values():
		for next_id: int in node.next_ids:
			var line: Line2D = Line2D.new()
			line.add_point(node.position)
			line.add_point(_realm.nodes[next_id].position)
			var is_available: bool = node.id == current_id and available_ids.has(next_id)
			var both_visited: bool = (
				_realm.visited_ids.has(node.id) and _realm.visited_ids.has(next_id)
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
	# Admin path only: leaving the realm view ends the preview. Clear
	# state so re-entering replans a fresh realm.
	admin_preview_realm = null
	get_tree().change_scene_to_file(ADMIN_HUB_PATH)


func _on_inventory_pressed() -> void:
	InventoryScreen.mode = InventoryScreen.Mode.RUN
	InventoryScreen.return_path = SELF_PATH
	get_tree().change_scene_to_file(INVENTORY_PATH)


func _on_quit_pressed() -> void:
	GameState.reset_for_new_run(0)
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
