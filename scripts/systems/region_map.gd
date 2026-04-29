class_name RegionMap
extends RefCounted

## Runtime graph for a single region run. Built by RegionPlanner.plan();
## consumed by Region (current node + walk state) and the run scene
## (rendering). No defined exit — the player decides when to leave.

var nodes: Dictionary = {}  # id (int) -> MapNode
var entry_id: int = -1
