class_name AdminCombat
extends Control

const ADMIN_HUB_PATH: String = "res://scenes/ui/admin_hub.tscn"
const BAND_TUNING_PATH: String = "res://scenes/ui/band_tuning.tscn"
const COMBAT_ARENA_PATH: String = "res://scenes/ui/combat_arena.tscn"
const LOBBY_PATH: String = "res://scenes/ui/admin_combat.tscn"

@onready var band_tuning_button: Button = $BandTuningButton
@onready var start_combat_button: Button = $StartCombatButton
@onready var back_button: Button = $BackButton


func _ready() -> void:
	band_tuning_button.pressed.connect(_on_band_tuning_pressed)
	start_combat_button.pressed.connect(_on_start_combat_pressed)
	back_button.pressed.connect(_back)
	band_tuning_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_back()


func _on_band_tuning_pressed() -> void:
	BandTuningScreen.return_path = LOBBY_PATH
	get_tree().change_scene_to_file(BAND_TUNING_PATH)


func _on_start_combat_pressed() -> void:
	CombatSkipOverlay.return_path = ADMIN_HUB_PATH
	get_tree().change_scene_to_file(COMBAT_ARENA_PATH)


func _back() -> void:
	get_tree().change_scene_to_file(ADMIN_HUB_PATH)
