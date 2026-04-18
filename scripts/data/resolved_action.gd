class_name ResolvedAction
extends Resource

## Output of GambitEngine.evaluate. Transient — not saved to disk, just
## passed to whatever applies actions in the combat loop.

var action_id: StringName = &""
var actor: Node = null
var target: Node = null
