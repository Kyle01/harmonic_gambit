class_name BandCardTile
extends PanelContainer

var _pending_card: BandCard = null

@onready var portrait_rect: TextureRect = $Margin/Rows/Portrait
@onready var name_label: Label = $Margin/Rows/NameLabel
@onready var flavor_label: Label = $Margin/Rows/FlavorLabel
@onready var effects_label: Label = $Margin/Rows/EffectsLabel
@onready var requires_label: Label = $Margin/Rows/RequiresLabel


func setup(card: BandCard) -> void:
	if is_node_ready():
		_apply(card)
	else:
		_pending_card = card


func _ready() -> void:
	if _pending_card != null:
		_apply(_pending_card)
		_pending_card = null


func _apply(card: BandCard) -> void:
	name_label.text = card.display_name if card.display_name != "" else str(card.id)
	flavor_label.text = card.flavor
	effects_label.text = " · ".join(card.applied_effects)
	if card.activation_requirements.is_empty():
		requires_label.text = ""
		requires_label.visible = false
	else:
		requires_label.text = "Requires: " + ", ".join(card.activation_requirements)
		requires_label.visible = true
	if card.art != null:
		portrait_rect.texture = card.art
		portrait_rect.visible = true
	else:
		portrait_rect.texture = null
