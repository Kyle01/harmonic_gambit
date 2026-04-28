class_name AdminRegions
extends Control

const ADMIN_HUB_PATH: String = "res://scenes/ui/admin_hub.tscn"
const REGION_RUN_PATH: String = "res://scenes/ui/region_run_test.tscn"
const REGION_TILE_SCENE: PackedScene = preload("res://scenes/ui/components/region_card_tile.tscn")

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
	var defs: Array[RegionDef] = RegionCatalog.get_all()
	empty_label.visible = defs.is_empty()
	for def: RegionDef in defs:
		var tile: RegionCardTile = REGION_TILE_SCENE.instantiate() as RegionCardTile
		card_grid.add_child(tile)
		tile.setup(def)
		tile.play_pressed.connect(_on_play_pressed)


func _on_play_pressed(def: RegionDef) -> void:
	RegionRunTest.target_region = def
	get_tree().change_scene_to_file(REGION_RUN_PATH)


func _back() -> void:
	get_tree().change_scene_to_file(ADMIN_HUB_PATH)
