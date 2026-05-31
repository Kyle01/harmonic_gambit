class_name AdminHub
extends Control

const MAIN_MENU_PATH: String = "res://scenes/ui/main_menu.tscn"
const COMBAT_TILE_PATH: String = "res://scenes/ui/admin_combat.tscn"
const CHARACTERS_TILE_PATH: String = "res://scenes/ui/admin_playable_characters.tscn"
const BAND_CARDS_PATH: String = "res://scenes/ui/admin_band_cards.tscn"
const THE_REALM_PATH: String = "res://scenes/ui/admin_the_realm.tscn"
const REGIONS_PATH: String = "res://scenes/ui/admin_regions.tscn"
const INVENTORY_PATH: String = "res://scenes/ui/inventory.tscn"
const EVENTS_PATH: String = "res://scenes/ui/events.tscn"
const ENEMIES_PATH: String = "res://scenes/ui/enemies.tscn"
const GAMBIT_CARDS_PATH: String = "res://scenes/ui/gambit_cards.tscn"
const ITEMS_PATH: String = "res://scenes/ui/items.tscn"
const BAND_TUNING_PATH: String = "res://scenes/ui/band_tuning.tscn"
const SHOP_PATH: String = "res://scenes/ui/shop.tscn"
const GAMBIT_TUNING_PATH: String = "res://scenes/ui/gambit_tuning.tscn"
const HUB_PATH: String = "res://scenes/ui/admin_hub.tscn"

const DEV_CREDITS_BUMP: int = 50

@onready var combat_tile: Button = $TileGrid/CombatTile
@onready var characters_tile: Button = $TileGrid/PlayableCharactersTile
@onready var band_cards_tile: Button = $TileGrid/BandCardsTile
@onready var the_realm_tile: Button = $TileGrid/TheRealmTile
@onready var regions_tile: Button = $TileGrid/RegionsTile
@onready var inventory_tile: Button = $TileGrid/InventoryTile
@onready var events_tile: Button = $TileGrid/EventsTile
@onready var enemies_tile: Button = $TileGrid/EnemiesTile
@onready var gambit_cards_tile: Button = $TileGrid/GambitCardsTile
@onready var items_tile: Button = $TileGrid/ItemsTile
@onready var band_tuning_tile: Button = $TileGrid/BandTuningTile
@onready var shop_tile: Button = $TileGrid/ShopTile
@onready var back_button: Button = $BackButton

# DEV-ONLY: removed in PR3 once Start path is wired and RUN screens are
# reachable through the real run flow. PR3 grep for "DEV-PR3-REMOVE" finds
# the row in admin_hub.tscn and the handlers below.
@onready var dev_inventory_run_button: Button = $DevRow/DevInventoryRunButton
@onready var dev_shop_run_button: Button = $DevRow/DevShopRunButton
@onready var dev_band_tuning_run_button: Button = $DevRow/DevBandTuningRunButton
@onready var dev_gambit_tuning_run_button: Button = $DevRow/DevGambitTuningRunButton
@onready var dev_bump_credits_button: Button = $DevRow/DevBumpCreditsButton


func _ready() -> void:
	combat_tile.pressed.connect(_go.bind(COMBAT_TILE_PATH))
	characters_tile.pressed.connect(_go.bind(CHARACTERS_TILE_PATH))
	band_cards_tile.pressed.connect(_go.bind(BAND_CARDS_PATH))
	the_realm_tile.pressed.connect(_go.bind(THE_REALM_PATH))
	regions_tile.pressed.connect(_go.bind(REGIONS_PATH))
	inventory_tile.pressed.connect(_go.bind(INVENTORY_PATH))
	events_tile.pressed.connect(_go.bind(EVENTS_PATH))
	enemies_tile.pressed.connect(_go.bind(ENEMIES_PATH))
	gambit_cards_tile.pressed.connect(_go.bind(GAMBIT_CARDS_PATH))
	items_tile.pressed.connect(_go.bind(ITEMS_PATH))
	band_tuning_tile.pressed.connect(_go.bind(BAND_TUNING_PATH))
	shop_tile.pressed.connect(_go.bind(SHOP_PATH))
	back_button.pressed.connect(_go.bind(MAIN_MENU_PATH))
	# DEV-PR3-REMOVE
	dev_inventory_run_button.pressed.connect(_dev_open_inventory_run)
	dev_shop_run_button.pressed.connect(_dev_open_shop_run)
	dev_band_tuning_run_button.pressed.connect(_dev_open_band_tuning_run)
	dev_gambit_tuning_run_button.pressed.connect(_dev_open_gambit_tuning_run)
	dev_bump_credits_button.pressed.connect(_dev_bump_credits)
	combat_tile.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go(MAIN_MENU_PATH)


func _go(path: String) -> void:
	get_tree().change_scene_to_file(path)


# DEV-PR3-REMOVE: scaffolding that lets PR2 verify RUN-mode rendering
# before the real run flow exists. PR3 deletes both these handlers and
# the DevRow they're bound to in admin_hub.tscn.
func _dev_open_inventory_run() -> void:
	InventoryScreen.mode = InventoryScreen.Mode.RUN
	InventoryScreen.return_path = HUB_PATH
	_go(INVENTORY_PATH)


func _dev_open_shop_run() -> void:
	ShopScreen.mode = ShopScreen.Mode.RUN
	ShopScreen.return_path = HUB_PATH
	_go(SHOP_PATH)


func _dev_open_band_tuning_run() -> void:
	BandTuningScreen.mode = BandTuningScreen.Mode.RUN
	BandTuningScreen.return_path = HUB_PATH
	_go(BAND_TUNING_PATH)


func _dev_open_gambit_tuning_run() -> void:
	GambitTuningScreen.mode = GambitTuningScreen.Mode.RUN
	GambitTuningScreen.return_path = HUB_PATH
	_go(GAMBIT_TUNING_PATH)


func _dev_bump_credits() -> void:
	GameState.credits += DEV_CREDITS_BUMP
	EventBus.credits_changed.emit(GameState.credits)
