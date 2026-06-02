class_name MapNodeButton
extends Control

## Clickable map node visualized as a colored circle. The KIND_COLOR
## map is the only place node coloring lives — collapse it to all-white
## when we want the player blind to encounter type.

signal node_pressed(id: int)

const RADIUS: float = 18.0
const HIT_RADIUS: float = 24.0

const KIND_COLOR: Dictionary = {
	EventNode.Kind.COMBAT: Color(0.85, 0.32, 0.32, 1.0),
	EventNode.Kind.EVENT: Color(0.46, 0.62, 0.92, 1.0),
	EventNode.Kind.SHOP: Color(0.96, 0.78, 0.30, 1.0),
}

const _UNREVEALED_COLOR: Color = Color(0.95, 0.93, 0.84, 1.0)

const _OUTLINE_CURRENT: Color = Color(1.0, 1.0, 1.0, 1.0)
const _OUTLINE_AVAILABLE: Color = Color(0.95, 0.93, 0.84, 0.95)
const _OUTLINE_VISITED: Color = Color(0.70, 0.66, 0.58, 0.5)
const _OUTLINE_LOCKED: Color = Color(0.10, 0.10, 0.12, 0.6)

var node_id: int = -1
var kind: int = 0
var is_current: bool = false
var is_available: bool = false
var is_visited: bool = false


func setup(node: MapNode) -> void:
	node_id = node.id
	kind = node.kind
	custom_minimum_size = Vector2(HIT_RADIUS * 2.0, HIT_RADIUS * 2.0)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


func set_state(current: bool, available: bool, visited: bool) -> void:
	is_current = current
	is_available = available
	is_visited = visited
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not is_available or is_current:
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var local: Vector2 = mb.position - (size * 0.5)
			if local.length() <= HIT_RADIUS:
				node_pressed.emit(node_id)
				accept_event()


func _draw() -> void:
	var center: Vector2 = size * 0.5
	# Reveal rule: kind color reveals as soon as a node is visited — that
	# is, the moment its encounter has been resolved. The player's current
	# position is conveyed by the white outline rather than by suppressing
	# the fill, so a "just-completed" shop/combat shows its color while
	# you're still standing on it choosing your next move.
	var fill: Color
	if is_visited:
		fill = KIND_COLOR.get(kind, _UNREVEALED_COLOR).darkened(0.35)
	elif not is_available and not is_current:
		fill = _UNREVEALED_COLOR.darkened(0.55)
	else:
		fill = _UNREVEALED_COLOR
	var outline: Color = _outline_for_state()
	draw_circle(center, RADIUS + 2.0, outline)
	draw_circle(center, RADIUS, fill)


func _outline_for_state() -> Color:
	if is_current:
		return _OUTLINE_CURRENT
	if is_available:
		return _OUTLINE_AVAILABLE
	if is_visited:
		return _OUTLINE_VISITED
	return _OUTLINE_LOCKED
