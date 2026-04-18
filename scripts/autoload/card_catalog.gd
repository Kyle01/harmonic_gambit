extends Node

## Persistent cross-run catalog of discovered cards / enemies / characters.
## The only cross-run state besides achievements — see CLAUDE.md
## (no power meta-progression).

const SAVE_PATH: String = "user://catalog.tres"

var discovered_card_ids: Array[StringName] = []
var discovered_enemy_ids: Array[StringName] = []
var discovered_character_ids: Array[StringName] = []


func load_catalog() -> void:
	pass


func save_catalog() -> void:
	pass
