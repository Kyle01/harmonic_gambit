class_name EventRunDemo
extends Control

## Read-only walkthrough of an EventDef's scene tree, used by the admin
## Events screen to verify event content end-to-end. Does NOT mutate
## GameState — every effect renders to the log panel showing what *would*
## apply at the currently-previewed column. The column spinbox lets the dev
## scrub the column-effect multiplier and see numeric effects re-scale in
## real time.
##
## Static target_event is set by the parent screen (EventsScreen) before
## change_scene_to_file. _ready() reads it, seeds RNG.get_stream("event_demo"),
## and navigates to the entry scene.

const EVENTS_PATH: String = "res://scenes/ui/events.tscn"

static var target_event: EventDef = null

var _stream: RandomNumberGenerator = null
var _current_scene_id: StringName = &""
var _visited_scenes: Array[EventScene] = []
var _column: int = 0

@onready var event_title_label: Label = $Panel/Margin/Rows/EventTitleLabel
@onready var column_spinbox: SpinBox = $Panel/Margin/Rows/HeaderRow/ColumnSpinBox
@onready var multiplier_label: Label = $Panel/Margin/Rows/HeaderRow/MultiplierLabel
@onready var body_label: RichTextLabel = $Panel/Margin/Rows/BodyLabel
@onready var choices_box: VBoxContainer = $Panel/Margin/Rows/ChoicesBox
@onready var log_title: Label = $Panel/Margin/Rows/LogTitle
@onready var log_box: VBoxContainer = $Panel/Margin/Rows/LogScroll/LogBox
@onready var continue_button: Button = $Panel/Margin/Rows/Footer/ContinueButton
@onready var restart_button: Button = $Panel/Margin/Rows/Footer/RestartButton
@onready var back_button: Button = $BackButton


func _ready() -> void:
	back_button.pressed.connect(_back)
	restart_button.pressed.connect(_restart)
	continue_button.pressed.connect(_back)
	column_spinbox.value_changed.connect(_on_column_changed)

	if target_event == null:
		event_title_label.text = "(no event selected)"
		body_label.text = ""
		return

	event_title_label.text = (
		target_event.display_name if target_event.display_name != "" else str(target_event.id)
	)
	_stream = RNG.get_stream("event_demo")
	_column = int(column_spinbox.value)
	_update_multiplier_label()
	_visit(target_event.entry_scene_id)


func _unhandled_input(input_event: InputEvent) -> void:
	if input_event.is_action_pressed("ui_cancel"):
		_back()


func _on_column_changed(value: float) -> void:
	_column = int(value)
	_update_multiplier_label()
	_render_log()


func _update_multiplier_label() -> void:
	if target_event == null:
		multiplier_label.text = ""
		return
	var mult: float = target_event.column_multiplier(_column)
	multiplier_label.text = (
		"coeff %.2f · col %d → ×%.2f" % [target_event.column_effect_multiplier, _column, mult]
	)


func _restart() -> void:
	if target_event == null:
		return
	_visited_scenes.clear()
	_visit(target_event.entry_scene_id)


func _visit(scene_id: StringName) -> void:
	var scene: EventScene = target_event.get_scene(scene_id)
	if scene == null:
		push_warning("EventRunDemo: missing scene id %s" % scene_id)
		return
	_current_scene_id = scene_id
	_visited_scenes.append(scene)
	_render_scene(scene)
	_render_log()


func _render_scene(scene: EventScene) -> void:
	body_label.text = scene.body
	for child: Node in choices_box.get_children():
		child.queue_free()
	if scene.choices.is_empty():
		continue_button.visible = true
		restart_button.visible = true
		return
	continue_button.visible = false
	restart_button.visible = false
	for choice: EventChoice in scene.choices:
		var button: Button = Button.new()
		button.text = _format_choice_label(choice)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choices_box.add_child(button)
		button.pressed.connect(_on_choice_pressed.bind(choice))
	if choices_box.get_child_count() > 0:
		var first_button: Button = choices_box.get_child(0) as Button
		first_button.grab_focus()


func _format_choice_label(choice: EventChoice) -> String:
	if choice.requirement == "":
		return choice.label
	return "[req: %s] %s" % [choice.requirement, choice.label]


func _on_choice_pressed(choice: EventChoice) -> void:
	if choice.outcomes.is_empty():
		push_warning("EventRunDemo: choice has no outcomes")
		return
	var outcome: EventOutcome = _roll_outcome(choice.outcomes)
	_visit(outcome.next_scene_id)


func _roll_outcome(outcomes: Array[EventOutcome]) -> EventOutcome:
	if outcomes.size() == 1:
		return outcomes[0]
	var total: float = 0.0
	for o: EventOutcome in outcomes:
		total += maxf(o.weight, 0.0)
	if total <= 0.0:
		return outcomes[0]
	var roll: float = _stream.randf() * total
	var cumulative: float = 0.0
	for o: EventOutcome in outcomes:
		cumulative += maxf(o.weight, 0.0)
		if roll <= cumulative:
			return o
	return outcomes[outcomes.size() - 1]


func _render_log() -> void:
	for child: Node in log_box.get_children():
		child.queue_free()
	var has_any: bool = false
	for scene: EventScene in _visited_scenes:
		if scene.effects.is_empty():
			continue
		has_any = true
		for effect: String in scene.effects:
			var line: Label = Label.new()
			line.text = "• " + _format_effect_line(effect)
			line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			line.add_theme_font_size_override("font_size", 14)
			line.add_theme_color_override("font_color", Color(0.9569, 0.9333, 0.8392))
			log_box.add_child(line)
	log_title.visible = has_any


func _format_effect_line(effect: String) -> String:
	var parts: PackedStringArray = effect.split(":")
	if parts.is_empty():
		return effect
	var verb: String = parts[0]
	var mult: float = target_event.column_multiplier(_column) if target_event != null else 1.0
	var rendered: String = effect
	match verb:
		"gain_credits":
			rendered = _format_gain_credits(parts, mult, effect)
		"heal_party":
			rendered = _format_heal_party(parts, mult, effect)
		"recruit":
			rendered = _format_recruit(parts, mult, effect)
	return rendered


func _format_gain_credits(parts: PackedStringArray, mult: float, fallback: String) -> String:
	if parts.size() < 2:
		return fallback
	var base: int = parts[1].to_int()
	var scaled: int = int(ceil(float(base) * mult))
	return "+%d credits → +%d  (×%.2f)" % [base, scaled, mult]


func _format_heal_party(parts: PackedStringArray, mult: float, fallback: String) -> String:
	if parts.size() < 2:
		return fallback
	var amount: String = parts[1]
	if amount == "full":
		return "heal party (full restore, no scaling)"
	var base_hp: int = amount.to_int()
	var scaled_hp: int = int(ceil(float(base_hp) * mult))
	return "heal party for %d HP → %d HP each  (×%.2f)" % [base_hp, scaled_hp, mult]


func _format_recruit(parts: PackedStringArray, mult: float, fallback: String) -> String:
	if parts.size() < 3:
		return fallback
	var character_id: String = parts[1]
	var base_level: int = parts[2].to_int()
	var scaled_level: int = int(ceil(float(base_level) * mult))
	var name_text: String = _resolve_character_name(character_id)
	return (
		"recruit %s at level %d → level %d  (×%.2f)" % [name_text, base_level, scaled_level, mult]
	)


func _resolve_character_name(character_id: String) -> String:
	for character: CharacterDef in CharacterCatalog.get_all():
		if str(character.id) == character_id:
			return character.display_name if character.display_name != "" else character_id
	return character_id


func _back() -> void:
	target_event = null
	get_tree().change_scene_to_file(EVENTS_PATH)
