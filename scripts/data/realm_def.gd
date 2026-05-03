class_name RealmDef
extends Resource

## The Realm: the run-level meta-map shape. A single fixed-shape graph of
## 12 region-nodes laid out in 6 columns of 1-2-3-3-2-1. Col 0 is always
## the intro region; col 5 is always the finale; cols 1..4 are weighted-
## random draws from the catalog. A 1:1 lane lock between col 2 and col 3
## (the third and fourth columns, 0-indexed 2 and 3) forces the player to
## commit to a path before the second half of the run.
##
## Hand-tune middle_column_weights in the inspector. Weights per column
## sum to 100 (matches RegionDef.encounter_distribution convention).
##
## To produce a runtime Realm from a RealmDef, call
## RealmPlanner.plan(def, RegionCatalog.get_all(), RNG.get_stream("realm")).

## Fixed shape of the realm: column counts left-to-right.
const COLUMN_COUNTS: Array[int] = [1, 2, 3, 3, 2, 1]

@export var id: StringName = &"the_realm"
@export var display_name: String = "The Realm"

@export_group("Fixed regions")
## Column 0 is always this region (the introduction).
@export var intro_region_id: StringName = &"the_introduction"
## Column 5 is always this region (the finale).
@export var finale_region_id: StringName = &"the_finale"

@export_group("Middle column weights")
## One Dictionary per middle column (cols 1..4 = indices 0..3 of this
## array). Keys are RegionDef.id (StringName); values are weights that
## sum to 100. Cols 0 and 5 are not in this array — they are fixed by
## intro_region_id / finale_region_id. Repeats across nodes are allowed.
@export var middle_column_weights: Array[Dictionary] = [
	{
		&"the_city": 25.0,
		&"the_depths": 25.0,
		&"the_expanse": 35.0,
		&"the_warp": 15.0,
	},
	{
		&"the_city": 20.0,
		&"the_depths": 40.0,
		&"the_expanse": 20.0,
		&"the_warp": 20.0,
	},
	{
		&"the_city": 15.0,
		&"the_depths": 35.0,
		&"the_expanse": 20.0,
		&"the_warp": 30.0,
	},
	{
		&"the_city": 0.0,
		&"the_depths": 25.0,
		&"the_expanse": 25.0,
		&"the_warp": 50.0,
	},
]

@export_group("Presentation")
## Abstract color-field background painted behind the node graph.
@export var background: Texture2D = null


## Editor-side sanity check: each middle column's weights sum to ~100.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	for i: int in range(middle_column_weights.size()):
		var col: Dictionary = middle_column_weights[i]
		var total: float = 0.0
		for v: Variant in col.values():
			total += float(v)
		if absf(total - 100.0) > 0.01:
			warnings.append("middle_column_weights[%d] sums to %.2f (should be 100)" % [i, total])
	return warnings
