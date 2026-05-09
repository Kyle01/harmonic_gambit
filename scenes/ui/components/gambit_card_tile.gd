class_name GambitCardTile
extends PanelContainer

## Monopoly-action-card style tile for gambit cards. Yellow body, dark
## border, no art — just card name and description. Same 240x420 footprint
## as BandCardTile and CharacterCardTile.

var _pending_card: GambitCard = null

@onready var name_label: Label = $Margin/Rows/NameLabel
@onready var description_label: Label = $Margin/Rows/DescriptionLabel


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
	description_label.text = card.flavor
