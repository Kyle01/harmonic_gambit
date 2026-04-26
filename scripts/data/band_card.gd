class_name BandCard
extends Card

## An equippable band card. When activation_requirements are satisfied
## by the current party, applied_effects modify the run.
##
## Both arrays are display-only Strings for v1 — admin viewer renders them
## verbatim. They will tighten to typed Resources (BandEffect /
## BandRequirement) once runtime composition lands.

@export var applied_effects: Array[String] = []
@export var activation_requirements: Array[String] = []
