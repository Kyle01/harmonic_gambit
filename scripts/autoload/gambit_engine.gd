extends Node

## Evaluates an actor's gambit list in priority order and returns a
## ResolvedAction (action + resolved target). Pure function of actor state
## + world snapshot — no side effects.
##
## World must expose get_party() and get_enemies(), both returning
## Array[Node]. trigger_expr and target_selector are stringly-typed until
## a condition/selector registry lands.


func evaluate(actor: Node, world: Node) -> ResolvedAction:
	var gambits: Array = []
	if actor.has_method("get_gambits"):
		gambits = actor.get_gambits()
	elif "gambits" in actor:
		gambits = actor.gambits
	gambits.sort_custom(func(a: GambitDef, b: GambitDef) -> bool: return a.priority < b.priority)
	for g in gambits:
		if not _trigger_ok(g, world):
			continue
		var target: Node = _resolve_target(g, actor, world)
		if target == null:
			continue
		var resolved: ResolvedAction = ResolvedAction.new()
		resolved.action_id = g.action_id
		resolved.actor = actor
		resolved.target = target
		return resolved
	return null


func _trigger_ok(g: GambitDef, world: Node) -> bool:
	match g.trigger_expr:
		"":
			return true
		"any_enemy_alive":
			for e in world.get_enemies():
				if _alive(e):
					return true
			return false
		"any_ally_alive":
			for a in world.get_party():
				if _alive(a):
					return true
			return false
	return false


func _resolve_target(g: GambitDef, actor: Node, world: Node) -> Node:
	var opposing: Array[Node]
	if world.get_party().has(actor):
		opposing = world.get_enemies()
	else:
		opposing = world.get_party()
	match g.target_selector:
		&"nearest_enemy":
			var best: Node = null
			var best_dist: float = INF
			for t in opposing:
				if not _alive(t):
					continue
				var d: float = (actor.global_position as Vector2).distance_to(t.global_position)
				if d < best_dist:
					best_dist = d
					best = t
			return best
		&"any_enemy":
			for t in opposing:
				if _alive(t):
					return t
			return null
	return null


func _alive(actor: Node) -> bool:
	if actor == null or not is_instance_valid(actor):
		return false
	if not ("hp" in actor):
		return false
	return actor.hp > 0
