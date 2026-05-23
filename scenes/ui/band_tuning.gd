class_name BandTuningScreen
extends Control

const ADMIN_HUB_PATH: String = "res://scenes/ui/admin_hub.tscn"
const BAND_TUNING_PATH: String = "res://scenes/ui/band_tuning.tscn"
const GAMBIT_TUNING_PATH: String = "res://scenes/ui/gambit_tuning.tscn"

static var return_path: String = ADMIN_HUB_PATH

var _roster: Array = []
var _band_pool: Array[BandCard] = []
var _equipped_char_indices: Array[int] = []
var _equipped_band_idx: int = -1
var _force_glow: bool = false
var _focused_band_pool_idx: int = -1

@onready var gambit_tuning_tab: Button = $TabsRow/GambitTuningTab
@onready var early_button: Button = $PresetRow/EarlyButton
@onready var mid_button: Button = $PresetRow/MidButton
@onready var late_button: Button = $PresetRow/LateButton
@onready var glow_toggle: CheckButton = $GlowToggle
@onready var back_button: Button = $BackButton
@onready var top_characters_cascade: CardCascade = $TopCharactersCascade
@onready var top_band_cards_cascade: CardCascade = $TopBandCardsCascade
@onready var bottom_characters_cascade: CardCascade = $BottomCharactersCascade
@onready var bottom_band_cards_cascade: CardCascade = $BottomBandCardsCascade
@onready var equipped_count_label: Label = $EquippedCountLabel
@onready var activation_label: Label = $ActivationLabel
@onready var gambit_chips_label: Label = $GambitChipsLabel


func _ready() -> void:
	gambit_tuning_tab.pressed.connect(_on_gambit_tuning_tab_pressed)
	early_button.pressed.connect(_load_preset.bind(BandTuningPresets.Preset.EARLY))
	mid_button.pressed.connect(_load_preset.bind(BandTuningPresets.Preset.MID))
	late_button.pressed.connect(_load_preset.bind(BandTuningPresets.Preset.LATE))
	glow_toggle.toggled.connect(_on_glow_toggled)
	back_button.pressed.connect(_back)
	top_characters_cascade.entry_clicked.connect(_on_top_character_clicked)
	bottom_characters_cascade.entry_clicked.connect(_on_bottom_character_clicked)
	top_band_cards_cascade.entry_clicked.connect(_on_top_band_card_clicked)
	bottom_band_cards_cascade.entry_clicked.connect(_on_bottom_band_card_clicked)
	bottom_band_cards_cascade.focus_changed.connect(_on_bottom_band_focus_changed)
	_load_preset(BandTuningPresets.Preset.EARLY)
	early_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_back()


func _load_preset(preset: BandTuningPresets.Preset) -> void:
	var snap: Dictionary = BandTuningPresets.get_snapshot(preset)
	_roster = snap["characters"]
	_band_pool = snap["band_cards"]
	_equipped_char_indices.clear()
	_equipped_band_idx = -1
	_focused_band_pool_idx = 0 if _band_pool.size() > 0 else -1
	_update_total_chips_label()
	_rebuild_all()


func _on_bottom_character_clicked(idx: int) -> void:
	if idx < 0 or idx >= _roster.size():
		return
	if _equipped_char_indices.has(idx):
		_equipped_char_indices.erase(idx)
	else:
		_equipped_char_indices.append(idx)
	_rebuild_characters()


func _on_top_character_clicked(idx: int) -> void:
	if idx < 0 or idx >= _equipped_char_indices.size():
		return
	_equipped_char_indices.remove_at(idx)
	_rebuild_characters()


func _on_bottom_band_card_clicked(idx: int) -> void:
	if idx < 0 or idx >= _band_pool.size():
		return
	if _equipped_band_idx == idx:
		_equipped_band_idx = -1
	else:
		_equipped_band_idx = idx
	_focused_band_pool_idx = idx
	_rebuild_band_cards()


func _on_top_band_card_clicked(_idx: int) -> void:
	if _equipped_band_idx < 0:
		return
	_equipped_band_idx = -1
	_rebuild_band_cards()


func _on_bottom_band_focus_changed(idx: int) -> void:
	_focused_band_pool_idx = idx
	_update_activation_label()


func _on_glow_toggled(pressed: bool) -> void:
	_force_glow = pressed
	_rebuild_band_cards()


func _rebuild_all() -> void:
	_rebuild_characters()
	_rebuild_band_cards()


func _rebuild_characters() -> void:
	top_characters_cascade.set_entries(_build_top_character_entries())
	bottom_characters_cascade.set_entries(_build_bottom_character_entries())
	_update_equipped_count()


func _rebuild_band_cards() -> void:
	top_band_cards_cascade.set_entries(_build_top_band_card_entries())
	bottom_band_cards_cascade.set_entries(_build_bottom_band_card_entries())
	_update_activation_label()


func _build_top_character_entries() -> Array:
	var entries: Array = []
	for roster_idx: int in _equipped_char_indices:
		if roster_idx < 0 or roster_idx >= _roster.size():
			continue
		entries.append(_character_entry(_roster[roster_idx], false))
	return entries


func _build_bottom_character_entries() -> Array:
	var entries: Array = []
	var i: int = 0
	for row: Dictionary in _roster:
		var is_equipped: bool = _equipped_char_indices.has(i)
		entries.append(_character_entry(row, is_equipped))
		i += 1
	return entries


func _character_entry(row: Dictionary, is_equipped: bool) -> Dictionary:
	var def: CharacterDef = row.get("def")
	var name_str: String = "?"
	var art: Texture2D = null
	if def != null:
		name_str = def.display_name if def.display_name != "" else str(def.id)
		art = def.portrait
	var level: int = row.get("level", 1)
	var label: String = "%s — Lv %d" % [name_str, level]
	return {
		"art": art,
		"label": label,
		"equipped": is_equipped,
	}


func _build_top_band_card_entries() -> Array:
	var entries: Array = []
	if _equipped_band_idx < 0 or _equipped_band_idx >= _band_pool.size():
		return entries
	var card: BandCard = _band_pool[_equipped_band_idx]
	(
		entries
		. append(
			{
				"art": card.art,
				"label": _band_card_name(card),
				"equipped": true,
				"glow": _force_glow,
			}
		)
	)
	return entries


func _build_bottom_band_card_entries() -> Array:
	var entries: Array = []
	var i: int = 0
	for card: BandCard in _band_pool:
		var is_equipped: bool = i == _equipped_band_idx
		(
			entries
			. append(
				{
					"art": card.art,
					"label": _band_card_name(card),
					"equipped": is_equipped,
				}
			)
		)
		i += 1
	return entries


func _band_card_name(card: BandCard) -> String:
	return card.display_name if card.display_name != "" else str(card.id)


func _update_equipped_count() -> void:
	equipped_count_label.text = "Equipped: %d" % _equipped_char_indices.size()


func _update_total_chips_label() -> void:
	var total: int = 0
	for row: Dictionary in _roster:
		total += int(row.get("chips", 0))
	gambit_chips_label.text = "Gambit Chips: %d" % total


func _update_activation_label() -> void:
	var idx: int = _focused_band_pool_idx
	if idx < 0 or idx >= _band_pool.size():
		activation_label.text = ""
		return
	var card: BandCard = _band_pool[idx]
	activation_label.text = " · ".join(card.activation_requirements)


func _on_gambit_tuning_tab_pressed() -> void:
	GambitTuningScreen.return_path = BAND_TUNING_PATH
	get_tree().change_scene_to_file(GAMBIT_TUNING_PATH)


func _back() -> void:
	var target := return_path
	return_path = ADMIN_HUB_PATH
	get_tree().change_scene_to_file(target)
