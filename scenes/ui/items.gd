class_name ItemsScreen
extends Control

const ADMIN_HUB_PATH: String = "res://scenes/ui/admin_hub.tscn"
const ITEM_TILE_SCENE: PackedScene = preload("res://scenes/ui/components/item_tile.tscn")

@onready var item_grid: GridContainer = $Scroll/ItemGrid
@onready var empty_label: Label = $EmptyLabel
@onready var back_button: Button = $BackButton


func _ready() -> void:
	back_button.pressed.connect(_back)
	_populate()
	back_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_back()


func _populate() -> void:
	var items: Array[ItemDef] = ItemCatalog.get_all()
	empty_label.visible = items.is_empty()
	for item: ItemDef in items:
		var tile: ItemTile = ITEM_TILE_SCENE.instantiate() as ItemTile
		item_grid.add_child(tile)
		tile.setup(item)


func _back() -> void:
	get_tree().change_scene_to_file(ADMIN_HUB_PATH)
