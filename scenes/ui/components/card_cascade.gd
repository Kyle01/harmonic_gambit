class_name CardCascade
extends Control

## Uniform-size card cascade. All cards render at the same size, evenly
## staggered horizontally so each card peeks out from behind the next.
## The selected card is raised slightly and outlined; click any card to
## swap selection. A label below the fan shows the selected card's
## display string.
##
## Per-entry optional flags (default false; back-compat with view-only callers):
##   equipped : bool — paints a brighter gold border to mark the card as equipped
##   glow     : bool — adds a pulsing gold halo behind the card

signal focus_changed(index: int)
signal entry_clicked(index: int)

const SLIVER_STRIDE: int = 60
const CARD_WIDTH: int = 170
const CARD_HEIGHT: int = 240
const SELECTED_RAISE: int = 14
const HALO_PADDING: int = 14

var _entries: Array = []
var _focus_index: int = 0
var _selected_style: StyleBoxFlat = null
var _normal_style: StyleBoxFlat = null
var _equipped_style: StyleBoxFlat = null
var _halo_style: StyleBoxFlat = null
var _halo_tweens: Array[Tween] = []

@onready var fan: Control = $Fan
@onready var label: Label = $FocusLabel
@onready var empty_label: Label = $EmptyLabel


func _ready() -> void:
	_make_styles()
	_apply()


func set_entries(entries: Array) -> void:
	var size_changed: bool = entries.size() != _entries.size()
	_entries = entries
	if size_changed or _focus_index >= entries.size():
		_focus_index = 0
	if is_node_ready():
		_apply()


func get_focus_index() -> int:
	return _focus_index


func set_focus_index(index: int) -> void:
	if index < 0 or index >= _entries.size():
		return
	if index == _focus_index:
		return
	_focus_index = index
	if is_node_ready():
		_clear_fan()
		_build_fan()
		_update_label()


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
	_equipped_style = StyleBoxFlat.new()
	_equipped_style.bg_color = Color(0, 0, 0, 0)
	_equipped_style.border_width_left = 5
	_equipped_style.border_width_top = 5
	_equipped_style.border_width_right = 5
	_equipped_style.border_width_bottom = 5
	_equipped_style.border_color = Color(1.0, 0.85, 0.25, 1.0)
	_halo_style = StyleBoxFlat.new()
	_halo_style.bg_color = Color(1.0, 0.898, 0.4, 0.18)
	_halo_style.border_width_left = 6
	_halo_style.border_width_top = 6
	_halo_style.border_width_right = 6
	_halo_style.border_width_bottom = 6
	_halo_style.border_color = Color(1.0, 0.898, 0.4, 0.9)
	_halo_style.corner_radius_top_left = 12
	_halo_style.corner_radius_top_right = 12
	_halo_style.corner_radius_bottom_left = 12
	_halo_style.corner_radius_bottom_right = 12


func _apply() -> void:
	_kill_halo_tweens()
	_clear_fan()
	if _entries.is_empty():
		empty_label.visible = true
		label.text = ""
		return
	empty_label.visible = false
	_build_fan()
	_update_label()


func _clear_fan() -> void:
	_kill_halo_tweens()
	for c: Node in fan.get_children():
		c.queue_free()


func _kill_halo_tweens() -> void:
	for t: Tween in _halo_tweens:
		if t != null and t.is_valid():
			t.kill()
	_halo_tweens.clear()


func _build_fan() -> void:
	var focused_card: PanelContainer = null
	var focused_halo: Panel = null
	var n: int = _entries.size()
	var total_width: int = (n - 1) * SLIVER_STRIDE + CARD_WIDTH if n > 0 else 0
	var offset_x: int = max(0, int((fan.size.x - total_width) / 2))
	var i: int = 0
	for entry: Dictionary in _entries:
		var is_focused: bool = i == _focus_index
		var is_equipped: bool = entry.get("equipped", false)
		var has_glow: bool = entry.get("glow", false)
		var y_offset: int = 0 if is_focused else SELECTED_RAISE
		var card_pos: Vector2 = Vector2(offset_x + i * SLIVER_STRIDE, y_offset)

		var halo: Panel = null
		if has_glow:
			halo = _make_halo(card_pos)
			fan.add_child(halo)

		var card: PanelContainer = PanelContainer.new()
		card.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
		card.size = Vector2(CARD_WIDTH, CARD_HEIGHT)
		if is_equipped:
			card.add_theme_stylebox_override("panel", _equipped_style)
		elif is_focused:
			card.add_theme_stylebox_override("panel", _selected_style)
		else:
			card.add_theme_stylebox_override("panel", _normal_style)
			card.modulate = Color(0.82, 0.82, 0.82, 1.0)
		card.position = card_pos
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

		if is_focused:
			focused_card = card
			focused_halo = halo
		i += 1

	if focused_card != null:
		if focused_halo != null:
			fan.move_child(focused_halo, -1)
		fan.move_child(focused_card, -1)


func _make_halo(card_pos: Vector2) -> Panel:
	var halo: Panel = Panel.new()
	halo.add_theme_stylebox_override("panel", _halo_style)
	halo.position = card_pos - Vector2(HALO_PADDING, HALO_PADDING)
	halo.size = Vector2(CARD_WIDTH + HALO_PADDING * 2, CARD_HEIGHT + HALO_PADDING * 2)
	halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween: Tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	tween.tween_property(halo, "modulate:a", 1.0, 0.8)
	tween.tween_property(halo, "modulate:a", 0.4, 0.8)
	_halo_tweens.append(tween)
	return halo


func _on_card_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			entry_clicked.emit(index)
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
