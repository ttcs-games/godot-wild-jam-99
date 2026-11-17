extends Node2D

@onready var grid := get_parent()

func _draw() -> void:
	if grid._lava_visual_row >= grid.grid_height:
		return
	var lava_y: float = grid._lava_visual_row * grid.cell_size
	var rect := Rect2(
		Vector2(0, lava_y),
		Vector2(grid.grid_width * grid.cell_size, (grid.grid_height * grid.cell_size) - lava_y)
	)
	draw_rect(rect, Color(1.0, 0.25, 0.05, 0.45))
