class_name EventChoice
extends Resource

## A clickable option presented to the player on an EventScene. Choosing it
## rolls a weighted EventOutcome from `outcomes` and navigates to that
## outcome's next_scene_id.
##
## requirement is a stringly-typed prerequisite expression evaluated against
## party state at runtime — empty means always available. v1 vocabulary
## (parsed by the runtime / demo runner, not by this Resource):
##   "instrument:<role>"     party has a member with that instrument_role
##   "credits:>=N"           party has at least N credits
##   "party_size:>=N"        party has at least N members
##
## In the read-only admin demo, gated choices render with a "[req: …]" prefix
## but never block selection. TODO: refactor to typed EventChoiceRequirement
## Resource subclasses once the inventory + run-state systems land.

@export var label: String = ""
@export var requirement: String = ""
@export var outcomes: Array[EventOutcome] = []
