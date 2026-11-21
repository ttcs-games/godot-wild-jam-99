class_name BrickHandler extends BaseHandler

func play():
	var flag : bool = false
	var active_card = GameManager._active_card
	var self_cells : Array [Vector2i] 
	for offset in active_card.card_data.shape.offsets:
		var cell :Vector2i = offset + GameManager.grid.hovered_cell - Vector2i(1,1) if active_card.card_data.shape.display_name != "I-shape" else GameManager.grid.hovered_cell + offset
		self_cells.append(cell)

	for cell in self_cells:
		
		for neighbor in GameManager.grid._neighbors(cell):
				# Check side isn't taken by opposite element
				
				if GameManager.grid.cell_to_block.has(neighbor)&& !(neighbor in self_cells):
					if Elements.isSame(GameManager.grid.cell_to_block[neighbor].element ,GameManager.grid.cell_to_block[cell].element):
						flag = true
						break
						
	
	await _on_grid_shape_placed()
	if(flag):
		await GameManager.hand.draw_one(GameManager.deck.draw(1).get(0))
