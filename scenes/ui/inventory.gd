class_name InventoryScreen
extends Control

const ADMIN_HUB_PATH: String = "res://scenes/ui/admin_hub.tscn"
const CHARACTER_TILE: PackedScene = preload("res://scenes/ui/components/character_card_tile.tscn")
const GAMBIT_TILE: PackedScene = preload("res://scenes/ui/components/gambit_card_tile.tscn")
const BAND_TILE: PackedScene = preload("res://scenes/ui/components/band_card_tile.tscn")
const ITEM_TILE: PackedScene = preload("res://scenes/ui/components/item_tile.tscn")

@onready var early_button: Button = $PresetRow/EarlyButton
@onready var mid_button: Button = $PresetRow/MidButton
@onready var late_button: Button = $PresetRow/LateButton
@onready var credits_value: Label = $HeaderStrip/CreditsPanel/Margin/Rows/CreditsValue
@onready var chips_value: Label = $HeaderStrip/ChipsPanel/Margin/Rows/ChipsValue
@onready var characters_grid: GridContainer = $Scroll/SectionsBox/CharactersSection/CharactersGrid
@onready var gambit_grid: GridContainer = $Scroll/SectionsBox/GambitCardsSection/GambitCardsGrid
@onready var band_grid: GridContainer = $Scroll/SectionsBox/BandCardsSection/BandCardsGrid
@onready var items_grid: GridContainer = $Scroll/SectionsBox/ItemsSection/ItemsGrid
@onready var back_button: Button = $BackButton


func _ready() -> void:
	early_button.pressed.connect(_load_preset.bind(InventoryPresets.Preset.EARLY))
	mid_button.pressed.connect(_load_preset.bind(InventoryPresets.Preset.MID))
	late_button.pressed.connect(_load_preset.bind(InventoryPresets.Preset.LATE))
	back_button.pressed.connect(_back)
	_load_preset(InventoryPresets.Preset.EARLY)
	early_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_back()


func _load_preset(preset: InventoryPresets.Preset) -> void:
	var snap: Dictionary = InventoryPresets.get_snapshot(preset)
	_render(snap)


func _render(snap: Dictionary) -> void:
	_clear(characters_grid)
	_clear(gambit_grid)
	_clear(band_grid)
	_clear(items_grid)

	credits_value.text = str(snap["credits"])
	chips_value.text = str(snap["chips"])

	for entry: Dictionary in snap["characters"]:
		var def: CharacterDef = entry["def"]
		if def == null:
			continue
		var tile: CharacterCardTile = CHARACTER_TILE.instantiate() as CharacterCardTile
		characters_grid.add_child(tile)
		tile.setup(def, entry["level"])

	for gambit: GambitCard in snap["gambit_cards"]:
		var gt: GambitCardTile = GAMBIT_TILE.instantiate() as GambitCardTile
		gambit_grid.add_child(gt)
		gt.setup(gambit)

	for band: BandCard in snap["band_cards"]:
		var bt: BandCardTile = BAND_TILE.instantiate() as BandCardTile
		band_grid.add_child(bt)
		bt.setup(band)

	for item: ItemDef in snap["items"]:
		var it: ItemTile = ITEM_TILE.instantiate() as ItemTile
		items_grid.add_child(it)
		it.setup(item)


func _clear(grid: GridContainer) -> void:
	for child: Node in grid.get_children():
		child.queue_free()


func _back() -> void:
	get_tree().change_scene_to_file(ADMIN_HUB_PATH)
