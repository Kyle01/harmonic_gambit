class_name PixelCircle
extends Control

## Renders a chunky pixel-art circle by filling a grid of square cells
## inside a midpoint-circle mask. Used as the medallion on gambit cards.

@export var pixel_size: int = 8:
	set(value):
		pixel_size = max(1, value)
		_refresh()

@export var radius_cells: int = 7:
	set(value):
		radius_cells = max(1, value)
		_refresh()

@export var color: Color = Color(0.85, 0.66, 0.16, 1):
	set(value):
		color = value
		queue_redraw()


func _ready() -> void:
	_refresh()


func _refresh() -> void:
	var dim: int = pixel_size * (2 * radius_cells + 1)
	custom_minimum_size = Vector2(dim, dim)
	queue_redraw()


func _draw() -> void:
	var r: int = radius_cells
	var r_sq: int = r * r
	for cx: int in range(2 * r + 1):
		var dx: int = cx - r
		for cy: int in range(2 * r + 1):
			var dy: int = cy - r
			if dx * dx + dy * dy <= r_sq:
				draw_rect(
					Rect2(cx * pixel_size, cy * pixel_size, pixel_size, pixel_size),
					color,
				)
