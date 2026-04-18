class_name Player
extends CharacterBody2D

## Player actor. hp/take_damage inlined for hello-world scope; will move
## to a HealthComponent once the component family lands.

signal health_changed(new_hp: int)
signal died

@export var max_hp: int = 30
@export var gambits: Array[GambitDef] = []

var hp: int = 0


func _ready() -> void:
	hp = max_hp


func take_damage(amount: int) -> void:
	hp = maxi(0, hp - amount)
	health_changed.emit(hp)
	if hp <= 0:
		died.emit()


func get_gambits() -> Array[GambitDef]:
	return gambits
