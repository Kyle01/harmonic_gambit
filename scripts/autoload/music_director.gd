extends Node

## Owns the active music AudioStreamPlayer across scene transitions.
## Scenes do not host their own music players — they call
## `MusicDirector.play(stream)` so that tracks spanning multiple scenes
## (main menu → options → main menu) don't restart on scene change.
## Routes through the Music bus; volume is controlled by AudioSettings.

const THEME: AudioStream = preload("res://assets/audio/music/theme.mp3")

var _player: AudioStreamPlayer


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = &"Music"
	add_child(_player)
	play(THEME)


func play(stream: AudioStream) -> void:
	if _player.stream == stream and _player.playing:
		return
	_player.stream = stream
	_player.play()


func stop() -> void:
	_player.stop()


func is_playing() -> bool:
	return _player.playing
