class_name RhythmPrompt
extends Control

## Minimal rhythm-prompt stub. One flash per pulse(). Real hit-window
## timing lands later; this exists so every action gets a visual beat
## per the three-pillar design.

@onready var panel: ColorRect = $ColorRect


func _ready() -> void:
	modulate.a = 0.0


func pulse() -> void:
	modulate.a = 1.0
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
