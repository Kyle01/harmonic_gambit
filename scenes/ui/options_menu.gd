class_name OptionsMenu
extends Control

## Options screen. Music + SFX volume sliders backed by AudioSettings.
## Changes apply live; AudioSettings persists each change to
## user://settings.tres.

@onready var music_slider: HSlider = $Rows/MusicRow/Slider
@onready var music_readout: Label = $Rows/MusicRow/Readout
@onready var sfx_slider: HSlider = $Rows/SFXRow/Slider
@onready var sfx_readout: Label = $Rows/SFXRow/Readout
@onready var back_button: Button = $BackButton


func _ready() -> void:
	music_slider.value = AudioSettings.get_music_volume()
	sfx_slider.value = AudioSettings.get_sfx_volume()
	_update_readout(music_readout, music_slider.value)
	_update_readout(sfx_readout, sfx_slider.value)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	back_button.pressed.connect(_back)
	music_slider.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_back()


func _on_music_changed(value: float) -> void:
	AudioSettings.set_music_volume(value)
	_update_readout(music_readout, value)


func _on_sfx_changed(value: float) -> void:
	AudioSettings.set_sfx_volume(value)
	_update_readout(sfx_readout, value)


func _update_readout(label: Label, value: float) -> void:
	label.text = "%d%%" % roundi(value * 100.0)


func _back() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
