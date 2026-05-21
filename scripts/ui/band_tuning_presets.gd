class_name BandTuningPresets
extends RefCounted

## View-only fixtures for the admin Band Tuning screen. Each preset returns a
## snapshot Dictionary the screen reads to render. No GameState mutation.
##
## Snapshot shape:
##   characters : Array[Dictionary]  # { def: CharacterDef, level: int, chips: int }
##   band_cards : Array[BandCard]

enum Preset { EARLY, MID, LATE }


static func get_snapshot(preset: Preset) -> Dictionary:
	match preset:
		Preset.EARLY:
			return _early()
		Preset.MID:
			return _mid()
		Preset.LATE:
			return _late()
	return _early()


static func _early() -> Dictionary:
	return {
		"characters":
		[
			{"def": _character(&"singer"), "level": 1, "chips": 0},
		],
		"band_cards": _band_cards([&"soloist"]),
	}


static func _mid() -> Dictionary:
	return {
		"characters":
		[
			{"def": _character(&"singer"), "level": 4, "chips": 2},
			{"def": _character(&"drummer"), "level": 3, "chips": 1},
			{"def": _character(&"guitar"), "level": 3, "chips": 1},
			{"def": _character(&"singer"), "level": 2, "chips": 1},
		],
		"band_cards": _band_cards([&"soloist", &"rock_band"]),
	}


static func _late() -> Dictionary:
	return {
		"characters":
		[
			{"def": _character(&"singer"), "level": 9, "chips": 4},
			{"def": _character(&"drummer"), "level": 8, "chips": 3},
			{"def": _character(&"guitar"), "level": 8, "chips": 3},
			{"def": _character(&"keyboard"), "level": 7, "chips": 3},
			{"def": _character(&"bass"), "level": 7, "chips": 2},
			{"def": _character(&"sax"), "level": 6, "chips": 2},
			{"def": _character(&"singer"), "level": 5, "chips": 2},
			{"def": _character(&"drummer"), "level": 6, "chips": 2},
		],
		"band_cards":
		_band_cards(
			[
				&"soloist",
				&"rock_band",
				&"jazz_trio",
				&"chamber_ensemble",
				&"bluegrass",
			]
		),
	}


static func _character(id: StringName) -> CharacterDef:
	for def: CharacterDef in CharacterCatalog.get_all():
		if def.id == id:
			return def
	push_warning("BandTuningPresets: character not found: %s" % id)
	return null


static func _band_cards(ids: Array) -> Array[BandCard]:
	var pool: Array[BandCard] = BandCardCatalog.get_all()
	var by_id: Dictionary = {}
	for card: BandCard in pool:
		by_id[card.id] = card
	var result: Array[BandCard] = []
	for id: StringName in ids:
		if by_id.has(id):
			result.append(by_id[id])
		else:
			push_warning("BandTuningPresets: band card not found: %s" % id)
	return result
