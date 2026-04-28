class_name RegionDef
extends Resource

## A region of the Realm. The run map for a region is generated from
## encounter_distribution: a weight-per-Kind map sampled with a seeded
## RandomNumberGenerator stream. Eventually 6 regions live in
## resources/regions/, each with its own distribution.
##
## draw_encounters lives on the Resource for now (same precedent as
## CharacterDef.stat_at_level). If region-type behavior diverges later,
## lift it into scripts/systems/region_service.gd.

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


func draw_encounters(stream: RandomNumberGenerator, count: int) -> Array[int]:
	var rolls: Array[int] = []
	var total: float = 0.0
	for kind: int in encounter_distribution:
		total += float(encounter_distribution[kind])
	if total <= 0.0 or count <= 0:
		return rolls
	for _i: int in range(count):
		var pick: float = stream.randf() * total
		var running: float = 0.0
		var chosen: int = -1
		for kind: int in encounter_distribution:
			running += float(encounter_distribution[kind])
			if pick < running:
				chosen = kind
				break
		if chosen == -1:
			chosen = encounter_distribution.keys()[0]
		rolls.append(chosen)
	return rolls
