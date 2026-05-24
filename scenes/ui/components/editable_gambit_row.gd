class_name EditableGambitRow
extends PanelContainer

## Yellow editable gambit row — two inline OptionButton dropdowns for the
## action (character ability or party item) and the card (condition + target).
## Dumb component: the owning screen wires options and listens for changes.

signal selection_changed(action_id: StringName, card_id: StringName)

var _suppress_emit: bool = false

@onready var action_button: OptionButton = $Margin/Row/ActionButton
@onready var card_button: OptionButton = $Margin/Row/CardButton


func _ready() -> void:
	action_button.item_selected.connect(_on_item_selected)
	card_button.item_selected.connect(_on_item_selected)


func set_action_options(options: Array) -> void:
	_populate(action_button, options)


func set_card_options(options: Array) -> void:
	_populate(card_button, options)


func set_selection(action_id: StringName, card_id: StringName) -> void:
	_suppress_emit = true
	_select_by_id(action_button, action_id)
	_select_by_id(card_button, card_id)
	_suppress_emit = false


func get_action_id() -> StringName:
	return _selected_id(action_button)


func get_card_id() -> StringName:
	return _selected_id(card_button)


func _populate(button: OptionButton, options: Array) -> void:
	button.clear()
	for opt: Dictionary in options:
		var label: String = opt.get("label", "?")
		var id_val: StringName = opt.get("id", &"")
		var idx: int = button.item_count
		button.add_item(label, idx)
		button.set_item_metadata(idx, id_val)


func _select_by_id(button: OptionButton, id: StringName) -> void:
	if id == &"":
		if button.item_count > 0:
			button.selected = 0
		return
	for i: int in button.item_count:
		if button.get_item_metadata(i) == id:
			button.selected = i
			return
	if button.item_count > 0:
		button.selected = 0


func _selected_id(button: OptionButton) -> StringName:
	var idx: int = button.selected
	if idx < 0 or idx >= button.item_count:
		return &""
	var meta: Variant = button.get_item_metadata(idx)
	return meta if meta is StringName else &""


func _on_item_selected(_idx: int) -> void:
	if _suppress_emit:
		return
	selection_changed.emit(get_action_id(), get_card_id())
