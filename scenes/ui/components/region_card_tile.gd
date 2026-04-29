class_name RegionCardTile
extends PanelContainer

signal play_pressed(def: RegionDef)

const _KIND_LABELS: Dictionary = {
	EventNode.Kind.COMBAT: "Combat",
	EventNode.Kind.EVENT: "Event",
	EventNode.Kind.SHOP: "Shop",
}

var _pending_def: RegionDef = null
var _def: RegionDef = null

@onready var background_rect: TextureRect = $Margin/Rows/Background
@onready var name_label: Label = $Margin/Rows/NameLabel
@onready var description_label: Label = $Margin/Rows/DescriptionLabel
@onready var distribution_label: Label = $Margin/Rows/DistributionLabel
@onready var play_button: Button = $Margin/Rows/PlayButton


func setup(def: RegionDef) -> void:
	_def = def
	if is_node_ready():
		_apply(def)
	else:
		_pending_def = def


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	if _pending_def != null:
		_apply(_pending_def)
		_pending_def = null


func _apply(def: RegionDef) -> void:
	name_label.text = def.display_name if def.display_name != "" else str(def.id)
	description_label.text = def.description
	distribution_label.text = _format_distribution(def.encounter_distribution)
	if def.background != null:
		background_rect.texture = def.background
		background_rect.visible = true
	else:
		background_rect.texture = null
		background_rect.visible = false


func _format_distribution(dist: Dictionary) -> String:
	var total: float = 0.0
	for kind: int in dist:
		total += float(dist[kind])
	if total <= 0.0:
		return ""
	var parts: Array[String] = []
	for kind: int in dist:
		var weight: float = float(dist[kind])
		if weight <= 0.0:
			continue
		var pct: int = int(round(weight / total * 100.0))
		var label: String = _KIND_LABELS.get(kind, str(kind))
		parts.append("%s %d%%" % [label, pct])
	return " · ".join(parts)


func _on_play_pressed() -> void:
	if _def != null:
		play_pressed.emit(_def)
