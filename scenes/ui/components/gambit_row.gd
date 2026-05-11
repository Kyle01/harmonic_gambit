class_name GambitRow
extends PanelContainer

## Compact yellow row for a gambit card in the inventory list. Two columns:
## the card's display_name on the left, the trigger/target summary on the
## right.

var _pending_card: GambitCard = null

@onready var name_label: Label = $Margin/Row/NameLabel
@onready var trigger_label: Label = $Margin/Row/TriggerLabel


func setup(card: GambitCard) -> void:
	if is_node_ready():
		_apply(card)
	else:
		_pending_card = card


func _ready() -> void:
	if _pending_card != null:
		_apply(_pending_card)
		_pending_card = null


func _apply(card: GambitCard) -> void:
	name_label.text = card.display_name if card.display_name != "" else str(card.id)
	trigger_label.text = card.flavor
