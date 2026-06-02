class_name MainMenu
extends Control

const REGION_RUN_PATH: String = "res://scenes/ui/region_run_test.tscn"
const INTRO_REGION_ID: StringName = &"the_introduction"

@onready var start_button: Button = $Buttons/StartButton
@onready var catalog_button: Button = $Buttons/CatalogButton
@onready var options_button: Button = $Buttons/OptionsButton
@onready var credits_button: Button = $Buttons/CreditsButton
@onready var admin_button: Button = $Buttons/AdminButton


func _ready() -> void:
	start_button.pressed.connect(_start_new_run)
	catalog_button.pressed.connect(_go.bind("res://scenes/ui/catalog_placeholder.tscn"))
	options_button.pressed.connect(_go.bind("res://scenes/ui/options_menu.tscn"))
	credits_button.pressed.connect(_go.bind("res://scenes/ui/credits_placeholder.tscn"))
	admin_button.pressed.connect(_go.bind("res://scenes/ui/admin_hub.tscn"))
	start_button.grab_focus()


func _start_new_run() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	var seed: int = rng.randi()
	GameState.reset_for_new_run(seed)
	var intro: RegionDef = _find_region(INTRO_REGION_ID)
	if intro == null:
		push_error("MainMenu: intro region '%s' not in RegionCatalog" % str(INTRO_REGION_ID))
		return
	RegionRunTest.target_region = intro
	RegionRunTest.return_to_realm = true
	RegionRunTest.is_run = true
	RegionRunTest.target_realm_column = 0
	RegionRunTest.active_region = null
	get_tree().change_scene_to_file(REGION_RUN_PATH)


func _find_region(id: StringName) -> RegionDef:
	for region: RegionDef in RegionCatalog.get_all():
		if region.id == id:
			return region
	return null


func _go(path: String) -> void:
	get_tree().change_scene_to_file(path)
