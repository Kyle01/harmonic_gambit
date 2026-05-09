class_name EventResolver
extends RefCounted

## Pure-function resolver for EventDef walks. Stateless; static-only entry
## points. Both the admin demo runner and the (deferred) runtime event
## screen call into here so the scene-lookup and column-scaling formula
## live in exactly one place.
##
## Keeping these out of EventDef preserves the data layer's no-logic rule
## (CLAUDE.md) — schema Resources stay POCO-shaped, which also keeps the
## C# port path easy.


## Find a scene by id within an event. Returns null if not found.
static func get_scene(def: EventDef, scene_id: StringName) -> EventScene:
	if def == null:
		return null
	for scene: EventScene in def.scenes:
		if scene.id == scene_id:
			return scene
	return null


## Per-column scaling multiplier. column is the realm column index (0-5).
## Effective multiplier at column C = 1.0 + C * column_effect_multiplier.
## With coeff = 0.5: col 0 → 1.0×, col 3 → 2.5×, col 5 → 3.5×.
static func column_multiplier(def: EventDef, column: int) -> float:
	if def == null:
		return 1.0
	return 1.0 + float(column) * def.column_effect_multiplier
