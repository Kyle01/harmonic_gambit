class_name AdminPlayableCharacters
extends Control

const ADMIN_HUB_PATH: String = "res://scenes/ui/admin_hub.tscn"
const CHARACTER_DETAIL_PATH: String = "res://scenes/ui/admin_character_detail.tscn"
const CHARACTER_DETAIL_SCRIPT = preload("res://scenes/ui/admin_character_detail.gd")
const CARD_TILE_SCENE: PackedScene = preload("res://scenes/ui/components/character_card_tile.tscn")

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
	var defs: Array[CharacterDef] = CharacterCatalog.get_all()
	empty_label.visible = defs.is_empty()
	for def: CharacterDef in defs:
		var tile: CharacterCardTile = CARD_TILE_SCENE.instantiate() as CharacterCardTile
		card_grid.add_child(tile)
		tile.setup(def)
		tile.selected.connect(_on_tile_selected)


func _on_tile_selected(def: CharacterDef) -> void:
	CHARACTER_DETAIL_SCRIPT.target_def = def
	get_tree().change_scene_to_file(CHARACTER_DETAIL_PATH)


func _back() -> void:
	get_tree().change_scene_to_file(ADMIN_HUB_PATH)
