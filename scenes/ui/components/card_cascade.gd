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
##   glow     : bool — adds a soft pulsing white halo behind the card

signal focus_changed(index: int)
signal entry_clicked(index: int)

@export var card_width: int = 170
@export var card_height: int = 240
@export var sliver_stride: int = 60
@export var selected_raise: int = 14
@export var halo_padding: int = 0
@export var show_focus_label: bool = true
@export var show_borders: bool = true

var _entries: Array = []
var _focus_index: int = 0
var _selected_style: StyleBoxFlat = null
var _normal_style: StyleBoxFlat = null
var _equipped_style: StyleBoxFlat = null
var _halo_style_outer: StyleBoxFlat = null
var _halo_style_inner: StyleBoxFlat = null
var _halo_tweens: Array[Tween] = []

@onready var fan: Control = $Fan
@onready var label: Label = $FocusLabel
@onready var empty_label: Label = $EmptyLabel


func _ready() -> void:
	_make_styles()
	_layout_internals()
	_apply()


func _layout_internals() -> void:
	# When the focus label is shown, defer to the cascade scene's authored
	# Fan/FocusLabel positions (back-compat with existing callers).
	if show_focus_label:
		return
	label.visible = false
	var fan_top: float = 16.0
	var width: float = fan.size.x if fan.size.x > 0.0 else 600.0
	var fan_height: float = float(card_height + selected_raise + halo_padding * 2)
	fan.position = Vector2(0.0, fan_top)
	fan.size = Vector2(width, fan_height)
	empty_label.position = Vector2(0.0, fan_top + fan_height * 0.4)
	empty_label.size = Vector2(width, 30.0)


func get_focus_index() -> int:
	return _focus_index


func set_entries(entries: Array) -> void:
	var size_changed: bool = entries.size() != _entries.size()
	_entries = entries
	if size_changed or _focus_index >= entries.size():
		_focus_index = 0
	if is_node_ready():
		_apply()


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
	# Halo: layered white panels with rounded corners, simulating a soft gradient.
	_halo_style_outer = StyleBoxFlat.new()
	_halo_style_outer.bg_color = Color(1.0, 1.0, 1.0, 0.10)
	_halo_style_outer.border_color = Color(1.0, 1.0, 1.0, 0.35)
	_halo_style_outer.border_width_left = 4
	_halo_style_outer.border_width_top = 4
	_halo_style_outer.border_width_right = 4
	_halo_style_outer.border_width_bottom = 4
	_halo_style_outer.corner_radius_top_left = 28
	_halo_style_outer.corner_radius_top_right = 28
	_halo_style_outer.corner_radius_bottom_left = 28
	_halo_style_outer.corner_radius_bottom_right = 28
	_halo_style_inner = StyleBoxFlat.new()
	_halo_style_inner.bg_color = Color(1.0, 1.0, 1.0, 0.28)
	_halo_style_inner.border_color = Color(1.0, 1.0, 1.0, 0.95)
	_halo_style_inner.border_width_left = 6
	_halo_style_inner.border_width_top = 6
	_halo_style_inner.border_width_right = 6
	_halo_style_inner.border_width_bottom = 6
	_halo_style_inner.corner_radius_top_left = 14
	_halo_style_inner.corner_radius_top_right = 14
	_halo_style_inner.corner_radius_bottom_left = 14
	_halo_style_inner.corner_radius_bottom_right = 14


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


func _effective_stride(n: int) -> int:
	if n <= 1:
		return sliver_stride
	var available: float = max(fan.size.x, float(card_width))
	var max_stride: int = int((available - float(card_width)) / float(n - 1))
	return clamp(sliver_stride, 1, max(1, max_stride))


func _build_fan() -> void:
	var focused_card: PanelContainer = null
	var focused_halo: Control = null
	var n: int = _entries.size()
	var stride: int = _effective_stride(n)
	var total_width: int = (n - 1) * stride + card_width if n > 0 else 0
	var offset_x: int = max(0, int((fan.size.x - float(total_width)) / 2.0))
	var card_baseline_y: int = halo_padding + selected_raise
	var i: int = 0
	for entry: Dictionary in _entries:
		var is_focused: bool = i == _focus_index
		var is_equipped: bool = entry.get("equipped", false)
		var has_glow: bool = entry.get("glow", false)
		var y_offset: int = card_baseline_y if not is_focused else card_baseline_y - selected_raise
		var card_pos: Vector2 = Vector2(offset_x + i * stride, y_offset)

		var halo: Control = null
		if has_glow:
			halo = _make_halo(card_pos)
			fan.add_child(halo)

		var card: PanelContainer = PanelContainer.new()
		card.custom_minimum_size = Vector2(card_width, card_height)
		card.size = Vector2(card_width, card_height)
		if is_equipped and show_borders:
			card.add_theme_stylebox_override("panel", _equipped_style)
		elif is_focused and show_borders:
			card.add_theme_stylebox_override("panel", _selected_style)
		else:
			card.add_theme_stylebox_override("panel", _normal_style)
			if not is_focused:
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


func _make_halo(card_pos: Vector2) -> Control:
	var group: Control = Control.new()
	group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group.position = Vector2.ZERO
	group.size = fan.size

	var outer_pad: int = halo_padding
	var outer: Panel = Panel.new()
	outer.add_theme_stylebox_override("panel", _halo_style_outer)
	outer.position = card_pos - Vector2(outer_pad, outer_pad)
	outer.size = Vector2(card_width + outer_pad * 2, card_height + outer_pad * 2)
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group.add_child(outer)

	var inner_pad: int = max(halo_padding / 2, 8)
	var inner: Panel = Panel.new()
	inner.add_theme_stylebox_override("panel", _halo_style_inner)
	inner.position = card_pos - Vector2(inner_pad, inner_pad)
	inner.size = Vector2(card_width + inner_pad * 2, card_height + inner_pad * 2)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group.add_child(inner)

	var tween: Tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	tween.tween_property(group, "modulate:a", 1.0, 0.7)
	tween.tween_property(group, "modulate:a", 0.55, 0.7)
	_halo_tweens.append(tween)
	return group


func _on_card_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			entry_clicked.emit(index)
			# entry_clicked handlers may rebuild entries; index can now be stale.
			if index < 0 or index >= _entries.size():
				return
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
