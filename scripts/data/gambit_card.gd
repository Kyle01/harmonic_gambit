class_name GambitCard
extends Card

## A collectible gambit card. Each card bundles a trigger condition with a
## target selector. The action is supplied at equip-time from the owning
## character's known abilities (learn_list), and priority comes from the
## slot order on the equipped character — so neither lives on the card.
##
## trigger_expr / target_selector are stringly-typed for v1; GambitEngine
## owns the canonical vocabulary. New strings here are content-only until
## the engine evaluator catches up.

@export var trigger_expr: String = ""
@export var target_selector: StringName = &""
