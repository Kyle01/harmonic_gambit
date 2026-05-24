class_name GambitTuningPresets
extends RefCounted

## View-only fixtures for the admin Gambit Tuning screen. Each preset returns
## a snapshot Dictionary the screen reads to render. No GameState mutation.
##
## Snapshot shape:
##   owned_chips : int
##   party_items : Array[ItemDef]
##   characters  : Array[Dictionary]
##     # { def: CharacterDef, level: int, chips_equipped: int, rows: Array[GambitDef] }
##
## chips_equipped == rows.size() per character — the screen treats one yellow
## row per chip on the focused character.

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
	var singer: CharacterDef = _character(&"singer")
	var drummer: CharacterDef = _character(&"drummer")
	return {
		"owned_chips": 3,
		"party_items": _party_items(),
		"characters":
		[
			{
				"def": singer,
				"level": 1,
				"chips_equipped": 1,
				"rows": [_row(singer, 1, &"sharp_pitch", &"enemy_any")],
			},
			{
				"def": drummer,
				"level": 3,
				"chips_equipped": 0,
				"rows": [] as Array[GambitDef],
			},
		],
	}


static func _mid() -> Dictionary:
	var singer: CharacterDef = _character(&"singer")
	var drummer: CharacterDef = _character(&"drummer")
	var guitar: CharacterDef = _character(&"guitar")
	var keyboard: CharacterDef = _character(&"keyboard")
	return {
		"owned_chips": 8,
		"party_items": _party_items(),
		"characters":
		[
			{
				"def": singer,
				"level": 5,
				"chips_equipped": 2,
				"rows":
				[
					_row(singer, 5, &"harmony", &"ally_most_damaged"),
					_row(singer, 5, &"sharp_pitch", &"enemy_most_hp"),
				],
			},
			{
				"def": drummer,
				"level": 4,
				"chips_equipped": 1,
				"rows": [_row(drummer, 4, &"downbeat", &"self")],
			},
			{
				"def": guitar,
				"level": 4,
				"chips_equipped": 1,
				"rows": [_row(guitar, 4, &"power_chord", &"enemy_least_hp")],
			},
			{
				"def": keyboard,
				"level": 3,
				"chips_equipped": 0,
				"rows": [] as Array[GambitDef],
			},
		],
	}


static func _late() -> Dictionary:
	var singer: CharacterDef = _character(&"singer")
	var drummer: CharacterDef = _character(&"drummer")
	var guitar: CharacterDef = _character(&"guitar")
	var keyboard: CharacterDef = _character(&"keyboard")
	var bass: CharacterDef = _character(&"bass")
	var sax: CharacterDef = _character(&"sax")
	return {
		"owned_chips": 15,
		"party_items": _party_items(),
		"characters":
		[
			{
				"def": singer,
				"level": 9,
				"chips_equipped": 3,
				"rows":
				[
					_row(singer, 9, &"harmony", &"ally_hp_40"),
					_row(singer, 9, &"echo_volley", &"enemies_2plus"),
					_row(singer, 9, &"sharp_pitch", &"enemy_any"),
				],
			},
			{
				"def": drummer,
				"level": 8,
				"chips_equipped": 2,
				"rows":
				[
					_row(drummer, 8, &"backbeat", &"self"),
					_row(drummer, 8, &"snare_hit", &"enemy_least_hp"),
				],
			},
			{
				"def": guitar,
				"level": 7,
				"chips_equipped": 2,
				"rows":
				[
					_row(guitar, 7, &"feedback", &"enemy_most_hp"),
					_row(guitar, 7, &"riff", &"enemy_any"),
				],
			},
			{
				"def": keyboard,
				"level": 7,
				"chips_equipped": 1,
				"rows": [_row(keyboard, 7, &"arpeggio", &"ally_most_damaged")],
			},
			{
				"def": bass,
				"level": 6,
				"chips_equipped": 1,
				"rows": [_row(bass, 6, &"deep_pluck", &"enemy_any")],
			},
			{
				"def": sax,
				"level": 7,
				"chips_equipped": 1,
				"rows": [_row(sax, 7, &"blow", &"enemy_any")],
			},
		],
	}


static func _row(
	def: CharacterDef, level: int, action_id: StringName, card_id: StringName
) -> GambitDef:
	var row: GambitDef = GambitDef.new()
	row.action_id = action_id if _character_knows(def, action_id, level) else &""
	var card: GambitCard = _card(card_id)
	if card != null:
		row.trigger_expr = card.trigger_expr
		row.target_selector = card.target_selector
	row.priority = 0
	return row


static func _character(id: StringName) -> CharacterDef:
	for def: CharacterDef in CharacterCatalog.get_all():
		if def.id == id:
			return def
	push_warning("GambitTuningPresets: character not found: %s" % id)
	return null


static func _card(id: StringName) -> GambitCard:
	for card: GambitCard in GambitCardCatalog.get_all():
		if card.id == id:
			return card
	push_warning("GambitTuningPresets: gambit card not found: %s" % id)
	return null


static func _character_knows(def: CharacterDef, ability_id: StringName, level: int) -> bool:
	if def == null:
		return false
	for entry: LearnEntry in def.learn_list:
		if entry.ability != null and entry.ability.id == ability_id and entry.level <= level:
			return true
	push_warning(
		"GambitTuningPresets: %s does not know %s at level %d" % [def.id, ability_id, level]
	)
	return false


static func _party_items() -> Array[ItemDef]:
	return ItemCatalog.get_all()
