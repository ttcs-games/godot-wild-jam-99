class_name GrassHandler extends BaseHandler

func play_grass(card_deck :CardPile, block : Node2D, card : CardData):
	var path = load("res://data/materials/grass_material.tres")
	card_deck._cards.pick_random().material = path
	card_deck.draw(1)
