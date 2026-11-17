# Global Class (defined in Project Settings - Globals - Autoload)
# Means it is automatically loaded in any scene and can be accessed anywhere in code, like so: 'GameManager.select_card(myCard)'
# Current scope: holds reference to Hand and selected Card. Manages existance of Cursor with selected shape

extends Node

const DRAW_AMOUNT := 10

var REWARD_AMOUNT := 3 #Default is 3 rewards for completing a level

var hand: Control
var cursor_layer: CanvasLayer

var deck: CardPile
var discard: CardPile
var exhume: CardPile

const CURSOR := preload("res://ui/held_cursor.tscn")
const DECK_VIEWER_SCENE := preload("res://ui/deck_viewer.tscn")

var cursorAnimation : AnimatedSprite2D
var _active_card: Control = null
var _active_card_index: int = 1000 #because the player will never have more than 10 cards
var _active_cursor: Node2D = null
var _open_viewer: Control = null

#Reward Handling
var reward_to_apply: Reward = null
var _reward_chosen: bool = false #checks if the player has selected a reward
var cards_affected : Array[CardData] = []

# Creates the piles and a initial deck
func init_deck() -> void:
	deck = CardPile.new()
	discard = CardPile.new()
	exhume = CardPile.new()
	deck.add_all(CardFactory.standard_deck())
	deck.shuffle()

# Draws cards from deck into hand
# Reshuffles discard pile into deck if there is not enough to draw
func start_turn() -> void:
	var cards := deck.draw(DRAW_AMOUNT)
	if cards.size() < DRAW_AMOUNT:
		deck.add_all(discard.draw_all())
		deck.shuffle()
		cards.append_array(deck.draw(DRAW_AMOUNT - cards.size()))
	hand.setup(cards)

# Puts all the cards from hand to discard pile
func end_turn() -> void:
	discard.add_all(hand.get_cards_data())
	hand.clear()

func discard_card(card: CardData) -> void:
	discard.add(card)

# Needs to be called 
func select_card(card: Control, card_index: int) -> void:
	cursorAnimation.play("grab")
	# If you already have a selected card - cancel previous selection
	if _active_card != null:
		_active_card.unlock()
		_active_card = null
		_active_cursor.queue_free()
		_active_cursor = null
		
	# Memorize the (new) selected card 
	_active_card = card
	_active_card_index = card_index
	card.lock()
	
	# Create a cursor with shape
	_active_cursor = CURSOR.instantiate()
	_active_cursor.setup(card.card_data)
	cursor_layer.add_child(_active_cursor)

func remove_card() -> void:
	if _active_card != null:
		_active_card.unlock()
		_active_card = null
	if _active_cursor != null:
		_active_cursor.queue_free()
		_active_cursor = null
	

func rotate_selection() -> void:
	#squares dont change while rotating
	if _active_card.card_data.shape.display_name == "Square":
			return
	else:
		#defining the new offsets for the shape once its rotated
		var new_offsets: Array[Vector2i] = []
		var re_centre_offset := Vector2i(3,3)
		#Think of it as rotating every offset around (1,1) or in a 3x3 grid. This is why (1,1) doesn't change itself
		for shape in _active_card.card_data.shape.offsets:
			if (shape == Vector2i(0,0)):
				shape = Vector2i(2,0)
			elif (shape == Vector2i(0,1)):
				shape = Vector2i(1,0)
			elif (shape == Vector2i(0,2)):
				shape = Vector2i(0,0)
			elif (shape == Vector2i(1,0)):
				shape = Vector2i(2,1)
			#no (1,1) cuz it always stays in the same spot
			elif (shape == Vector2i(1,2)):
				shape = Vector2i(0,1)
			elif (shape == Vector2i(2,0)):
				shape = Vector2i(2,2)
			elif (shape == Vector2i(2,1)):
				shape = Vector2i(1,2)
			elif (shape == Vector2i(2,2)):
				shape = Vector2i(0,2)
				
			#These lines are specifically for the stupid line block.
			#because it is the only one that goes beyond the 0-2 offset amount.
			elif (shape == Vector2i(0,3)):
				shape = Vector2i(3,0)
			elif (shape == Vector2i(3,0)):
				shape = Vector2i(2,3)
			elif (shape == Vector2i(2,3)):
				shape = Vector2i(3,2)
			elif (shape == Vector2i(3,2)):
				shape = Vector2i(0,3)
			
			#This code below finds the distance between the rotated object and the origin (top left)
			re_centre_offset = Vector2i(min(re_centre_offset[0],shape[0]), min(re_centre_offset[1],shape[1]))
			new_offsets.append(shape)
			
		#the distance is subtracted from the rotated shape's new offsets
		new_offsets.assign(new_offsets.map(func (offset): return Vector2i(offset - re_centre_offset)))
		
		#the adjusted offsets are assigned to the card again, making sure rotation doesn't move the shape away from cursor
		var rotated_card := _active_card
		rotated_card.card_data.shape.offsets = new_offsets
		#sending the same card and index, but with a rotated shape
		select_card(rotated_card, _active_card_index)
		return

func cursor_Hover() -> void:
	if cursorAnimation.animation != "grab":
		cursorAnimation.play("hover")
	
func cursor_Hover_exit() -> void:
	if cursorAnimation.animation != "grab":
		cursorAnimation.play("hover_exit")

func open_pile_viewer(pile: CardPile, title: String, num_cards_displayed: int = 1000, sort_cards : bool = true) -> void:
	remove_card()
	if _open_viewer != null:
		return
	_open_viewer = DECK_VIEWER_SCENE.instantiate()
	cursor_layer.add_child(_open_viewer)
	_open_viewer.setup(pile, title, num_cards_displayed, sort_cards)
	_open_viewer.close_requested.connect(_close_pile_viewer)
	
	#configuring accept rewards button to apply rewards
	if (_reward_chosen):
		_open_viewer.get_child(1).pressed.connect(apply_rewards)

func _close_pile_viewer() -> void:
	if _open_viewer == null:
		return
	_open_viewer.queue_free()
	_open_viewer = null

#applies the reward to the card. Horrible way of doing this, but it's a game jam, so have to make compromises
func _on_card_chosen(card_affected: Control) -> void:
	#if no reward is chosen, do this. Adding cards is already handled in rewards_screen script
	if (_reward_chosen == false or reward_to_apply == null):
		return
	
	if (card_affected.card_data in cards_affected):
		cards_affected.erase(card_affected.card_data)
		card_affected.unlock()
		
	elif (reward_to_apply.amount > len(cards_affected)):
		cards_affected.append(card_affected.card_data)
		card_affected.lock()
	
	#this is the accept rewards button
	_open_viewer.get_child(1).visible = true
	_open_viewer.get_child(1).disabled = false
	
func apply_rewards() -> void:
	#removing these cards from the deck
	deck.remove_all(cards_affected)
	
	#add them back in changed if its one of the other rewards
	for single_card in cards_affected:
		if (reward_to_apply.Type == Reward.Types.TRAIT):
			single_card.material = reward_to_apply.Trait_added
			
		elif (reward_to_apply.Type == Reward.Types.CHANGE_ELEMENT):
			single_card.element = reward_to_apply.Element_change
			
		elif (reward_to_apply.Type == Reward.Types.CHANGE_SHAPE):
			single_card.shape = reward_to_apply.Shape_change
	
	if (reward_to_apply.Type != Reward.Types.REMOVE):
		deck.add_all(cards_affected)
	
	_open_viewer.get_child(1).visible = false
	_open_viewer.get_child(1).disabled = true
	_open_viewer.close_requested.emit()
	cards_affected = []
	
