class_name AdminCharacterDetail
extends Control

const ADMIN_PC_PATH: String = "res://scenes/ui/admin_playable_characters.tscn"
const UI_FONT: Font = preload("res://assets/fonts/munro_small.ttf")
const COLOR_TITLE: Color = Color(1, 0.898, 0.4, 1)
const COLOR_META: Color = Color(1, 0.5608, 0.8314, 1)
const COLOR_LOCKED: Color = Color(0.5, 0.5, 0.5, 1)

static var target_def: CharacterDef = null

@onready var portrait_rect: TextureRect = %Portrait
@onready var name_label: Label = %NameLabel
@onready var role_label: Label = %RoleLabel
@onready var flavor_label: Label = %FlavorLabel
@onready var level_slider: HSlider = %LevelSlider
@onready var level_label: Label = %LevelLabel
@onready var hp_value: Label = %HpValue
@onready var mp_value: Label = %MpValue
@onready var atk_value: Label = %AtkValue
@onready var def_value: Label = %DefValue
@onready var pow_value: Label = %PowValue
@onready var spd_value: Label = %SpdValue
@onready var learn_list_box: VBoxContainer = %LearnList
@onready var back_button: Button = %BackButton


func _ready() -> void:
	back_button.pressed.connect(_back)
	level_slider.value_changed.connect(_on_level_changed)
	if target_def == null:
		push_warning("AdminCharacterDetail: target_def not set")
		return
	_apply_static()
	_apply_slider_range()
	_refresh(int(level_slider.value))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_back()


func _apply_static() -> void:
	name_label.text = (
		target_def.display_name if target_def.display_name != "" else str(target_def.id)
	)
	role_label.text = (
		str(target_def.instrument_role) if target_def.instrument_role != &"" else "—"
	)
	flavor_label.text = target_def.flavor
	if target_def.portrait != null:
		portrait_rect.texture = target_def.portrait


func _on_level_changed(value: float) -> void:
	_refresh(int(value))


func _refresh(level: int) -> void:
	level_label.text = "Level %d" % level
	hp_value.text = str(CharacterDef.stat_at_level(target_def.base_hp, target_def.hp_growth, level))
	mp_value.text = str(CharacterDef.stat_at_level(target_def.base_mp, target_def.mp_growth, level))
	atk_value.text = str(
		CharacterDef.stat_at_level(target_def.base_atk, target_def.atk_growth, level)
	)
	def_value.text = str(
		CharacterDef.stat_at_level(target_def.base_def, target_def.def_growth, level)
	)
	pow_value.text = str(
		CharacterDef.stat_at_level(target_def.base_pow, target_def.pow_growth, level)
	)
	spd_value.text = str(
		CharacterDef.stat_at_level(target_def.base_spd, target_def.spd_growth, level)
	)
	_rebuild_learn_list(level)


func _apply_slider_range() -> void:
	var max_level: int = 1
	for entry: LearnEntry in target_def.learn_list:
		if entry != null:
			max_level = max(max_level, entry.level)
	level_slider.max_value = float(max_level)


func _rebuild_learn_list(slider_level: int) -> void:
	for child: Node in learn_list_box.get_children():
		child.queue_free()
	var entries: Array[LearnEntry] = target_def.learn_list.duplicate()
	entries.sort_custom(_by_level)
	for entry: LearnEntry in entries:
		var unlocked: bool = entry.level <= slider_level
		learn_list_box.add_child(_build_ability_row(entry, unlocked))


func _build_ability_row(entry: LearnEntry, unlocked: bool) -> Control:
	var title_color: Color = COLOR_TITLE if unlocked else COLOR_LOCKED
	var body_color: Color = COLOR_META if unlocked else COLOR_LOCKED
	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 2)
	box.add_child(
		_make_label("Lv %d  %s" % [entry.level, _ability_name(entry.ability)], 18, title_color)
	)
	box.add_child(_make_label(_meta_line(entry.ability), 12, body_color))
	var flavor_row: Label = _make_label(_flavor_text(entry.ability), 12, body_color)
	flavor_row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(flavor_row)
	return box


static func _by_level(a: LearnEntry, b: LearnEntry) -> bool:
	return a.level < b.level


static func _ability_name(ability: AbilityDef) -> String:
	if ability == null:
		return "(missing)"
	return ability.display_name if ability.display_name != "" else str(ability.id)


static func _meta_line(ability: AbilityDef) -> String:
	if ability == null:
		return ""
	return (
		"%s · %s · Power %d · MP %d"
		% [
			ability.category.to_upper(),
			_scope_label(ability.scope),
			ability.base_power,
			ability.mp_cost,
		]
	)


static func _scope_label(scope: String) -> String:
	match scope:
		"all":
			return "AoE"
		"chain":
			return "Chain"
		"splash":
			return "Splash"
		_:
			return "Single"


static func _flavor_text(ability: AbilityDef) -> String:
	if ability == null:
		return ""
	return ability.flavor


static func _make_label(text: String, font_size: int, color: Color) -> Label:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_font_override("font", UI_FONT)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	return lbl


func _back() -> void:
	get_tree().change_scene_to_file(ADMIN_PC_PATH)
