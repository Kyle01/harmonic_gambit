class_name MainMenu
extends Control

@onready var start_button: Button = $Buttons/StartButton
@onready var catalog_button: Button = $Buttons/CatalogButton
@onready var options_button: Button = $Buttons/OptionsButton
@onready var credits_button: Button = $Buttons/CreditsButton
@onready var admin_button: Button = $Buttons/AdminButton


func _ready() -> void:
	start_button.pressed.connect(_go.bind("res://scenes/ui/start_placeholder.tscn"))
	catalog_button.pressed.connect(_go.bind("res://scenes/ui/catalog_placeholder.tscn"))
	options_button.pressed.connect(_go.bind("res://scenes/ui/options_menu.tscn"))
	credits_button.pressed.connect(_go.bind("res://scenes/ui/credits_placeholder.tscn"))
	admin_button.pressed.connect(_go.bind("res://scenes/ui/admin_placeholder.tscn"))
	start_button.grab_focus()


func _go(path: String) -> void:
	get_tree().change_scene_to_file(path)
