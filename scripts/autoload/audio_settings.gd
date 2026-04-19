extends Node

## Authoritative volume state for the Music and SFX audio buses.
## Persists to user://settings.tres (mirrors the CardCatalog save pattern).
## Applied once at _ready; then on every slider change. UI subscribes to the
## EventBus `*_volume_changed` signals, never calls AudioServer directly.

const SAVE_PATH: String = "user://settings.tres"
const SILENCE_DB: float = -60.0

var _settings: UserSettings
var _music_bus_idx: int = -1
var _sfx_bus_idx: int = -1


func _ready() -> void:
	_settings = _load_or_default()
	_music_bus_idx = AudioServer.get_bus_index("Music")
	_sfx_bus_idx = AudioServer.get_bus_index("SFX")
	_apply(_music_bus_idx, _settings.music_volume_linear)
	_apply(_sfx_bus_idx, _settings.sfx_volume_linear)


func get_music_volume() -> float:
	return _settings.music_volume_linear


func get_sfx_volume() -> float:
	return _settings.sfx_volume_linear


func set_music_volume(linear: float) -> void:
	var value: float = clampf(linear, 0.0, 1.0)
	_settings.music_volume_linear = value
	_apply(_music_bus_idx, value)
	_save()
	EventBus.music_volume_changed.emit(value)


func set_sfx_volume(linear: float) -> void:
	var value: float = clampf(linear, 0.0, 1.0)
	_settings.sfx_volume_linear = value
	_apply(_sfx_bus_idx, value)
	_save()
	EventBus.sfx_volume_changed.emit(value)


func _apply(bus_idx: int, linear: float) -> void:
	if bus_idx < 0:
		return
	var db: float = SILENCE_DB if linear <= 0.0 else linear_to_db(linear)
	AudioServer.set_bus_volume_db(bus_idx, db)


func _load_or_default() -> UserSettings:
	if ResourceLoader.exists(SAVE_PATH):
		var loaded: Resource = ResourceLoader.load(SAVE_PATH)
		if loaded is UserSettings:
			return loaded
	return UserSettings.new()


func _save() -> void:
	var err: int = ResourceSaver.save(_settings, SAVE_PATH)
	if err != OK:
		push_warning("AudioSettings: save failed (%d) to %s" % [err, SAVE_PATH])
