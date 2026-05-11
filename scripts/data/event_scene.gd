class_name EventScene
extends Resource

## A node in an EventDef's scene tree. Terminal if `choices.is_empty()`
## (the runner shows an "End of event" continue button).
##
## `effects` is a stringly-typed mini-DSL applied on entering this scene.
## v1 vocabulary (interpreted by the runtime / demo runner):
##   "gain_credits:N"        gain ceil(N * column_mult) credits
##   "heal_party:full"       fully heal every party member
##   "heal_party:N"          heal each member by ceil(N * column_mult) HP
##   "recruit:<id>:N"        recruit CharacterDef <id> at level
##                           ceil(N * column_mult)
## "full" is a sentinel that never scales. Numeric arguments scale via the
## owning EventDef.column_effect_multiplier and the column the event fires
## in. TODO: refactor to typed EventEffect Resource subclasses once the
## inventory system lands and the effect vocabulary stabilizes.

@export var id: StringName = &""
@export_multiline var body: String = ""
@export var choices: Array[EventChoice] = []
@export var effects: Array[String] = []
