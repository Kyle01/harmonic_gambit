class_name GambitDef
extends Resource

## A single gambit: "if <trigger> then <action> on <target>", at a given
## priority. GambitEngine walks the list in priority order (lowest first)
## and returns the first entry whose trigger resolves.
##
## trigger_expr and target_selector are stringly-typed for now; they will
## be parsed against a registry of conditions/selectors once that lands.

@export var action_id: StringName = &""
@export var trigger_expr: String = ""
@export var target_selector: StringName = &""
@export_range(0, 100) var priority: int = 0
