class_name BandTuningScreen
extends Control

const ADMIN_HUB_PATH: String = "res://scenes/ui/admin_hub.tscn"
const GAMBIT_TUNING_PATH: String = "res://scenes/ui/gambit_tuning.tscn"

static var return_path: String = ADMIN_HUB_PATH

var _roster: Array = []
var _band_pool: Array[BandCard] = []
var _equipped_chars: Dictionary = {}
var _equipped_band_idx: int = -1
var _force_glow: bool = false

@onready var gambit_tuning_tab: Button = $TabsRow/GambitTuningTab
@onready var early_button: Button = $PresetRow/EarlyButton
@onready var mid_button: Button = $PresetRow/MidButton
@onready var late_button: Button = $PresetRow/LateButton
@onready var glow_toggle: CheckButton = $GlowToggle
@onready var back_button: Button = $BackButton
@onready var characters_cascade: CardCascade = $CharactersCascade
@onready var band_cards_cascade: CardCascade = $BandCardsCascade
@onready var equipped_count_label: Label = $EquippedCountLabel
@onready var activation_label: Label = $ActivationLabel


func _ready() -> void:
	gambit_tuning_tab.pressed.connect(_on_gambit_tuning_tab_pressed)
	early_button.pressed.connect(_load_preset.bind(BandTuningPresets.Preset.EARLY))
	mid_button.pressed.connect(_load_preset.bind(BandTuningPresets.Preset.MID))
	late_button.pressed.connect(_load_preset.bind(BandTuningPresets.Preset.LATE))
	glow_toggle.toggled.connect(_on_glow_toggled)
	back_button.pressed.connect(_back)
	characters_cascade.entry_clicked.connect(_on_character_clicked)
	band_cards_cascade.entry_clicked.connect(_on_band_card_clicked)
	band_cards_cascade.focus_changed.connect(_on_band_focus_changed)
	_load_preset(BandTuningPresets.Preset.EARLY)
	early_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_back()


func _load_preset(preset: BandTuningPresets.Preset) -> void:
	var snap: Dictionary = BandTuningPresets.get_snapshot(preset)
	_roster = snap["characters"]
	_band_pool = snap["band_cards"]
	_equipped_chars.clear()
	_equipped_band_idx = -1
	_rebuild_characters()
	_rebuild_band_cards()
	_update_equipped_count()
	_update_activation_label()


func _on_character_clicked(idx: int) -> void:
	if idx < 0 or idx >= _roster.size():
		return
	if _equipped_chars.has(idx):
		_equipped_chars.erase(idx)
	else:
		_equipped_chars[idx] = true
	_rebuild_characters()
	_update_equipped_count()


func _on_band_card_clicked(idx: int) -> void:
	if idx < 0 or idx >= _band_pool.size():
		return
	if _equipped_band_idx == idx:
		_equipped_band_idx = -1
	else:
		_equipped_band_idx = idx
	_rebuild_band_cards()


func _on_band_focus_changed(_idx: int) -> void:
	_update_activation_label()


func _on_glow_toggled(pressed: bool) -> void:
	_force_glow = pressed
	_rebuild_band_cards()


func _rebuild_characters() -> void:
	var entries: Array = []
	var i: int = 0
	for row: Dictionary in _roster:
		var def: CharacterDef = row["def"]
		var name_str: String = "?"
		var art: Texture2D = null
		if def != null:
			name_str = def.display_name if def.display_name != "" else str(def.id)
			art = def.portrait
		var level: int = row.get("level", 1)
		var chips: int = row.get("chips", 0)
		var label: String = (
			"%s — Lv %d · %d chip%s" % [name_str, level, chips, "" if chips == 1 else "s"]
		)
		(
			entries
			. append(
				{
					"art": art,
					"label": label,
					"equipped": _equipped_chars.has(i),
				}
			)
		)
		i += 1
	characters_cascade.set_entries(entries)


func _rebuild_band_cards() -> void:
	var entries: Array = []
	var i: int = 0
	for card: BandCard in _band_pool:
		var is_equipped: bool = i == _equipped_band_idx
		var name_str: String = card.display_name if card.display_name != "" else str(card.id)
		(
			entries
			. append(
				{
					"art": card.art,
					"label": name_str,
					"equipped": is_equipped,
					"glow": is_equipped and _force_glow,
				}
			)
		)
		i += 1
	band_cards_cascade.set_entries(entries)


func _update_equipped_count() -> void:
	equipped_count_label.text = "Equipped: %d" % _equipped_chars.size()


func _update_activation_label() -> void:
	if _band_pool.is_empty():
		activation_label.text = ""
		return
	var focus_idx: int = band_cards_cascade.get_focus_index()
	if focus_idx < 0 or focus_idx >= _band_pool.size():
		activation_label.text = ""
		return
	var card: BandCard = _band_pool[focus_idx]
	activation_label.text = " · ".join(card.activation_requirements)


func _on_gambit_tuning_tab_pressed() -> void:
	GambitTuningScreen.return_path = ADMIN_HUB_PATH
	get_tree().change_scene_to_file(GAMBIT_TUNING_PATH)


func _back() -> void:
	var target := return_path
	return_path = ADMIN_HUB_PATH
	get_tree().change_scene_to_file(target)
