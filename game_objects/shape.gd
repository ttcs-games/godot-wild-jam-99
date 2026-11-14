# A shape that will be shown Card or Cursor
# Important: Grid does not use Shape, instead, it generates the Blocks by itself
#            (otherwise Grid would need to store all the shape info for each cell)
extends Node2D

const BLOCK := preload("res://game_objects/block.tscn")
@export var offsets: Array[Vector2i] # All coordinates of the blocks, needed to make a shape 
@export var element: Elements.Id = Elements.Id.GREEN
@export var cell_size: int = 32

func _ready() -> void:
	# Create a visual by spawning blocks from an array
	for offset in offsets:
		var b := BLOCK.instantiate()
		# Assign position by multiplied its normalized coordinates (starts at 0, 0) times the size of a cell 
		b.position = offset * cell_size
		b.element = element
		add_child(b)
