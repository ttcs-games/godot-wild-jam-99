# Cursor for  showing the selected shape from card
extends Node2D

# CONSTANTS
const SHAPE := preload("res://game_objects/shape.tscn")

# VARIABLES
var card_data: CardData # card data from which shape is chosen
var _shape: Node2D # chosen shape

# Init the cursor with a shape from card
func setup(data: CardData) -> void:
	card_data = data
	_shape = SHAPE.instantiate()
	_shape.offsets = data.shape.offsets
	_shape.element = data.element
	add_child(_shape)
	_center_shape_on_mouse()

# Each tick move the position to follow the mouse (so drawn shape follows it)
func _process(_delta: float) -> void:
	global_position = get_global_mouse_position()

func _unhandled_input(event: InputEvent) -> void:
	if GameManager.is_end_turn_in_progress or GameManager.is_level_won:
		return
	
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		GameManager.rotate_selection()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		GameManager.remove_card()
		get_viewport().set_input_as_handled()
		

# Set shape's center to be located at the mouse's location
func _center_shape_on_mouse() -> void:
	# skip if we dont know a shape
	if _shape == null or card_data == null:
		return
	# get the smallest rectangle that can contain the shape (all the blocks)
	var bbox := Utils.bounding_box(card_data.shape.offsets)
	# set shape to be located where its center is (easily calculated via rectangle we just got)
	_shape.position = -Vector2(bbox.size) * _shape.cell_size * 0.5
