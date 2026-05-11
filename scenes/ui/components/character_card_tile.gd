class_name CharacterCardTile
extends PanelContainer

signal selected(def: CharacterDef)

var _pending_def: CharacterDef = null
var _pending_level: int = 0
var _def: CharacterDef = null

@onready var portrait_rect: TextureRect = $Margin/Rows/Portrait
@onready var name_label: Label = $Margin/Rows/NameLabel
@onready var role_label: Label = $Margin/Rows/RoleLabel
@onready var level_label: Label = $Margin/Rows/LevelLabel
@onready var flavor_label: Label = $Margin/Rows/FlavorLabel


func setup(def: CharacterDef, level: int = 0) -> void:
	_def = def
	if is_node_ready():
		_apply(def, level)
	else:
		_pending_def = def
		_pending_level = level


func _ready() -> void:
	if _pending_def != null:
		_apply(_pending_def, _pending_level)
		_pending_def = null
		_pending_level = 0


func _apply(def: CharacterDef, level: int) -> void:
	name_label.text = def.display_name if def.display_name != "" else str(def.id)
	role_label.text = str(def.instrument_role) if def.instrument_role != &"" else "—"
	if level > 0:
		level_label.text = "Lv %d" % level
		level_label.visible = true
	else:
		level_label.text = ""
		level_label.visible = false
	flavor_label.text = def.flavor
	if def.portrait != null:
		portrait_rect.texture = def.portrait
		portrait_rect.visible = true
	else:
		portrait_rect.texture = null


func _gui_input(event: InputEvent) -> void:
	if _def == null:
		return
	var fired: bool = false
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			fired = true
	elif event.is_action_pressed("ui_accept"):
		fired = true
	if fired:
		selected.emit(_def)
		accept_event()
