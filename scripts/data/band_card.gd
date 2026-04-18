class_name BandCard
extends Card

## A band composition card (Jazz Trio, Power Trio, String Quartet, etc.).
## BandComposer grants bonus_payload when the party's instrument roles
## match required_roles.
##
## bonus_payload is Resource for now — it will tighten to a concrete
## BandBonus type once that schema lands.

@export var required_roles: Array[StringName] = []
@export var bonus_payload: Resource = null
