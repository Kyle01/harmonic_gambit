class_name CombatSkipOverlay
extends CanvasLayer

## Combat is a placeholder until the real combat-runtime PR lands. This
## overlay sits on top of `test_arena` and exposes the only resolution
## path the run loop currently understands: a Skip button that grants a
## flat +5 credits and exits to `return_path`. Both the admin Combat tile
## (via `combat_arena.tscn`) and the PR3 run-path COMBAT-kind node will
## instance this same overlay.
##
## `return_path` is set by whoever launched the combat scene before
## `change_scene_to_file`. Reset to `MAIN_MENU_PATH` on exit so a stale
## value can't survive into the next combat entry.

const MAIN_MENU_PATH: String = "res://scenes/ui/main_menu.tscn"
const SKIP_REWARD: int = 5

static var return_path: String = MAIN_MENU_PATH

@onready var skip_button: Button = $Panel/Margin/Rows/SkipButton


func _ready() -> void:
	skip_button.pressed.connect(_on_skip_pressed)
	skip_button.grab_focus()


func _on_skip_pressed() -> void:
	GameState.credits += SKIP_REWARD
	EventBus.credits_changed.emit(GameState.credits)
	var target: String = return_path
	return_path = MAIN_MENU_PATH
	get_tree().change_scene_to_file(target)
