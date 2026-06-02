class_name EventCardTile
extends PanelContainer

## Catalog tile for the admin Events grid. Renders an event's title + hook +
## scope (region / column) and exposes a Play button that emits play_pressed
## so the parent screen can launch the demo runner.

signal play_pressed(def: EventDef)

const _ALL_REGIONS: Array[StringName] = [
	&"the_introduction",
	&"the_city",
	&"the_expanse",
	&"the_depths",
	&"the_warp",
	&"the_finale",
]
const _ALL_COLUMNS: Array[int] = [0, 1, 2, 3, 4, 5]

var _pending_def: EventDef = null
var _def: EventDef = null

@onready var name_label: Label = $Margin/Rows/NameLabel
@onready var description_label: Label = $Margin/Rows/DescriptionLabel
@onready var scope_label: Label = $Margin/Rows/ScopeLabel
@onready var coeff_label: Label = $Margin/Rows/CoeffLabel
@onready var play_button: Button = $Margin/Rows/PlayButton


func setup(def: EventDef) -> void:
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


func _apply(def: EventDef) -> void:
	name_label.text = def.display_name if def.display_name != "" else str(def.id)
	description_label.text = def.description
	scope_label.text = _format_scope(def)
	coeff_label.text = "Column scaling: ×%.2f" % def.column_effect_multiplier


func _format_scope(def: EventDef) -> String:
	# Empty findable arrays = the event can only fire via a forced reference
	# (e.g. RegionDef.forced_entry_event_id). The random picker skips it.
	if def.findable_regions.is_empty() and def.findable_columns.is_empty():
		return "pinned (never random)"
	var region_text: String = "any region"
	if not _is_full_region_set(def.findable_regions):
		region_text = ", ".join(def.findable_regions.map(_humanize_region))
	var column_text: String = "any column"
	if not _is_full_column_set(def.findable_columns):
		var cols: Array[String] = []
		for c: int in def.findable_columns:
			cols.append(str(c))
		column_text = "col " + ", ".join(cols)
	return "%s · %s" % [region_text, column_text]


func _is_full_region_set(regions: Array[StringName]) -> bool:
	if regions.size() != _ALL_REGIONS.size():
		return false
	for r: StringName in _ALL_REGIONS:
		if not regions.has(r):
			return false
	return true


func _is_full_column_set(columns: Array[int]) -> bool:
	if columns.size() != _ALL_COLUMNS.size():
		return false
	for c: int in _ALL_COLUMNS:
		if not columns.has(c):
			return false
	return true


func _humanize_region(region_id: StringName) -> String:
	return str(region_id).trim_prefix("the_").capitalize()


func _on_play_pressed() -> void:
	if _def != null:
		play_pressed.emit(_def)
