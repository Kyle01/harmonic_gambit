class_name GambitTuningScreen
extends Control

const ADMIN_HUB_PATH: String = "res://scenes/ui/admin_hub.tscn"

static var return_path: String = ADMIN_HUB_PATH

@onready var back_button: Button = $BackButton


func _ready() -> void:
	back_button.pressed.connect(_back)
	back_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_back()


func _back() -> void:
	var target := return_path
	return_path = ADMIN_HUB_PATH
	get_tree().change_scene_to_file(target)
