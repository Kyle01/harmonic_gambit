class_name ShopItemRow
extends PanelContainer

## Compact horizontal row for shop items: icon + name + description on the
## left, price + Buy button on the right. Items never sell out, so there is
## no purchased state — Buy just deducts credits.

signal buy_pressed

var _item: ItemDef = null
var _price: int = 0

@onready var icon_rect: TextureRect = $Margin/Row/Icon
@onready var name_label: Label = $Margin/Row/TextColumn/NameLabel
@onready var description_label: Label = $Margin/Row/TextColumn/DescriptionLabel
@onready var price_label: Label = $Margin/Row/PriceColumn/PriceLabel
@onready var buy_button: Button = $Margin/Row/PriceColumn/BuyButton


func _ready() -> void:
	buy_button.pressed.connect(_on_buy_pressed)


func setup(item: ItemDef, price: int, can_afford: bool) -> void:
	if not is_node_ready():
		await ready
	_item = item
	_price = price
	name_label.text = item.display_name if item.display_name != "" else str(item.id)
	description_label.text = item.description
	if item.art != null:
		icon_rect.texture = item.art
		icon_rect.visible = true
	else:
		icon_rect.visible = false
	price_label.text = "%d credits" % price
	buy_button.disabled = not can_afford


func set_can_afford(can_afford: bool) -> void:
	buy_button.disabled = not can_afford


func _on_buy_pressed() -> void:
	buy_pressed.emit()
