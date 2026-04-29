class_name Region
extends RefCounted

## Runtime counterpart of RegionDef. Holds the rolled encounter sequence
## and walk progress for the region the player is currently traveling
## through. Created by RegionPlanner.plan(); lives only as long as
## something holds a reference. RegionDef stays the template; Region is
## the live thing.

var def: RegionDef = null
var encounters: Array[int] = []
var current_index: int = 0


func is_complete() -> bool:
	return current_index >= encounters.size()


func peek() -> int:
	if is_complete():
		return -1
	return encounters[current_index]


func advance() -> int:
	if is_complete():
		return -1
	var kind: int = encounters[current_index]
	current_index += 1
	return kind
