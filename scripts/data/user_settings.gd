class_name UserSettings
extends Resource

## Persistent user settings. Saved to user://settings.tres by AudioSettings.
## Volumes are linear 0.0..1.0; the audio layer converts to decibels.

@export var music_volume_linear: float = 0.0
@export var sfx_volume_linear: float = 0.8
