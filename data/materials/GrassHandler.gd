class_name GrassHandler extends BaseHandler

func play():
	var path = load("res://data/materials/grass_material.tres")
	GameManager.hand.cards.pick_random().card_data.material = path
	await GameManager.hand.draw_one(GameManager.deck.draw(1).get(0))
	GameManager.hand._layout()
