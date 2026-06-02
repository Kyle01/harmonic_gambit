class_name EventRunner
extends Control

## Runtime event walker. Mirrors `EventRunDemo`'s scene-tree walk (body +
## choices + Continue) but applies each scene's effects to `GameState` via
## `EventEffectApplier` instead of rendering them to a log. Used by the
## run path when a region advances onto an EVENT-kind node.
##
## Callers set the three static vars before `change_scene_to_file`:
##   target_event_id  StringName id of the EventDef to play
##   target_column    realm column index for `column_effect_multiplier`
##   return_path      scene to load when the player presses Continue at
##                    the terminal scene
##
## Statics reset to their defaults on exit, so a stale value can't survive
## into the next entry.

const MAIN_MENU_PATH: String = "res://scenes/ui/main_menu.tscn"

static var target_event_id: StringName = &""
static var target_column: int = 0
static var return_path: String = MAIN_MENU_PATH

var _event: EventDef = null
var _stream: RandomNumberGenerator = null
var _current_scene_id: StringName = &""

@onready var event_title_label: Label = $Panel/Margin/Rows/EventTitleLabel
@onready var body_label: RichTextLabel = $Panel/Margin/Rows/BodyLabel
@onready var choices_box: VBoxContainer = $Panel/Margin/Rows/ChoicesBox
@onready var continue_button: Button = $Panel/Margin/Rows/Footer/ContinueButton


func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	_event = _find_event(target_event_id)
	if _event == null:
		event_title_label.text = "(event '%s' not found)" % str(target_event_id)
		body_label.text = ""
		continue_button.visible = true
		continue_button.grab_focus()
		return
	event_title_label.text = (_event.display_name if _event.display_name != "" else str(_event.id))
	_stream = RNG.get_stream("event_runtime")
	if target_event_id == &"the_awakening":
		GameState.intro_fired = true
	_visit(_event.entry_scene_id)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_continue_pressed()


func _find_event(id: StringName) -> EventDef:
	for def: EventDef in EventCatalog.get_all():
		if def.id == id:
			return def
	return null


func _visit(scene_id: StringName) -> void:
	var scene: EventScene = EventResolver.get_scene(_event, scene_id)
	if scene == null:
		push_warning("EventRunner: missing scene id %s" % scene_id)
		return
	_current_scene_id = scene_id
	for effect: String in scene.effects:
		EventEffectApplier.apply(effect, target_column, _event)
	_render_scene(scene)


func _render_scene(scene: EventScene) -> void:
	body_label.text = scene.body
	for child: Node in choices_box.get_children():
		child.queue_free()
	if scene.choices.is_empty():
		continue_button.visible = true
		continue_button.grab_focus()
		return
	continue_button.visible = false
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
		push_warning("EventRunner: choice has no outcomes")
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


func _on_continue_pressed() -> void:
	var target: String = return_path
	target_event_id = &""
	target_column = 0
	return_path = MAIN_MENU_PATH
	get_tree().change_scene_to_file(target)
