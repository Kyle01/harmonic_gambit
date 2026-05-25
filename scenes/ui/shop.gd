class_name ShopScreen
extends Control

## Admin / dev shop screen. Renders a randomized 2x3 grid of card offers
## (3-6 actual cards, remaining slots empty) plus the full ItemCatalog as
## buyable infinite-stock rows. Credits source is the Inventory preset
## fixture (Early / Mid / Late) — no GameState mutation. Purchase state
## lives only on the screen for the visit; switching presets resets
## credits and re-rolls cards.
##
## TODO(shop-v2): replace flat 5/4 pricing + uniform-random card mix with
## a real offer generator (rarity tiers, region-aware pricing, archetype
## variants) — see scripts/ui/shop_offers.gd for the placeholder.

const ADMIN_HUB_PATH: String = "res://scenes/ui/admin_hub.tscn"
const ITEM_ROW_SCENE: PackedScene = preload("res://scenes/ui/components/shop_item_row.tscn")
const TILE_SLOT_COUNT: int = 6

var _credits: int = 0
var _card_offers: Array = []
var _item_rows: Array[ShopItemRow] = []
var _offer_tiles: Array[ShopOfferTile] = []

@onready var early_button: Button = $Root/HeaderRow/PresetRow/EarlyButton
@onready var mid_button: Button = $Root/HeaderRow/PresetRow/MidButton
@onready var late_button: Button = $Root/HeaderRow/PresetRow/LateButton
@onready var back_button: Button = $Root/HeaderRow/BackButton
@onready var credits_value: Label = $Root/HeaderRow/CreditsPanel/Margin/Row/CreditsValue
@onready var cards_grid: GridContainer = $Root/BodyRow/CardsColumn/CardsScroll/CardsGrid
@onready var items_list: VBoxContainer = $Root/BodyRow/ItemsColumn/ItemsScroll/ItemsList


func _ready() -> void:
	_offer_tiles = []
	for child: Node in cards_grid.get_children():
		if child is ShopOfferTile:
			_offer_tiles.append(child)
	for i in range(_offer_tiles.size()):
		_offer_tiles[i].buy_pressed.connect(_on_card_buy.bind(i))
	early_button.pressed.connect(_load_preset.bind(InventoryPresets.Preset.EARLY))
	mid_button.pressed.connect(_load_preset.bind(InventoryPresets.Preset.MID))
	late_button.pressed.connect(_load_preset.bind(InventoryPresets.Preset.LATE))
	back_button.pressed.connect(_back)
	_build_item_rows()
	_load_preset(InventoryPresets.Preset.EARLY)
	early_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_back()


func _load_preset(preset: InventoryPresets.Preset) -> void:
	var snap: Dictionary = InventoryPresets.get_snapshot(preset)
	_credits = snap["credits"]
	_card_offers = ShopOffers.roll_card_offers(RNG.get_stream("shop"))
	_render_cards()
	_update_credits_label()
	_refresh_buy_states()


func _build_item_rows() -> void:
	for child: Node in items_list.get_children():
		child.queue_free()
	_item_rows = []
	for offer: Dictionary in ShopOffers.item_offers():
		var row: ShopItemRow = ITEM_ROW_SCENE.instantiate() as ShopItemRow
		items_list.add_child(row)
		row.setup(offer["ref"], offer["price"], true)
		row.buy_pressed.connect(_on_item_buy.bind(offer["price"]))
		_item_rows.append(row)


func _render_cards() -> void:
	for i in range(TILE_SLOT_COUNT):
		var tile: ShopOfferTile = _offer_tiles[i]
		if i < _card_offers.size():
			tile.setup(_card_offers[i], _credits >= _card_offers[i]["price"])
		else:
			tile.setup_empty()


func _on_card_buy(index: int) -> void:
	if index < 0 or index >= _card_offers.size():
		return
	var offer: Dictionary = _card_offers[index]
	var price: int = offer["price"]
	if _credits < price:
		return
	_credits -= price
	_offer_tiles[index].mark_purchased()
	_update_credits_label()
	_refresh_buy_states()


func _on_item_buy(price: int) -> void:
	if _credits < price:
		return
	_credits -= price
	_update_credits_label()
	_refresh_buy_states()


func _refresh_buy_states() -> void:
	for i in range(_offer_tiles.size()):
		if i >= _card_offers.size():
			continue
		_offer_tiles[i].set_can_afford(_credits >= _card_offers[i]["price"])
	for row: ShopItemRow in _item_rows:
		row.set_can_afford(_credits >= ShopOffers.ITEM_PRICE)


func _update_credits_label() -> void:
	credits_value.text = str(_credits)


func _back() -> void:
	get_tree().change_scene_to_file(ADMIN_HUB_PATH)
