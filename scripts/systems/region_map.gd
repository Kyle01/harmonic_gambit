class_name RegionMap
extends Resource

## Runtime graph for a single region run. Built by RegionPlanner.plan();
## consumed by Region (current node + walk state) and the run scene
## (rendering). No defined exit — the player decides when to leave.
##
## Resource (not RefCounted) per CLAUDE.md migrability rule.

@export var nodes: Dictionary = {}  # id (int) -> MapNode
@export var entry_id: int = -1
