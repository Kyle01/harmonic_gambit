class_name EventDef
extends Resource

## An FTL-inspired narrative event. A scene tree of body text + branching
## choices, with weighted outcomes and stringly-typed effects. Fires on
## EVENT-kind realm nodes (runtime hookup deferred — for now the admin
## Events screen renders the catalog and a read-only demo runner walks the
## scene tree).
##
## findable_columns / findable_regions are inclusion sets with no sentinel:
## empty literally means "this event fires nowhere." Schema defaults
## enumerate the full current set so newly-authored events default to
## discoverable everywhere; authors scope by removing entries. When a new
## region is added, update the findable_regions default AND audit every
## existing event .tres to decide whether the new region applies.
##
## column_effect_multiplier defines per-column scaling: the effective
## multiplier at column C = 1.0 + C * column_effect_multiplier. With
## coeff = 0.5: col 0 → 1.0×, col 3 → 2.5×, col 5 → 3.5×. The runtime
## applies this to numeric arguments inside an EventScene.effects entry
## (e.g. "gain_credits:5" at col 3 with coeff 0.5 → 13 credits).

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var art: Texture2D = null

@export_group("Discovery")
@export var findable_columns: Array[int] = [0, 1, 2, 3, 4, 5]
@export var findable_regions: Array[StringName] = [
	&"the_introduction",
	&"the_city",
	&"the_expanse",
	&"the_depths",
	&"the_warp",
	&"the_finale",
]
@export var column_effect_multiplier: float = 0.0

@export_group("Scene tree")
@export var entry_scene_id: StringName = &""
@export var scenes: Array[EventScene] = []


## Resolve a scene by id. Returns null if not found.
func get_scene(scene_id: StringName) -> EventScene:
	for scene: EventScene in scenes:
		if scene.id == scene_id:
			return scene
	return null


## Per-column scaling multiplier. column is the realm column index (0-5).
## See class doc for the formula.
func column_multiplier(column: int) -> float:
	return 1.0 + float(column) * column_effect_multiplier
