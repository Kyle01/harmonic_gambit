class_name ShopOfferTile
extends VBoxContainer

## Wraps a card tile (character / gambit / band) with a price label and a
## Buy button. Empty slots use setup_empty() to keep the 2x3 grid aligned
## without rendering placeholder text. On purchase the inner card flips
## to a centered "Purchased" panel and the Buy button locks out.

signal buy_pressed

const CHARACTER_TILE_SCENE: PackedScene = preload(
	"res://scenes/ui/components/character_card_tile.tscn"
)
const GAMBIT_TILE_SCENE: PackedScene = preload("res://scenes/ui/components/gambit_card_tile.tscn")
const BAND_TILE_SCENE: PackedScene = preload("res://scenes/ui/components/band_card_tile.tscn")

var _is_empty: bool = false
var _purchased: bool = false
var _price: int = 0

@onready var content_slot: Control = $ContentSlot
@onready var purchased_panel: PanelContainer = $PurchasedPanel
@onready var price_label: Label = $PriceLabel
@onready var buy_button: Button = $BuyButton


func _ready() -> void:
	buy_button.pressed.connect(_on_buy_pressed)


func setup(offer: Dictionary, can_afford: bool) -> void:
	if not is_node_ready():
		await ready
	_is_empty = false
	_purchased = false
	_price = offer["price"]
	_clear_content_slot()
	purchased_panel.visible = false
	content_slot.visible = true
	price_label.visible = true
	buy_button.visible = true
	buy_button.disabled = not can_afford
	buy_button.text = "Buy"
	price_label.text = "%d credits" % _price
	var kind: StringName = offer["kind"]
	match kind:
		&"character":
			var tile: CharacterCardTile = CHARACTER_TILE_SCENE.instantiate() as CharacterCardTile
			content_slot.add_child(tile)
			tile.setup(offer["ref"], 1)
		&"gambit":
			var tile: GambitCardTile = GAMBIT_TILE_SCENE.instantiate() as GambitCardTile
			content_slot.add_child(tile)
			tile.setup(offer["ref"])
		&"band":
			var tile: BandCardTile = BAND_TILE_SCENE.instantiate() as BandCardTile
			content_slot.add_child(tile)
			tile.setup(offer["ref"])
		_:
			push_warning("ShopOfferTile: unknown kind %s" % kind)


func setup_empty() -> void:
	if not is_node_ready():
		await ready
	_is_empty = true
	_purchased = false
	_clear_content_slot()
	content_slot.visible = false
	purchased_panel.visible = false
	price_label.visible = false
	buy_button.visible = false


func mark_purchased() -> void:
	if _is_empty:
		return
	_purchased = true
	_clear_content_slot()
	content_slot.visible = false
	purchased_panel.visible = true
	buy_button.disabled = true
	buy_button.text = "Purchased"


func set_can_afford(can_afford: bool) -> void:
	if _is_empty or _purchased:
		return
	buy_button.disabled = not can_afford


func is_purchasable() -> bool:
	return not _is_empty and not _purchased


func get_price() -> int:
	return _price


func _clear_content_slot() -> void:
	for child: Node in content_slot.get_children():
		child.queue_free()


func _on_buy_pressed() -> void:
	if not is_purchasable():
		return
	buy_pressed.emit()
