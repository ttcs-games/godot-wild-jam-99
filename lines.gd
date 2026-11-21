extends Node2D

@onready var grid := get_parent()

func _draw() -> void:
	if grid == null:
		return
	
	var x0 := float(0.0 - grid.grid_padding)
	var x1 = float(grid.grid_width * grid.cell_size + grid.grid_padding)
		
	if grid.objective_row >= 0 and grid.objective_row < grid.grid_height:
		var y = grid.objective_row * grid.cell_size
		draw_line(Vector2(x0, y), Vector2(x1, y), Color(1, 1, 1, 0.15), 18.0)
		draw_line(Vector2(x0, y), Vector2(x1, y), Color(1, 1, 1, 0.8), 4.5)
	
	if GameManager.current_level_data != null and "lava_per_turn" in GameManager.current_level_data:
		var rise_n: int = GameManager.current_level_data.lava_per_turn
		var next_lava_row := maxi(grid.objective_row, grid.lava_row - rise_n)
		if next_lava_row < grid.grid_height:
			var next_y := float(next_lava_row) * float(grid.cell_size)
			draw_line(Vector2(x0, next_y), Vector2(x1, next_y), Color(1.0, 0.5, 0.0, 0.22), 18.0)
			draw_line(Vector2(x0, next_y), Vector2(x1, next_y), Color(1.0, 0.5, 0.0, 0.75), 4.5)
	
	#drawing the bounds of the grid so it's easier to see
	var border := Rect2(0.0 - grid.grid_padding,0.0 - grid.grid_padding, grid.grid_width*grid.cell_size + 2*grid.grid_padding, grid.grid_height*grid.cell_size + 2*grid.grid_padding)
	draw_rect(border, Color.WHITE, false, 2.0)
	
	#drawing the shape if the cursor is hovering over it.
	if grid.in_bounds(grid.hovered_cell):
		#if there is an active block in the player's hand, it draws that instead.
		if GameManager._active_card != null:
			var highlight_color = Color.WHITE if grid.can_place(GameManager._active_card.card_data.shape.offsets, grid.hovered_cell, GameManager._active_card.card_data.element, GameManager._active_card.card_data.material) else Color.RED
			
			var shape_offsets : Array[Vector2i] 
			shape_offsets.assign(GameManager._active_card.card_data.shape.offsets.map(func(offset): return offset - Vector2i(1,1)) if GameManager._active_card.card_data.shape.display_name != "I-shape" else GameManager._active_card.card_data.shape.offsets)
			
			for block in shape_offsets:
				var cell_aim := Rect2(grid.cell_to_coords(grid.hovered_cell + block), Vector2(grid.cell_size, grid.cell_size))
				draw_rect(cell_aim, highlight_color, false, 2.0)
		else:
			var cell_aim := Rect2(grid.cell_to_coords(grid.hovered_cell), Vector2(grid.cell_size, grid.cell_size))
			draw_rect(cell_aim, Color.WHITE, false, 2.0)
