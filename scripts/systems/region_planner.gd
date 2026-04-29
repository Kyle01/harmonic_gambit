class_name RegionPlanner
extends RefCounted

## Builds a runtime Region from a RegionDef + RNG stream. The weighted-
## draw algorithm lives here, not on the data Resource. Stateless;
## static-only entry point.


static func plan(def: RegionDef, stream: RandomNumberGenerator) -> Region:
	var region: Region = Region.new()
	region.def = def
	region.encounters = _draw_encounters(def, stream, def.encounter_count)
	region.current_index = 0
	return region


static func _draw_encounters(
	def: RegionDef, stream: RandomNumberGenerator, count: int
) -> Array[int]:
	var rolls: Array[int] = []
	var dist: Dictionary = def.encounter_distribution
	var total: float = 0.0
	for kind: int in dist:
		total += float(dist[kind])
	if total <= 0.0 or count <= 0:
		return rolls
	for _i: int in range(count):
		var pick: float = stream.randf() * total
		var running: float = 0.0
		var chosen: int = -1
		for kind: int in dist:
			running += float(dist[kind])
			if pick < running:
				chosen = kind
				break
		if chosen == -1:
			chosen = dist.keys()[0]
		rolls.append(chosen)
	return rolls
