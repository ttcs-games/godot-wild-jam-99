# base_handler.gd
class_name BaseHandler
extends Resource

func play() -> void:
	await _on_grid_shape_placed()
	pass

func _on_grid_shape_placed() -> void:
	var card: Control = GameManager._active_card
	
	if card == null or not GameManager.hand.cards.has(card):
		return
	GameManager.discard_card(card.card_data)
	GameManager.remove_card()
	print(card)
	GameManager.hand.cards.erase(card)
	await GameManager.hand.discard_one(card)

# Rules: override these in children
func needs_foundation() -> bool:
	return true

func can_place_anywhere() -> bool:   # skips the lava-row restriction
	return false

func ignores_opposition() -> bool:
	return false
 
func sticky_neighbour() -> bool:
	return false
