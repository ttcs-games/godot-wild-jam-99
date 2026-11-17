# Game grid, where the shapes are to be placed

extends Node2D

# SETTINGS
@export var grid_width: int = 10
@export var grid_height: int = 20
@export var cell_size: int = 32
@export var grid_padding: int = 3
@export var objective_row: int = 6
@export var lava_rise_seconds: float = 0.5
@export var flash_seconds: float = 0.75
@export var flash_hold_seconds: float = 0.25
@export var delay_per_destruction: float = 0.25

# CONSTANTS
const BLOCK := preload("res://game_objects/block.tscn")
@onready var block_root: Node2D = $BlockRoot # node where all the blocks will be stored
@onready var cursor: AnimatedSprite2D = %Cursor #add cursor in the inspector
@onready var lava_overlay: Node2D = $Lava

# SIGNALS
# todo: placement is yet to be processed
# When a block is placed (L shape = 4 calls)
signal block_placed(cell: Vector2i, element: Elements.Id) # todo: material?
# When a shape is placed (L shape = 1 call)
signal shape_placed(cells: Array[Vector2i], element: Elements.Id) # todo: material?
# When shape cannot be placed
signal placement_rejected(offsets: Array[Vector2i])
signal level_cleared(delta: int)
signal game_over

# VARIABLES
# Stores the occupied cells
var cell_to_block: = {} # key: Vector2i, value: Block
# Keeps track of cell that is aimed at
var hovered_cell := Vector2i (-1, -1) 
var _last_hovered: Vector2i = Vector2i(-999, -999)

var lava_row: int = grid_height
var _lava_visual_row: float = grid_height
var _last_lava_row_visual: float = -1.0
var is_animating: bool = false

var _level_cleared_fired: bool = false

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
	if objective_row >= 0 and objective_row < grid_height:
		var y := objective_row * cell_size
		var x0 := 0.0
		var x1 := grid_width * cell_size
		draw_line(Vector2(x0, y), Vector2(x1, y), Color(1, 1, 1, 0.15), 6.0)
		draw_line(Vector2(x0, y), Vector2(x1, y), Color(1, 1, 1, 0.8), 1.5)
	
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
		
		# Covered OR touches lava
		if cell.y >= lava_row:
			return false
		
		# Occupied by block
		if cell_to_block.has(cell):
			return false
		
		# Is at the bottom
		if cell.y == grid_height-1:
			has_foundation = true
		
		# Is block standing on existing one (below it)
		if cell_to_block.has(cell+Vector2i(0,1)):
			has_foundation = true
		
		# Check every side
		for neighbor in _neighbors(cell):
			# Check side isn't taken by opposite element
			if cell_to_block.has(neighbor):
				if Elements.opposes(cell_to_block[neighbor].element, element):
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
	if is_animating:
		return false
	
	if not can_place(offsets, origin, element):
		return false
	
	# For each block, register it in the grid
	var placed: Array[Vector2i] = []
	for offset in offsets:
		var cell := origin + offset
		placed.append(cell)
	
	# Send the win singal once ever, if any placed cell turned the line into finished line above the objective
	if not _level_cleared_fired and objective_row >= 0 and objective_row < grid_height:
		var checked_rows := {}
		for cell in placed:
			if cell.y > objective_row:
				continue
			if checked_rows.has(cell.y):
				continue
			checked_rows[cell.y] = true
			if _is_row_full(cell.y):
				_level_cleared_fired = true
				level_cleared.emit(lava_row - objective_row)
				break
	
	# Signal for each new block that is has been placed on a certain cell
	for cell in placed:
		block_placed.emit(cell, element)
	
	shape_placed.emit(placed, element)
	queue_redraw()
	return true

func reset_level() -> void:
	for block in cell_to_block.values():
		block.queue_free()
	cell_to_block.clear()
	_level_cleared_fired = false
	lava_row = grid_height
	_lava_visual_row = float(grid_height)
	lava_overlay.queue_redraw()
	queue_redraw()

func rise_lava(n: int) -> void:
	if is_animating:
		return
	if lava_row <= 0:
		return
	
	var target := maxi(objective_row, lava_row - n)
	lava_row = target
	is_animating = true
	var tw := create_tween()
	tw.tween_property(self, "_lava_visual_row", float(target), lava_rise_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.finished.connect(_on_lava_rise_finished, CONNECT_ONE_SHOT)

# Each tick get mouse position to get aimed cell
func _process(delta: float) -> void:
	var local_pos := to_local(get_global_mouse_position())
	var c := coords_to_cell(local_pos)
	if c != _last_hovered:
		_last_hovered = c
		hovered_cell = c
		queue_redraw()
	if _lava_visual_row != _last_lava_row_visual:
		_last_lava_row_visual = _lava_visual_row
		lava_overlay.queue_redraw()
	
# Processor for "block placed" signal: actually spawns the block node
func _on_block_placed(cell: Vector2i, element: Elements.Id) -> void:
	var b := BLOCK.instantiate()
	b.position = cell_to_coords(cell)
	b.element = element
	# todo: setup the material
	block_root.add_child(b)
	cell_to_block[cell] = b

# todo: debug function, to be removed
func _unhandled_input(event: InputEvent) -> void:
	# TODO: debug spacebar/0 to end/start a turn
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		GameManager.end_turn()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_0:
		GameManager.start_turn()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_1:
		rise_lava(2)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and GameManager._active_card != null:
		var test_offsets: Array[Vector2i] = GameManager._active_card.card_data.shape.offsets
		var ok := place(test_offsets, hovered_cell, GameManager._active_card.card_data.element)
		
		if not ok:
			placement_rejected.emit(test_offsets)
		else: 
			cursor.play("throw")

func _run_cascade() -> void:
	while true:
		var unfinished := _unfinished_rows_in_lava()
		if unfinished.is_empty():
			break
		
		await _flash_rows(unfinished)
		_break_rows(unfinished)
		await _shift_above_lowest(unfinished.max(), unfinished)
		await get_tree().create_timer(delay_per_destruction).timeout
	
	for y in range(0, lava_row):
		for x in grid_width:
			if cell_to_block.has(Vector2i(x, y)):
				return
	game_over.emit()

func _on_animation_finished():
	if cursor.animation == "release":
		cursor.sprite.play("idle")

func _is_row_unfinished(y: int) -> bool:
	var filled := 0
	for x in grid_width:
		if cell_to_block.has(Vector2i(x, y)):
			filled += 1
	return filled > 0 and filled < grid_width

func _unfinished_rows_in_lava() -> Array[int]:
	var result: Array[int] = []
	for y in range(lava_row, grid_height):
		if _is_row_unfinished(y):
			result.append(y)
	return result

func _on_lava_rise_finished() -> void:
	_run_cascade()
	is_animating = false

func _flash_rows(rows: Array[int]) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	var found_any := false
	for y in rows:
		for x in grid_width:
			var cell := Vector2i(x, y)
			if not cell_to_block.has(cell):
				continue
			var block: Node2D = cell_to_block[cell]
			tween.tween_property(block, "modulate", Color(1.0, 0.2, 0.2), flash_seconds)
			found_any = true
	
	if not found_any:
		return
	
	await tween.finished
	await get_tree().create_timer(flash_hold_seconds).timeout

func _break_rows(rows: Array[int]) -> void:
	for y in rows:
		for x in grid_width:
			var cell := Vector2i(x, y)
			if not cell_to_block.has(cell):
				continue
			var block: Node2D = cell_to_block[cell]
			block.hide()
			block.queue_free()
			cell_to_block.erase(cell)

func _shift_above_lowest(lowest_broken: int, broken_rows: Array[int]) -> void:
	var broken_set := {}
	for r in broken_rows:
		broken_set[r] = true
	var new_cells := {}
	var new_map := {}
	for y in grid_height:
		# The broken line needs no shifting
		if broken_set.has(y):
			continue
		var shift := 0
		# Check only lines above the first break
		if y < lowest_broken:
			# For each broken line BELOW, need to shift THIS line down by 1
			for b in broken_rows:
				if b > y:
					shift += 1
		var new_y := y + shift
		# Copy the non-empty cells into the new location
		# For lines unaffected with shifting (0) it will be the same location
		for x in grid_width:
			var old_cell := Vector2i(x, y)
			if not cell_to_block.has(old_cell):
				continue
			var new_cell := Vector2i(x, new_y)
			new_map[new_cell] = cell_to_block[old_cell]
	
	# Update the grid state
	cell_to_block = new_map
	
	# Animate the fall line by line
	var tween := create_tween()
	tween.set_parallel(true)
	var any_changed := false
	for y in grid_height:
		# Dont animate broken lines or lines below the break
		if broken_set.has(y) or y >= lowest_broken:
			continue
		# Find how many lines were broken below
		var shift := 0
		for b in broken_rows:
			if b > y:
				shift += 1
		if shift == 0:
			continue
		# Animate the position change of the existing blocks
		for x in grid_width:
			var new_cell := Vector2i(x, y + shift)
			if not new_map.has(new_cell):
				continue
			var block: Node2D = new_map[new_cell]
			tween.tween_property(block, "position",cell_to_coords(new_cell), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			any_changed = true
	if any_changed:
		await tween.finished

func _is_row_full(y: int) -> bool:
	for x in grid_width:
		if not cell_to_block.has(Vector2i(x, y)):
			return false
	return true
