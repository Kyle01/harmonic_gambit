class_name PlaceholderPage
extends Control

@onready var back_button: Button = $BackButton


func _ready() -> void:
	back_button.pressed.connect(_back)
	back_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_back()


func _back() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
