class_name ItemIcon
extends Control

## Compact item slot: a 32x32 art square with an optional ×N count badge
## in the bottom-right corner. Used in the inventory's Items section to
## stack duplicates.

var _pending_item: ItemDef = null
var _pending_count: int = 1

@onready var portrait: TextureRect = $Portrait
@onready var badge: Label = $Badge


func setup(item: ItemDef, count: int = 1) -> void:
	if is_node_ready():
		_apply(item, count)
	else:
		_pending_item = item
		_pending_count = count


func _ready() -> void:
	if _pending_item != null:
		_apply(_pending_item, _pending_count)
		_pending_item = null


func _apply(item: ItemDef, count: int) -> void:
	portrait.texture = item.art
	if count > 1:
		badge.text = "×%d" % count
		badge.visible = true
	else:
		badge.text = ""
		badge.visible = false
