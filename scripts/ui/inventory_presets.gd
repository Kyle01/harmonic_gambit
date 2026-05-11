class_name InventoryPresets
extends RefCounted

## View-only fixtures for the admin Inventory screen. Each preset returns a
## snapshot Dictionary the screen reads to render. No GameState mutation.
##
## Snapshot shape:
##   credits      : int
##   chips        : int
##   characters   : Array[Dictionary]  # { def: CharacterDef, level: int }
##   gambit_cards : Array[GambitCard]
##   band_cards   : Array[BandCard]
##   items        : Array[ItemDef]
##
## Duplicates are rendered as separate tiles — the screen iterates each
## array element produces one tile.

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
		"credits": 35,
		"chips": 1,
		"characters": [
			{"def": _character(&"singer"), "level": 1},
		],
		"gambit_cards": _gambit_cards([
			&"enemy_any",
			&"self_hp_40",
		]),
		"band_cards": [],
		"items": _items([&"hp_potion"]),
	}


static func _mid() -> Dictionary:
	return {
		"credits": 240,
		"chips": 6,
		"characters": [
			{"def": _character(&"singer"), "level": 4},
			{"def": _character(&"drummer"), "level": 3},
			{"def": _character(&"guitar"), "level": 3},
			{"def": _character(&"singer"), "level": 2},
		],
		"gambit_cards": _gambit_cards([
			&"enemy_any",
			&"enemy_least_hp",
			&"self_hp_40",
			&"ally_hp_40",
			&"ally_most_damaged",
			&"ally_dead",
			&"random_enemy",
		]),
		"band_cards": _band_cards([&"soloist", &"rock_band"]),
		"items": _items([&"hp_potion", &"hp_potion", &"phoenix_down"]),
	}


static func _late() -> Dictionary:
	return {
		"credits": 980,
		"chips": 14,
		"characters": [
			{"def": _character(&"singer"), "level": 9},
			{"def": _character(&"drummer"), "level": 8},
			{"def": _character(&"guitar"), "level": 8},
			{"def": _character(&"keyboard"), "level": 7},
			{"def": _character(&"bass"), "level": 7},
			{"def": _character(&"sax"), "level": 6},
			{"def": _character(&"singer"), "level": 5},
			{"def": _character(&"drummer"), "level": 6},
		],
		"gambit_cards": _gambit_cards([
			&"enemy_any",
			&"enemy_least_hp",
			&"enemy_most_hp",
			&"self_hp_20",
			&"self_hp_40",
			&"self_hp_60",
			&"ally_hp_20",
			&"ally_hp_40",
			&"ally_hp_60",
			&"ally_most_damaged",
			&"ally_dead",
			&"party_hp_avg_25",
			&"enemies_3plus",
			&"random_enemy",
		]),
		"band_cards": _band_cards([
			&"soloist",
			&"rock_band",
			&"jazz_trio",
			&"chamber_ensemble",
			&"bluegrass",
		]),
		"items": _items([
			&"hp_potion",
			&"hp_potion",
			&"hp_potion",
			&"phoenix_down",
			&"phoenix_down",
		]),
	}


static func _character(id: StringName) -> CharacterDef:
	for def: CharacterDef in CharacterCatalog.get_all():
		if def.id == id:
			return def
	push_warning("InventoryPresets: character not found: %s" % id)
	return null


static func _gambit_cards(ids: Array) -> Array[GambitCard]:
	var pool: Array[GambitCard] = GambitCardCatalog.get_all()
	var by_id: Dictionary = {}
	for card: GambitCard in pool:
		by_id[card.id] = card
	var result: Array[GambitCard] = []
	for id: StringName in ids:
		if by_id.has(id):
			result.append(by_id[id])
		else:
			push_warning("InventoryPresets: gambit card not found: %s" % id)
	return result


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
			push_warning("InventoryPresets: band card not found: %s" % id)
	return result


static func _items(ids: Array) -> Array[ItemDef]:
	var pool: Array[ItemDef] = ItemCatalog.get_all()
	var by_id: Dictionary = {}
	for item: ItemDef in pool:
		by_id[item.id] = item
	var result: Array[ItemDef] = []
	for id: StringName in ids:
		if by_id.has(id):
			result.append(by_id[id])
		else:
			push_warning("InventoryPresets: item not found: %s" % id)
	return result
