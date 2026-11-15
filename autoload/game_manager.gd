# Global Class (defined in Project Settings - Globals - Autoload)
# Means it is automatically loaded in any scene and can be accessed anywhere in code, like so: 'GameManager.select_card(myCard)'
# Current scope: holds reference to Hand and selected Card. Manages existance of Cursor with selected shape

extends Node

var hand: Control
var cursor_layer: CanvasLayer

const CURSOR := preload("res://ui/held_cursor.tscn")

var _active_card: Control = null
var _active_card_index: int = 11 #because the player will never have more than 10 cards
var _active_cursor: Node2D = null

# Needs to be called 
func select_card(card: Control, card_index: int) -> void:
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
