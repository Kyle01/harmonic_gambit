class_name AdminPlayableCharacters
extends Control

const ADMIN_HUB_PATH: String = "res://scenes/ui/admin_placeholder.tscn"
const CHARACTERS_DIR: String = "res://resources/characters"
const CARD_TILE_SCENE: PackedScene = preload("res://scenes/ui/components/character_card_tile.tscn")

@onready var card_grid: GridContainer = $Scroll/CardGrid
@onready var empty_label: Label = $EmptyLabel
@onready var back_button: Button = $BackButton


func _ready() -> void:
	back_button.pressed.connect(_back)
	_populate()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_back()


func _populate() -> void:
	var defs: Array[CharacterDef] = _load_character_defs()
	empty_label.visible = defs.is_empty()
	for def: CharacterDef in defs:
		var tile: CharacterCardTile = CARD_TILE_SCENE.instantiate() as CharacterCardTile
		card_grid.add_child(tile)
		tile.setup(def)


func _load_character_defs() -> Array[CharacterDef]:
	var results: Array[CharacterDef] = []
	var dir: DirAccess = DirAccess.open(CHARACTERS_DIR)
	if dir == null:
		push_warning("AdminPlayableCharacters: cannot open %s" % CHARACTERS_DIR)
		return results
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and _is_tres(file_name):
			var path: String = "%s/%s" % [CHARACTERS_DIR, file_name]
			var res: Resource = load(path)
			if res is CharacterDef:
				results.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()
	return results


func _is_tres(file_name: String) -> bool:
	return file_name.ends_with(".tres") or file_name.ends_with(".res")


func _back() -> void:
	get_tree().change_scene_to_file(ADMIN_HUB_PATH)
