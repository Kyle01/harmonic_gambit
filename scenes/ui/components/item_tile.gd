class_name ItemTile
extends PanelContainer

var _pending_item: ItemDef = null

@onready var portrait_rect: TextureRect = $Margin/Rows/Portrait
@onready var name_label: Label = $Margin/Rows/NameLabel
@onready var description_label: Label = $Margin/Rows/DescriptionLabel


func setup(item: ItemDef) -> void:
	if is_node_ready():
		_apply(item)
	else:
		_pending_item = item


func _ready() -> void:
	if _pending_item != null:
		_apply(_pending_item)
		_pending_item = null


func _apply(item: ItemDef) -> void:
	name_label.text = item.display_name if item.display_name != "" else str(item.id)
	description_label.text = item.description
	if item.art != null:
		portrait_rect.texture = item.art
		portrait_rect.visible = true
	else:
		portrait_rect.texture = null
