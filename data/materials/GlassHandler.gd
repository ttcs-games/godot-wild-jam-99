class_name GlassHandler extends BaseHandler

func play():
	GameManager.open_pile_viewer(GameManager.discard,"Discard Pile",GameManager.discard.size(),false,on_click_handle)

func on_click_handle(card_affected: Control):
	await GameManager.hand.draw_one(GameManager.discard.drawSpecificCard(GameManager.discard._cards.find(card_affected)),Vector2(800, -150) )
