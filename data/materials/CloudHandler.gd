class_name CloudHandler extends BaseHandler
func play():
	await  _on_grid_shape_placed()
	if GameManager.hand.cards.size() >=4:
		await GameManager.hand.discard_one(GameManager.hand.cards.pick_random())
		await GameManager.hand.discard_one(GameManager.hand.cards.pick_random())
		await GameManager.hand.discard_one(GameManager.hand.cards.pick_random())
		await GameManager.hand.discard_one(GameManager.hand.cards.pick_random())
	else:
		await GameManager.hand.discard_batch(GameManager.hand.cards)

func needs_foundation() -> bool:
	return false

func can_place_anywhere() -> bool:   # skips the lava-row restriction
	return true
