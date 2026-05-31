class_name InventoryScreen
extends Control

## Inventory screen. ADMIN mode (default) renders the Early/Mid/Late preset
## fixtures so dev can eyeball card / item layouts at every snapshot. RUN
## mode hides the preset row and renders from `GameState.owned_*` /
## `GameState.inventory` / `GameState.credits` / `GameState.chips`.
##
## `mode` and `return_path` are static so a launcher can configure them
## once before `change_scene_to_file`. `_exit_tree` resets both to their
## ADMIN defaults so a stale RUN configuration can't survive into the
## next entry.

enum Mode { ADMIN, RUN }

const ADMIN_HUB_PATH: String = "res://scenes/ui/admin_hub.tscn"
const GAMBIT_ROW_SCENE: PackedScene = preload("res://scenes/ui/components/gambit_row.tscn")
const ITEM_ICON_SCENE: PackedScene = preload("res://scenes/ui/components/item_icon.tscn")

static var mode: Mode = Mode.ADMIN
static var return_path: String = ADMIN_HUB_PATH

@onready var preset_row: HBoxContainer = $PresetRow
@onready var early_button: Button = $PresetRow/EarlyButton
@onready var mid_button: Button = $PresetRow/MidButton
@onready var late_button: Button = $PresetRow/LateButton
@onready var back_button: Button = $BackButton
@onready var characters_cascade: CardCascade = $CharactersCascade
@onready var band_cards_cascade: CardCascade = $BandCardsCascade
@onready var gambit_list: VBoxContainer = $GambitScroll/GambitList
@onready var credits_value: Label = $ChipsCreditsRow/CreditsPanel/Margin/Row/CreditsValue
@onready var chips_value: Label = $ChipsCreditsRow/ChipsPanel/Margin/Row/ChipsValue
@onready var items_row: HBoxContainer = $ItemsPanel/Margin/Rows/ItemsRow


func _ready() -> void:
	back_button.pressed.connect(_back)
	match mode:
		Mode.ADMIN:
			_load_admin()
		Mode.RUN:
			_load_run()


func _exit_tree() -> void:
	mode = Mode.ADMIN
	return_path = ADMIN_HUB_PATH


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_back()


func _load_admin() -> void:
	preset_row.visible = true
	early_button.pressed.connect(_load_preset.bind(InventoryPresets.Preset.EARLY))
	mid_button.pressed.connect(_load_preset.bind(InventoryPresets.Preset.MID))
	late_button.pressed.connect(_load_preset.bind(InventoryPresets.Preset.LATE))
	_load_preset(InventoryPresets.Preset.EARLY)
	early_button.grab_focus()


func _load_run() -> void:
	preset_row.visible = false
	_render(
		{
			"credits": GameState.credits,
			"chips": GameState.chips,
			"characters": _owned_character_rows(),
			"band_cards": GameState.owned_band_cards,
			"gambit_cards": GameState.owned_gambit_cards,
			"items": GameState.inventory,
		}
	)
	back_button.grab_focus()


func _owned_character_rows() -> Array:
	# Inventory's character renderer expects `{def, level}` entries. The
	# run-state owned_characters list is just defs; level lives in the
	# party (Array[Node]) once instantiated. Until the combat-runtime
	# PR lands, render every owned character at level 1.
	var rows: Array = []
	for def: CharacterDef in GameState.owned_characters:
		rows.append({"def": def, "level": 1})
	return rows


func _load_preset(preset: InventoryPresets.Preset) -> void:
	var snap: Dictionary = InventoryPresets.get_snapshot(preset)
	_render(snap)


func _render(snap: Dictionary) -> void:
	credits_value.text = str(snap["credits"])
	chips_value.text = str(snap["chips"])
	characters_cascade.set_entries(_characters_to_entries(snap["characters"]))
	band_cards_cascade.set_entries(_band_cards_to_entries(snap["band_cards"]))
	_render_gambit_list(snap["gambit_cards"])
	_render_items(snap["items"])


func _characters_to_entries(rows: Array) -> Array:
	var built: Array = []
	for entry: Dictionary in rows:
		var def: CharacterDef = entry["def"]
		if def == null:
			continue
		var name_str: String = def.display_name if def.display_name != "" else str(def.id)
		var label: String = "%s - Level %d" % [name_str, entry["level"]]
		built.append({"art": def.portrait, "label": label, "_sort_key": name_str})
	built.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return (a["_sort_key"] as String).naturalnocasecmp_to(b["_sort_key"] as String) < 0
	)
	return built


func _band_cards_to_entries(cards: Array) -> Array:
	var built: Array = []
	for card: BandCard in cards:
		var name_str: String = card.display_name if card.display_name != "" else str(card.id)
		built.append({"art": card.art, "label": name_str, "_sort_key": name_str})
	built.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return (a["_sort_key"] as String).naturalnocasecmp_to(b["_sort_key"] as String) < 0
	)
	return built


func _render_gambit_list(cards: Array) -> void:
	for child: Node in gambit_list.get_children():
		child.queue_free()
	for card: GambitCard in cards:
		var row: GambitRow = GAMBIT_ROW_SCENE.instantiate() as GambitRow
		gambit_list.add_child(row)
		row.setup(card)


func _render_items(items: Array) -> void:
	for child: Node in items_row.get_children():
		child.queue_free()
	var counts: Dictionary = {}
	var order: Array[ItemDef] = []
	for item: ItemDef in items:
		if not counts.has(item.id):
			counts[item.id] = 0
			order.append(item)
		counts[item.id] = (counts[item.id] as int) + 1
	for item: ItemDef in order:
		var icon: ItemIcon = ITEM_ICON_SCENE.instantiate() as ItemIcon
		items_row.add_child(icon)
		icon.setup(item, counts[item.id])


func _back() -> void:
	var target: String = ADMIN_HUB_PATH if mode == Mode.ADMIN else return_path
	get_tree().change_scene_to_file(target)
