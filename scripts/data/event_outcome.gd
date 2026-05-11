class_name EventOutcome
extends Resource

## One weighted branch of an EventChoice. The choice rolls a single outcome
## via RNG.get_stream("event") (or "event_demo" in the admin runner) and then
## navigates to next_scene_id.
##
## Single deterministic outcome → single-element outcomes array with weight
## 1.0. Multi-outcome FTL-style ("50/50 the airlock breaks") is supported by
## the schema today; content authors opt in by adding a second EventOutcome.

@export var weight: float = 1.0
@export var next_scene_id: StringName = &""
