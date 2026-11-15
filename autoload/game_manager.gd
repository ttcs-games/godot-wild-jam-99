# Global Class (defined in Project Settings - Globals - Autoload)
# Means it is automatically loaded in any scene and can be accessed anywhere in code, like so: 'GameManager.select_card(myCard)'
# Current scope: holds reference to Hand and selected Card. Manages existance of Cursor with selected shape

extends Node

var hand: Control
var cursor_layer: CanvasLayer

const CURSOR := preload("res://ui/held_cursor.tscn")

var _active_card: Control = null
var _active_cursor: Node2D = null

# Needs to be called 
func select_card(card: Control) -> void:
	# Already have selected card - skip
	if _active_card != null:
		return
	# Memorize the selected card 
	_active_card = card
	card.lock()
	
	# Create a cursor with shape
	_active_cursor = CURSOR.instantiate()
	_active_cursor.setup(card.card_data)
	cursor_layer.add_child(_active_cursor)
	
func cancel_selection() -> void:
	# No selected card - skip
	if _active_card == null:
		return
	
	# Forget about selected card
	_active_card.unlock()
	_active_card = null
	
	# Delete a cursor with shape
	if _active_cursor != null:
		_active_cursor.queue_free()
		_active_cursor = null
