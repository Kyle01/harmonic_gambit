class_name CharacterCardTile
extends PanelContainer

var _pending_def: CharacterDef = null

@onready var portrait_rect: TextureRect = $Margin/Rows/Portrait
@onready var name_label: Label = $Margin/Rows/NameLabel
@onready var role_label: Label = $Margin/Rows/RoleLabel
@onready var flavor_label: Label = $Margin/Rows/FlavorLabel


func setup(def: CharacterDef) -> void:
	if is_node_ready():
		_apply(def)
	else:
		_pending_def = def


func _ready() -> void:
	if _pending_def != null:
		_apply(_pending_def)
		_pending_def = null


func _apply(def: CharacterDef) -> void:
	name_label.text = def.display_name if def.display_name != "" else str(def.id)
	role_label.text = str(def.instrument_role) if def.instrument_role != &"" else "—"
	flavor_label.text = def.flavor
	if def.portrait != null:
		portrait_rect.texture = def.portrait
		portrait_rect.visible = true
	else:
		portrait_rect.texture = null
