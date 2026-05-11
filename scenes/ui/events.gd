class_name EventsScreen
extends Control

const ADMIN_HUB_PATH: String = "res://scenes/ui/admin_hub.tscn"
const EVENT_RUN_DEMO_PATH: String = "res://scenes/ui/event_run_demo.tscn"
const EVENT_TILE_SCENE: PackedScene = preload("res://scenes/ui/components/event_card_tile.tscn")

@onready var card_grid: GridContainer = $Scroll/CardGrid
@onready var empty_label: Label = $EmptyLabel
@onready var back_button: Button = $BackButton


func _ready() -> void:
	back_button.pressed.connect(_back)
	_populate()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_back()


func _populate() -> void:
	var defs: Array[EventDef] = EventCatalog.get_all()
	empty_label.visible = defs.is_empty()
	for def: EventDef in defs:
		var tile: EventCardTile = EVENT_TILE_SCENE.instantiate() as EventCardTile
		card_grid.add_child(tile)
		tile.setup(def)
		tile.play_pressed.connect(_on_play_pressed)


func _on_play_pressed(def: EventDef) -> void:
	EventRunDemo.target_event = def
	get_tree().change_scene_to_file(EVENT_RUN_DEMO_PATH)


func _back() -> void:
	get_tree().change_scene_to_file(ADMIN_HUB_PATH)
