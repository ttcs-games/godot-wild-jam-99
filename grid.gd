# Game grid, where the shapes are to be placed

extends Node2D

# SETTINGS
@export var grid_width: int = 10
@export var grid_height: int = 20
@export var cell_size: int = 32
@export var grid_padding: int = 3

# CONSTANTS
const BLOCK := preload("res://game_objects/block.tscn")
@onready var block_root: Node2D = $BlockRoot # node where all the blocks will be stored

# SIGNALS
# todo: placement is yet to be processed
# When a block is placed (L shape = 4 calls)
signal block_placed(cell: Vector2i, element: Elements.Id) # todo: material?
# When a shape is placed (L shape = 1 call)
signal shape_placed(cells: Array[Vector2i], element: Elements.Id) # todo: material?
# When shape cannot be placed
signal placement_rejected(offsets: Array[Vector2i])

# VARIABLES
# Stores the occupied cells
var cells := {} # key: Vector2i, value: Elements.Id
# Keeps track of cell that is aimed at
var hovered_cell := Vector2i (-1, -1) 

# (1, 2) * 32px = (32px, 64px)
func cell_to_coords(c: Vector2i) -> Vector2:
	return c * cell_size

# (32px, 64px) / 32px = (1, 2)
func coords_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i((pos / cell_size).floor())
	
# (1, 2): 1 >= 0 and 1 < 10 ; 2 >= 0 and 2 < 20 -> inside the grid 
func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < grid_width and c.y < grid_height

# We process block placed signal by ourselves (to actually place it)
func _ready() -> void:
	block_placed.connect(_on_block_placed)

# Draw function is used only for aim draw (blocks are drawn by themselves - they are independent nodes)
func _draw() -> void:
	#drawing the bounds of the grid so it's easier to see
	var border := Rect2(0.0 - grid_padding,0.0 - grid_padding,grid_width*cell_size + 2*grid_padding, grid_height*cell_size + 2*grid_padding)
	draw_rect(border, Color.WHITE, false, 2.0)
	
	#drawing the shape if the cursor is hovering over it.
	if in_bounds(hovered_cell):
		#if there is an active block in the player's hand, it draws that instead.
		if GameManager._active_card != null:
			for block in GameManager._active_card.card_data.shape.offsets:
				var cell_aim := Rect2(cell_to_coords(hovered_cell + block), Vector2(cell_size, cell_size))
				draw_rect(cell_aim, Color.WHITE, false, 2.0)
		else:
			var cell_aim := Rect2(cell_to_coords(hovered_cell), Vector2(cell_size, cell_size))
			draw_rect(cell_aim, Color.WHITE, false, 2.0)

# Checker for an array of blocks (a shape) if it can be placed in required cell
func can_place(offsets: Array[Vector2i], origin: Vector2i, element: Elements.Id) -> bool:
	var has_foundation := false
	# Check every block in an array
	for offset in offsets:
		# Get coordinates of to-be-placed block
		var cell := origin + offset
		
		# Out of grid
		if not in_bounds(cell):
			return false
		
		# Occupied by block
		if cells.has(cell):
			return false
		
		# Is at the bottom
		if cell.y == grid_height-1:
			has_foundation = true
		
		# Is block standing on existing one (below it)
		if cells.has(cell+Vector2i(0,1)):
			has_foundation = true
		
		# Check every side
		for neighbor in _neighbors(cell):
			# Check side isn't taken by opposite element
			if cells.has(neighbor):
				if Elements.opposes(cells[neighbor], element):
					return false
	
	return has_foundation

# Helper: return all neighboring cells coordinates for a given cell 
func _neighbors(c: Vector2i) -> Array[Vector2i]:
	return [
		c + Vector2i(1,0),
		c + Vector2i(-1,0),
		c + Vector2i(0,1),
		c + Vector2i(0,-1)
	]

# Try placing an array of blocks (shape) to the grid. Returns false if failed
func place(offsets: Array[Vector2i], origin: Vector2i, element: Elements.Id) -> bool:
	if not can_place(offsets, origin, element):
		return false
	
	# For each block, register it in the grid
	var placed: Array[Vector2i] = []
	for offset in offsets:
		var cell := origin + offset
		cells[cell] = element
		placed.append(cell)
	
	# Signal for each new block that is has been placed on a certain cell
	for cell in placed:
		block_placed.emit(cell, element)
	
	shape_placed.emit(placed, element)
	return true
	
# Each tick get mouse position to get aimed cell 
# todo: find a better solution so we dont redraw the grid every turn because of that
func _process(delta: float) -> void:
	var local_pos := to_local(get_global_mouse_position())
	hovered_cell = coords_to_cell(local_pos)
	queue_redraw()
	
# Processor for "block placed" signal: actually spawns the block node
func _on_block_placed(cell: Vector2i, element: Elements.Id) -> void:
	var b := BLOCK.instantiate()
	b.position = cell_to_coords(cell)
	b.element = element
	# todo: setup the material
	block_root.add_child(b)

# todo: debug function, to be removed
func _unhandled_input(event: InputEvent) -> void:
	# Spacebar is pressed - generate a static array of blocks and emulate place function
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		var test_offsets: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)]
		var ok := place(test_offsets, hovered_cell, Elements.Id.BLUE)
		if not ok:
			placement_rejected.emit(test_offsets)
			
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var test_offsets: Array[Vector2i] = GameManager._active_card.card_data.shape.offsets
		var ok := place(test_offsets, hovered_cell, GameManager._active_card.card_data.element)
		if not ok:
			placement_rejected.emit(test_offsets)
		else:
			return #todo: make the card disappear from the hand.
	
