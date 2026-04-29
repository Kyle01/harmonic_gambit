class_name RegionDef
extends Resource

## A region of the Realm. Pure data: id, display name, encounter count,
## the weight-per-Kind distribution that defines how the region's run map
## is drawn, and presentation. Eventually 6 regions live in
## resources/regions/, each with its own distribution.
##
## To produce a runtime Region from a RegionDef, call
## RegionPlanner.plan(def, RNG.get_stream("region_<id>")). The planner
## owns the generation algorithm; this Resource owns only the data.

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var encounter_count: int = 8

@export_group("Presentation")
@export var background: Texture2D = null

@export_group("Encounters")
## Weights keyed by EventNode.Kind (int). Sum need not be 100; values
## are normalized at roll time. Zero is a valid weight (excludes a Kind).
@export var encounter_distribution: Dictionary = {
	EventNode.Kind.COMBAT: 0,
	EventNode.Kind.EVENT: 0,
	EventNode.Kind.SHOP: 0,
}
