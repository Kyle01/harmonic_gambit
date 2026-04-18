extends Node

## Seeded RNG streams. All randomness routes through get_stream(name) so
## runs are reproducible from a seed. Never call randi/randf/randomize
## directly — see CLAUDE.md.

var _seed: int = 0
var _streams: Dictionary = {}


func set_seed(new_seed: int) -> void:
	_seed = new_seed
	_streams.clear()


func get_stream(stream_name: String) -> RandomNumberGenerator:
	if not _streams.has(stream_name):
		var r: RandomNumberGenerator = RandomNumberGenerator.new()
		r.seed = hash("%d:%s" % [_seed, stream_name])
		_streams[stream_name] = r
	return _streams[stream_name]
