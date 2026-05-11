class_name CardCascade
extends Control

## Uniform-size card cascade. All cards render at the same size, evenly
## staggered horizontally so each card peeks out from behind the next.
## The selected card is raised slightly and outlined; click any card to
## swap selection. A label below the fan shows the selected card's
## display string.

signal focus_changed(index: int)

const SLIVER_STRIDE: int = 60
const CARD_WIDTH: int = 170
const CARD_HEIGHT: int = 240
const SELECTED_RAISE: int = 14

var _entries: Array = []
var _focus_index: int = 0
var _selected_style: StyleBoxFlat = null
var _normal_style: StyleBoxFlat = null

@onready var fan: Control = $Fan
@onready var label: Label = $FocusLabel
@onready var empty_label: Label = $EmptyLabel


func _ready() -> void:
	_make_styles()
	_apply()


func set_entries(entries: Array) -> void:
	_entries = entries
	_focus_index = 0
	if is_node_ready():
		_apply()


func _make_styles() -> void:
	_selected_style = StyleBoxFlat.new()
	_selected_style.bg_color = Color(0, 0, 0, 0)
	_selected_style.border_width_left = 3
	_selected_style.border_width_top = 3
	_selected_style.border_width_right = 3
	_selected_style.border_width_bottom = 3
	_selected_style.border_color = Color(1.0, 0.898, 0.4, 1.0)
	_normal_style = StyleBoxFlat.new()
	_normal_style.bg_color = Color(0, 0, 0, 0)


func _apply() -> void:
	_clear_fan()
	if _entries.is_empty():
		empty_label.visible = true
		label.text = ""
		return
	empty_label.visible = false
	_build_fan()
	_update_label()


func _clear_fan() -> void:
	for c: Node in fan.get_children():
		c.queue_free()


func _build_fan() -> void:
	var focused_card: PanelContainer = null
	var n: int = _entries.size()
	var total_width: int = (n - 1) * SLIVER_STRIDE + CARD_WIDTH if n > 0 else 0
	var offset_x: int = max(0, int((fan.size.x - total_width) / 2))
	var i: int = 0
	for entry: Dictionary in _entries:
		var card: PanelContainer = PanelContainer.new()
		card.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
		card.size = Vector2(CARD_WIDTH, CARD_HEIGHT)
		var y_offset: int = SELECTED_RAISE
		if i == _focus_index:
			y_offset = 0
			card.add_theme_stylebox_override("panel", _selected_style)
			focused_card = card
		else:
			card.add_theme_stylebox_override("panel", _normal_style)
			card.modulate = Color(0.82, 0.82, 0.82, 1.0)
		card.position = Vector2(offset_x + i * SLIVER_STRIDE, y_offset)
		card.mouse_filter = Control.MOUSE_FILTER_STOP

		var tex_rect: TextureRect = TextureRect.new()
		tex_rect.texture = entry.get("art")
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(tex_rect)

		var idx: int = i
		card.gui_input.connect(_on_card_gui_input.bind(idx))
		fan.add_child(card)
		i += 1

	if focused_card != null:
		fan.move_child(focused_card, -1)


func _on_card_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			if index != _focus_index:
				_focus_index = index
				_clear_fan()
				_build_fan()
				_update_label()
				focus_changed.emit(index)


func _update_label() -> void:
	if _entries.is_empty():
		label.text = ""
		return
	label.text = _entries[_focus_index].get("label", "")
