class_name GambitTuningScreen
extends Control

## Gambit tuning. ADMIN mode is the dev-facing preset-driven editor. RUN
## mode is a placeholder until the gambit-tuning runtime PR lands — every
## interactive widget is hidden and a "not yet wired" label takes their
## place, with Back returning to `return_path`.

enum Mode { ADMIN, RUN }

const ADMIN_HUB_PATH: String = "res://scenes/ui/admin_hub.tscn"
const CHARACTER_CARD_TILE: PackedScene = preload(
	"res://scenes/ui/components/character_card_tile.tscn"
)
const EDITABLE_GAMBIT_ROW: PackedScene = preload(
	"res://scenes/ui/components/editable_gambit_row.tscn"
)

static var mode: Mode = Mode.ADMIN
static var return_path: String = ADMIN_HUB_PATH

var _snap: Dictionary = {}
var _focused_idx: int = 0
var _all_cards: Array[GambitCard] = []
var _card_options: Array = []
var _run_placeholder_label: Label = null

@onready var preset_row: HBoxContainer = $PresetRow
@onready var early_button: Button = $PresetRow/EarlyButton
@onready var mid_button: Button = $PresetRow/MidButton
@onready var late_button: Button = $PresetRow/LateButton
@onready var chips_header: Label = $ChipsHeader
@onready var back_button: Button = $BackButton
@onready var character_panel: HBoxContainer = $CharacterPanel
@onready var prev_button: Button = $CharacterPanel/PrevButton
@onready var next_button: Button = $CharacterPanel/NextButton
@onready var character_slot: MarginContainer = $CharacterPanel/CharacterColumn/CharacterSlot
@onready var minus_chip_button: Button = $CharacterPanel/CharacterColumn/ChipControls/MinusButton
@onready var plus_chip_button: Button = $CharacterPanel/CharacterColumn/ChipControls/PlusButton
@onready var chip_summary_label: Label = $CharacterPanel/CharacterColumn/ChipSummaryLabel
@onready var rows_column: VBoxContainer = $CharacterPanel/RowsColumn
@onready var rows_hint_label: Label = $CharacterPanel/RowsColumn/RowsHintLabel


func _ready() -> void:
	back_button.pressed.connect(_back)
	match mode:
		Mode.ADMIN:
			_load_admin()
		Mode.RUN:
			_load_run()


func _exit_tree() -> void:
	mode = Mode.ADMIN
	return_path = ADMIN_HUB_PATH


func _load_admin() -> void:
	_all_cards = GambitCardCatalog.get_all()
	_card_options = _build_card_options()
	early_button.pressed.connect(_load_preset.bind(GambitTuningPresets.Preset.EARLY))
	mid_button.pressed.connect(_load_preset.bind(GambitTuningPresets.Preset.MID))
	late_button.pressed.connect(_load_preset.bind(GambitTuningPresets.Preset.LATE))
	prev_button.pressed.connect(_on_prev)
	next_button.pressed.connect(_on_next)
	plus_chip_button.pressed.connect(_on_plus_chip)
	minus_chip_button.pressed.connect(_on_minus_chip)
	_load_preset(GambitTuningPresets.Preset.EARLY)
	early_button.grab_focus()


func _load_run() -> void:
	preset_row.visible = false
	chips_header.visible = false
	character_panel.visible = false
	_run_placeholder_label = Label.new()
	_run_placeholder_label.text = "Gambit tuning is not yet wired to the active run."
	_run_placeholder_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_run_placeholder_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_run_placeholder_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_run_placeholder_label.add_theme_font_size_override("font_size", 24)
	_run_placeholder_label.add_theme_color_override("font_color", Color(0.9569, 0.9333, 0.8392))
	add_child(_run_placeholder_label)
	back_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_back()


func _load_preset(preset: GambitTuningPresets.Preset) -> void:
	_snap = GambitTuningPresets.get_snapshot(preset)
	_focused_idx = 0
	_rebuild_all()


func _focused() -> Dictionary:
	var chars: Array = _snap.get("characters", [])
	if _focused_idx < 0 or _focused_idx >= chars.size():
		return {}
	return chars[_focused_idx]


func _free_chips() -> int:
	var used: int = 0
	for c: Dictionary in _snap.get("characters", []):
		used += int(c.get("chips_equipped", 0))
	return int(_snap.get("owned_chips", 0)) - used


func _on_prev() -> void:
	var chars: Array = _snap.get("characters", [])
	if chars.is_empty():
		return
	_focused_idx = (_focused_idx - 1 + chars.size()) % chars.size()
	_rebuild_all()


func _on_next() -> void:
	var chars: Array = _snap.get("characters", [])
	if chars.is_empty():
		return
	_focused_idx = (_focused_idx + 1) % chars.size()
	_rebuild_all()


func _on_plus_chip() -> void:
	var focused: Dictionary = _focused()
	if focused.is_empty() or _free_chips() <= 0:
		return
	focused["chips_equipped"] = int(focused.get("chips_equipped", 0)) + 1
	var rows: Array = focused.get("rows", []) as Array
	rows.append(GambitDef.new())
	focused["rows"] = rows
	_rebuild_all()


func _on_minus_chip() -> void:
	var focused: Dictionary = _focused()
	if focused.is_empty():
		return
	var chips: int = int(focused.get("chips_equipped", 0))
	if chips <= 0:
		return
	focused["chips_equipped"] = chips - 1
	var rows: Array = focused.get("rows", []) as Array
	if rows.size() > 0:
		rows.pop_back()
	focused["rows"] = rows
	_rebuild_all()


func _rebuild_all() -> void:
	_update_chips_header()
	_rebuild_character_card()
	_rebuild_rows()
	_update_chip_controls()


func _update_chips_header() -> void:
	var owned: int = int(_snap.get("owned_chips", 0))
	chips_header.text = "Owned: %d   Free: %d" % [owned, _free_chips()]


func _rebuild_character_card() -> void:
	for child: Node in character_slot.get_children():
		child.queue_free()
	var focused: Dictionary = _focused()
	if focused.is_empty():
		return
	var def: CharacterDef = focused.get("def")
	if def == null:
		return
	var tile: CharacterCardTile = CHARACTER_CARD_TILE.instantiate()
	character_slot.add_child(tile)
	tile.setup(def, int(focused.get("level", 1)))
	var chars: Array = _snap.get("characters", [])
	prev_button.disabled = chars.size() <= 1
	next_button.disabled = chars.size() <= 1


func _rebuild_rows() -> void:
	for child: Node in rows_column.get_children():
		if child == rows_hint_label:
			continue
		child.queue_free()
	var focused: Dictionary = _focused()
	if focused.is_empty():
		return
	var def: CharacterDef = focused.get("def")
	if def == null:
		return
	var level: int = int(focused.get("level", 1))
	var action_options: Array = _build_action_options(def, level)
	var rows: Array = focused.get("rows", []) as Array
	var i: int = 0
	for entry in rows:
		var row_def: GambitDef = entry as GambitDef
		var row_widget: EditableGambitRow = EDITABLE_GAMBIT_ROW.instantiate()
		rows_column.add_child(row_widget)
		row_widget.set_action_options(action_options)
		row_widget.set_card_options(_card_options)
		var action_id: StringName = row_def.action_id if row_def != null else &""
		var card_id: StringName = _card_id_for(row_def)
		row_widget.set_selection(action_id, card_id)
		row_widget.selection_changed.connect(_on_row_changed.bind(i))
		i += 1


func _update_chip_controls() -> void:
	var focused: Dictionary = _focused()
	if focused.is_empty():
		plus_chip_button.disabled = true
		minus_chip_button.disabled = true
		chip_summary_label.text = "Chips: 0"
		return
	var chips: int = int(focused.get("chips_equipped", 0))
	plus_chip_button.disabled = _free_chips() <= 0
	minus_chip_button.disabled = chips <= 0
	chip_summary_label.text = "Chips: %d" % chips


func _on_row_changed(action_id: StringName, card_id: StringName, row_idx: int) -> void:
	var focused: Dictionary = _focused()
	if focused.is_empty():
		return
	var rows: Array = focused.get("rows", []) as Array
	if row_idx < 0 or row_idx >= rows.size():
		return
	var row_def: GambitDef = rows[row_idx] as GambitDef
	if row_def == null:
		row_def = GambitDef.new()
		rows[row_idx] = row_def
	row_def.action_id = action_id
	if card_id == &"":
		row_def.trigger_expr = ""
		row_def.target_selector = &""
		return
	var card: GambitCard = _card_by_id(card_id)
	if card != null:
		row_def.trigger_expr = card.trigger_expr
		row_def.target_selector = card.target_selector


func _build_action_options(def: CharacterDef, level: int) -> Array:
	var options: Array = []
	if def != null:
		var learned: Array[LearnEntry] = []
		for entry: LearnEntry in def.learn_list:
			if entry.ability != null and entry.level <= level:
				learned.append(entry)
		learned.sort_custom(func(a: LearnEntry, b: LearnEntry) -> bool: return a.level < b.level)
		for entry: LearnEntry in learned:
			var label: String = (
				entry.ability.display_name
				if entry.ability.display_name != ""
				else str(entry.ability.id)
			)
			options.append({"id": entry.ability.id, "label": "%s — Lv %d" % [label, entry.level]})
	for item: ItemDef in _snap.get("party_items", []) as Array[ItemDef]:
		var label_str: String = item.display_name if item.display_name != "" else str(item.id)
		options.append({"id": item.id, "label": "Item: %s" % label_str})
	return options


func _build_card_options() -> Array:
	var options: Array = []
	for card: GambitCard in _all_cards:
		var label: String = card.display_name if card.display_name != "" else str(card.id)
		options.append({"id": card.id, "label": label})
	return options


func _card_by_id(id: StringName) -> GambitCard:
	for card: GambitCard in _all_cards:
		if card.id == id:
			return card
	return null


func _card_id_for(row_def: GambitDef) -> StringName:
	if row_def == null:
		return &""
	for card: GambitCard in _all_cards:
		if (
			card.trigger_expr == row_def.trigger_expr
			and card.target_selector == row_def.target_selector
		):
			return card.id
	return &""


func _back() -> void:
	var target: String = return_path
	return_path = ADMIN_HUB_PATH
	get_tree().change_scene_to_file(target)
