class_name AdminHub
extends Control

const MAIN_MENU_PATH: String = "res://scenes/ui/main_menu.tscn"
const COMBAT_TILE_PATH: String = "res://scenes/ui/admin_combat.tscn"
const CHARACTERS_TILE_PATH: String = "res://scenes/ui/admin_playable_characters.tscn"
const BAND_CARDS_PATH: String = "res://scenes/ui/admin_band_cards.tscn"
const THE_REALM_PATH: String = "res://scenes/ui/admin_the_realm.tscn"
const REGIONS_PATH: String = "res://scenes/ui/admin_regions.tscn"

@onready var combat_tile: Button = $TileGrid/CombatTile
@onready var characters_tile: Button = $TileGrid/PlayableCharactersTile
@onready var band_cards_tile: Button = $TileGrid/BandCardsTile
@onready var the_realm_tile: Button = $TileGrid/TheRealmTile
@onready var regions_tile: Button = $TileGrid/RegionsTile
@onready var back_button: Button = $BackButton


func _ready() -> void:
	combat_tile.pressed.connect(_go.bind(COMBAT_TILE_PATH))
	characters_tile.pressed.connect(_go.bind(CHARACTERS_TILE_PATH))
	band_cards_tile.pressed.connect(_go.bind(BAND_CARDS_PATH))
	the_realm_tile.pressed.connect(_go.bind(THE_REALM_PATH))
	regions_tile.pressed.connect(_go.bind(REGIONS_PATH))
	back_button.pressed.connect(_go.bind(MAIN_MENU_PATH))
	combat_tile.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go(MAIN_MENU_PATH)


func _go(path: String) -> void:
	get_tree().change_scene_to_file(path)
