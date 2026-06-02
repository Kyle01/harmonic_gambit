class_name RegionRunTest
extends Control

const ADMIN_REGIONS_PATH: String = "res://scenes/ui/admin_regions.tscn"
const ADMIN_THE_REALM_PATH: String = "res://scenes/ui/admin_the_realm.tscn"
const MAIN_MENU_PATH: String = "res://scenes/ui/main_menu.tscn"
const EVENT_RUNNER_PATH: String = "res://scenes/ui/event_runner.tscn"
const SHOP_PATH: String = "res://scenes/ui/shop.tscn"
const COMBAT_ARENA_PATH: String = "res://scenes/ui/combat_arena.tscn"
const INVENTORY_PATH: String = "res://scenes/ui/inventory.tscn"
const SELF_PATH: String = "res://scenes/ui/region_run_test.tscn"
const MAP_NODE_SCENE: PackedScene = preload("res://scenes/ui/components/map_node_button.tscn")

const INTRO_EVENT_ID: StringName = &"the_awakening"

const _EDGE_DEFAULT_COLOR: Color = Color(0.95, 0.93, 0.84, 0.7)
const _EDGE_VISITED_COLOR: Color = Color(0.60, 0.56, 0.48, 0.55)
const _EDGE_LOCKED_COLOR: Color = Color(0.10, 0.10, 0.12, 0.45)
const _EDGE_AVAILABLE_COLOR: Color = Color(1.0, 0.95, 0.55, 0.95)
const _EDGE_DEFAULT_WIDTH: float = 2.0
const _EDGE_AVAILABLE_WIDTH: float = 3.0

static var target_region: RegionDef = null
## When true, "Go to next region" returns to the realm map. Set both by
## admin_the_realm (for in-realm region preview) and by the run start
## path. Independent of whether the traversal is an active run.
static var return_to_realm: bool = false
## When true, this traversal is part of an active run: EVENT/SHOP/COMBAT
## kinds auto-fire on entry, Inventory + Quit buttons are visible, and
## the event applier may mutate GameState. False for admin previewing,
## where the map is shown but kinds never fire.
static var is_run: bool = false
## Realm column the active region sits in. Drives EventDef column-effect
## scaling for EVENT-kind nodes. Set by whichever caller launches this
## scene (admin_the_realm in run mode, main_menu for the_introduction).
static var target_realm_column: int = 0
## Persisted Region instance so that side-trips into event_runner / shop /
## combat — each a scene change away — don't replan the map on return.
## Reused when target_region matches; cleared when the run leaves this
## region entirely (Next or Quit).
static var active_region: Region = null

var _region: Region = null
var _node_buttons: Dictionary = {}  # MapNode.id (int) -> MapNodeButton
var _controller: RegionRunController = null
## True on the first _build_map of a freshly-planned region; false when
## _build_map reuses an existing active_region (i.e., we're returning from
## a side-trip into event_runner / shop / combat). Gates the auto-fire of
## the entry node's kind so it triggers exactly once per region run.
var _is_fresh_region: bool = false

@onready var background_rect: TextureRect = $Background
@onready var edge_layer: Node2D = $EdgeLayer
@onready var node_layer: Control = $NodeLayer
@onready var next_region_button: Button = $NextRegionButton
@onready var inventory_button: Button = $InventoryButton
@onready var quit_button: Button = $QuitButton


func _ready() -> void:
	if target_region != null and target_region.background != null:
		background_rect.texture = target_region.background
	next_region_button.pressed.connect(_on_next_region)
	inventory_button.pressed.connect(_on_inventory_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	EventBus.region_advanced.connect(_on_region_advanced)
	inventory_button.visible = is_run
	quit_button.visible = is_run
	if target_region != null:
		_build_map()
	next_region_button.grab_focus()
	# Defer to next idle frame so the scene is fully in-tree before we
	# potentially trigger another change_scene_to_file for the entry kind.
	if is_run:
		call_deferred("_route_entry_on_load")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_next_region()


func _build_map() -> void:
	if active_region != null and active_region.def == target_region:
		_region = active_region
		_is_fresh_region = false
	else:
		var stream: RandomNumberGenerator = RNG.get_stream("region_%s" % str(target_region.id))
		_region = RegionPlanner.plan(target_region, stream)
		active_region = _region
		_is_fresh_region = true
	_controller = RegionRunController.new()
	_controller.set_region(_region)
	add_child(_controller)
	for node: MapNode in _region.map.nodes.values():
		var button: MapNodeButton = MAP_NODE_SCENE.instantiate()
		node_layer.add_child(button)
		button.setup(node)
		button.position = node.position - (button.size * 0.5)
		button.node_pressed.connect(_on_node_pressed)
		_node_buttons[node.id] = button
	_redraw_edges()
	_refresh_node_states()


func _route_entry_on_load() -> void:
	# Auto-fire the entry node's kind so the player drops straight into
	# their first encounter instead of "skipping" the first node. Only
	# fires on a fresh region plan — re-entries from event_runner / shop
	# / combat reuse the same Region instance and skip this path so we
	# don't re-trigger the entry kind on return.
	if _region == null or not _is_fresh_region:
		return
	var entry_id: int = _region.current_node_id
	var entry_node: MapNode = _region.map.nodes.get(entry_id)
	if entry_node == null:
		return
	_route_kind_node(entry_node.kind, entry_id)


func _on_node_pressed(node_id: int) -> void:
	# UI emits intent on the bus; RegionRunController handles the mutation.
	EventBus.region_node_chosen.emit(node_id)


func _on_region_advanced(_prev_node_id: int, new_node_id: int, kind: int) -> void:
	_redraw_edges()
	_refresh_node_states()
	if is_run:
		_route_kind_node(kind, new_node_id)


func _route_kind_node(kind: int, node_id: int) -> void:
	match kind:
		EventNode.Kind.EVENT:
			_launch_event(node_id)
		EventNode.Kind.SHOP:
			_launch_shop()
		EventNode.Kind.COMBAT:
			_launch_combat()


func _launch_event(node_id: int) -> void:
	var forced_id: StringName = _region.forced_event_for(node_id)
	var event_id: StringName = forced_id if forced_id != &"" else _pick_random_non_intro_event()
	if event_id == &"":
		return
	if event_id == INTRO_EVENT_ID and GameState.intro_fired:
		return  # the_awakening fires once per run; revisits to entry are silent
	EventRunner.target_event_id = event_id
	EventRunner.target_column = target_realm_column
	EventRunner.return_path = SELF_PATH
	get_tree().change_scene_to_file(EVENT_RUNNER_PATH)


func _launch_shop() -> void:
	ShopScreen.mode = ShopScreen.Mode.RUN
	ShopScreen.return_path = SELF_PATH
	get_tree().change_scene_to_file(SHOP_PATH)


func _launch_combat() -> void:
	CombatSkipOverlay.return_path = SELF_PATH
	get_tree().change_scene_to_file(COMBAT_ARENA_PATH)


func _pick_random_non_intro_event() -> StringName:
	var pool: Array[EventDef] = []
	for ev: EventDef in EventCatalog.get_all():
		if ev.id == INTRO_EVENT_ID:
			continue
		pool.append(ev)
	if pool.is_empty():
		push_error("RegionRunTest: no non-intro events available in EventCatalog")
		return &""
	var stream: RandomNumberGenerator = RNG.get_stream("event_pick")
	var idx: int = stream.randi() % pool.size()
	return pool[idx].id


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
				_region.visited_ids.has(id),
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


func _on_inventory_pressed() -> void:
	InventoryScreen.mode = InventoryScreen.Mode.RUN
	InventoryScreen.return_path = SELF_PATH
	get_tree().change_scene_to_file(INVENTORY_PATH)


func _on_quit_pressed() -> void:
	active_region = null
	target_region = null
	target_realm_column = 0
	return_to_realm = false
	is_run = false
	GameState.reset_for_new_run(0)
	get_tree().change_scene_to_file(MAIN_MENU_PATH)


func _on_next_region() -> void:
	target_region = null
	active_region = null
	var was_run: bool = is_run
	is_run = false
	if return_to_realm:
		return_to_realm = false
		EventBus.realm_region_completed.emit()
		if was_run:
			_handle_run_region_complete_to_realm()
		else:
			get_tree().change_scene_to_file(ADMIN_THE_REALM_PATH)
		return
	get_tree().change_scene_to_file(ADMIN_REGIONS_PATH)


func _handle_run_region_complete_to_realm() -> void:
	# First completion (the_introduction) plants a fresh realm onto
	# GameState. Subsequent completions step back into the existing realm
	# the player already started navigating.
	if GameState.active_realm == null:
		var def: RealmDef = load("res://resources/realm/the_realm.tres") as RealmDef
		if def == null:
			push_error("RegionRunTest: failed to load default RealmDef")
			get_tree().change_scene_to_file(MAIN_MENU_PATH)
			return
		var regions: Array[RegionDef] = RegionCatalog.get_all()
		var stream: RandomNumberGenerator = RNG.get_stream("realm")
		GameState.active_realm = RealmPlanner.plan(def, regions, stream)
	get_tree().change_scene_to_file(ADMIN_THE_REALM_PATH)
