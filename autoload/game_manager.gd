# Global Class (defined in Project Settings - Globals - Autoload)
# Means it is automatically loaded in any scene and can be accessed anywhere in code, like so: 'GameManager.select_card(myCard)'
# Current scope: holds reference to Hand and selected Card. Manages existance of Cursor with selected shape

extends Node

var REWARD_AMOUNT := 3 #Default is 3 rewards for completing a level
var redraws := 0

var hand: Control
var grid: Node2D
var cursor_layer: CanvasLayer

var deck: CardPile
var discard: CardPile
var exhume: CardPile

const CURSOR := preload("res://ui/held_cursor.tscn")
const DECK_VIEWER_SCENE := preload("res://ui/deck_viewer.tscn")
const SCENE_LEVEL_DESCRIPTION := "res://level_description.tscn"
const SCENE_GAME_ZONE := "res://Game_zone.tscn"
const SCENE_REWARDS := "res://Rewards_screen.tscn"
const SCENE_GAME_OVER := "res://game_over.tscn"

var cursorAnimation : AnimatedSprite2D
var _active_card: Control = null
var _active_card_index: int = 1000 #because the player will never have more than 10 cards
var _active_cursor: Node2D = null
var _open_viewer: Control = null
var cursor: AnimatedSprite2D = null

signal shape_rotated

#Reward Handling. The signal is emitted only when the reward is successfully applied, not when the viewer is closed
var reward_to_apply: Reward = null
var _reward_chosen: bool = false #checks if the player has selected a reward
var cards_affected : Array[Control] = []
signal reward_applied

# Turn Handling
var turn_number: int = 1
var lava_per_turn: int = 1
var lava_delay: int = 0
var draw_per_turn := 10
var is_end_turn_in_progress: bool = false
signal turn_changed(new_turn: int)
var is_game_over: bool = false
var is_level_won: bool = false

var current_level_data: LevelData = null

func start_run() -> void:
	current_level_data = null
	init_deck()
	MusicManager.switch_track()
	get_tree().change_scene_to_file(SCENE_LEVEL_DESCRIPTION)

func finish_rewards() -> void:
	get_tree().change_scene_to_file(SCENE_LEVEL_DESCRIPTION)

func end_run() -> void:
	is_game_over = true
	MusicManager.switch_track()
	get_tree().change_scene_to_file(SCENE_GAME_OVER)

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
	var cards := deck.draw(draw_per_turn)
	if cards.size() < draw_per_turn:
		deck.add_all(discard.draw_all())
		deck.shuffle()
		cards.append_array(deck.draw(draw_per_turn - cards.size()))
	hand.setup(cards)

func start_level() -> void:
	#Player gains one redraw per level. Maximum they can hold is 9.
	redraws = min(redraws + 1, 9)
	
	turn_number = 1
	is_end_turn_in_progress = false
	is_game_over = false
	is_level_won = false
	if current_level_data != null:
		lava_per_turn = current_level_data.lava_per_turn
		draw_per_turn = current_level_data.draw_per_turn
		lava_delay = current_level_data.lava_delay
	else:
		lava_per_turn = 1
		draw_per_turn = 10
		lava_delay = 0
	
	deck.shuffle()
	get_tree().change_scene_to_file(SCENE_GAME_ZONE)
	
# Puts all the cards from hand to discard pile
func end_turn(turn_label: Label) -> void:
	if grid.is_animating or hand._is_animating:
		return
	if is_end_turn_in_progress or is_level_won:
		return
	if grid.is_animating:
		return
	
	is_end_turn_in_progress = true
	if cursor.animation == "grab":
		cursor.play("idle")
	remove_card()
	await _phase_discard_hand()
	await _phase_rise_lava()
	if is_game_over:
		return
	await _phase_bump_turn(turn_label)
	await _phase_draw_hand(draw_per_turn)
	is_end_turn_in_progress = false

func finish_level() -> void:
	deck.add_all(discard.draw_all())
	deck.add_all(exhume.draw_all())
	deck.add_all(hand.get_cards_data())
	deck.shuffle()
	get_tree().change_scene_to_file(SCENE_REWARDS)

func discard_card(card: CardData) -> void:
	discard.add(card)

# Needs to be called 
func select_card(card: Control, card_index: int) -> void:
	if is_end_turn_in_progress or is_level_won:
		return
	if _active_card != card:
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
		#returning it to its original shape if it was rotated
		CardFactory.return_original_shape(_active_card.card_data)
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
		shape_rotated.emit()
		return

func cursor_Hover() -> void:
	if cursorAnimation.animation != "grab":
		cursorAnimation.play("hover")
	
func cursor_Hover_exit() -> void:
	if cursorAnimation.animation != "grab":
		cursorAnimation.play("hover_exit")

func open_pile_viewer(pile: CardPile, title: String , num_cards_displayed: int = 1000 ,sort_cards : bool = true, on_card_chosen:Callable = _on_card_chosen ) -> void:
	remove_card()
	cursorAnimation.play("idle")
	if _open_viewer != null:
		return
	_open_viewer = DECK_VIEWER_SCENE.instantiate()
	cursor_layer.add_child(_open_viewer)
	_open_viewer.setup(pile, title, num_cards_displayed, sort_cards,_on_card_chosen)
	_open_viewer.close_requested.connect(_close_pile_viewer)
	
	#configuring accept rewards button to apply rewards
	if (_reward_chosen):
		_open_viewer.get_child(1).pressed.connect(apply_rewards)

func _close_pile_viewer() -> void:
	#this is for the rewards screen.
	if (cards_affected != []):
		cards_affected = []
	
	if _open_viewer == null:
		return
	_open_viewer.queue_free()
	_open_viewer = null

#applies the reward to the card. Horrible way of doing this, but it's a game jam, so have to make compromises
func _on_card_chosen(card_affected: Control) -> void:
	#if no reward is chosen, do this. Adding cards is already handled in rewards_screen script
	if (_reward_chosen == false || reward_to_apply == null):
		return
	
	if (card_affected in cards_affected):
		cards_affected.erase(card_affected)
		card_affected.unlock()
		
	elif (reward_to_apply.amount > len(cards_affected)):
		cards_affected.append(card_affected)
		card_affected.lock()
	
	#this is the accept rewards button
	_open_viewer.get_child(1).visible = true
	_open_viewer.get_child(1).disabled = false
	
func apply_rewards() -> void:
	var cards_affected_data : Array[CardData]
	cards_affected_data.assign(cards_affected.map(func(card): return card.card_data))
	
	#removing these cards from the deck
	deck.remove_all(cards_affected_data)
	
	#add them back in changed if its one of the other rewards
	for single_card in cards_affected_data:
		if (reward_to_apply.Type == Reward.Types.TRAIT):
			single_card.material = reward_to_apply.Trait_added
			
			
		elif (reward_to_apply.Type == Reward.Types.CHANGE_ELEMENT):
			single_card.element = reward_to_apply.Element_change
			
		elif (reward_to_apply.Type == Reward.Types.CHANGE_SHAPE):
			single_card.shape = reward_to_apply.Shape_change
	
	if (reward_to_apply.Type != Reward.Types.REMOVE):
		deck.add_all(cards_affected_data)
	
	_open_viewer.get_child(1).visible = false
	_open_viewer.get_child(1).disabled = true
	_open_viewer.close_requested.emit()
	reward_applied.emit()
	cards_affected = []
	
func _phase_discard_hand() -> void:
	await get_tree().create_timer(0.15).timeout
	var hand_data: Array[CardData] = hand.get_cards_data()
	discard.add_all(hand_data)
	await hand.discard_batch(hand.cards.duplicate())
	await get_tree().create_timer(0.15).timeout

func _phase_rise_lava() -> void:
	await grid.rise_lava(lava_per_turn)

func _phase_bump_turn(turn_label: Label) -> void:
	turn_number += 1
	turn_changed.emit(turn_number)
	if turn_label != null:
		turn_label.text = "Turn %d" % turn_number
		var tw := create_tween()
		tw.tween_property(turn_label, "scale", Vector2(1.15, 1.15), 0.1)
		tw.tween_property(turn_label, "scale", Vector2.ONE, 0.1)
	await get_tree().create_timer(0.6).timeout

func _phase_draw_hand(cards_drawn: int) -> void:
	var cards := deck.draw(cards_drawn)
	await hand.draw_batch(cards)
	if cards.size() < cards_drawn:
		await get_tree().create_timer(0.15).timeout
		deck.add_all(discard.draw_all())
		deck.shuffle() # TODO: animation of flow: discard -> deck ?
		await get_tree().create_timer(0.15).timeout
		var extra_cards := deck.draw(draw_per_turn - cards.size())
		await hand.draw_batch(extra_cards)
	await get_tree().create_timer(0.2).timeout
