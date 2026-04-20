class_name AdminCombat
extends Node2D

const ADMIN_HUB_PATH: String = "res://scenes/ui/admin_placeholder.tscn"

@onready var back_button: Button = $BackLayer/BackButton


func _ready() -> void:
	back_button.pressed.connect(_back)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_back()


func _back() -> void:
	get_tree().change_scene_to_file(ADMIN_HUB_PATH)
