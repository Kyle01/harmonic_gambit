class_name AdminBandCards
extends Control

const ADMIN_HUB_PATH: String = "res://scenes/ui/admin_hub.tscn"
const CARD_TILE_SCENE: PackedScene = preload("res://scenes/ui/components/band_card_tile.tscn")

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
	var cards: Array[BandCard] = BandCardCatalog.get_all()
	empty_label.visible = cards.is_empty()
	for card: BandCard in cards:
		var tile: BandCardTile = CARD_TILE_SCENE.instantiate() as BandCardTile
		card_grid.add_child(tile)
		tile.setup(card)


func _back() -> void:
	get_tree().change_scene_to_file(ADMIN_HUB_PATH)
