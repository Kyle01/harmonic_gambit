class_name RegionRunTest
extends Control

const ADMIN_REGIONS_PATH: String = "res://scenes/ui/admin_regions.tscn"

static var target_region: RegionDef = null

@onready var background_rect: TextureRect = $Background
@onready var next_region_button: Button = $NextRegionButton


func _ready() -> void:
	if target_region != null and target_region.background != null:
		background_rect.texture = target_region.background
	next_region_button.pressed.connect(_on_next_region)
	next_region_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_next_region()


func _on_next_region() -> void:
	target_region = null
	get_tree().change_scene_to_file(ADMIN_REGIONS_PATH)
