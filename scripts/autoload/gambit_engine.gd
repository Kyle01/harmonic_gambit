extends Node

## Evaluates an actor's gambit list in priority order and returns a
## ResolvedAction (action + resolved target). Pure function of actor state
## + world snapshot — no side effects.
##
## ResolvedAction is not yet a Resource; return type is Resource for now
## and will tighten once the data schema lands.


func evaluate(_actor: Node, _world: Node) -> Resource:
	return null
