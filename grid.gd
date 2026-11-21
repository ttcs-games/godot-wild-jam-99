# Game grid, where the shapes are to be placed

extends Node2D

# SETTINGS
@export var grid_width: int = 10
@export var grid_height: int = 20
@export var cell_size: int = 40
@export var grid_padding: int = 3
@export var objective_row: int = 6
@export var lava_rise_seconds: float = 0.75
@export var flash_seconds: float = 0.25
@export var flash_hold_seconds: float = 0.25
@export var delay_per_destruction: float = 0.01

# CONSTANTS
const BLOCK := preload("res://game_objects/block.tscn")
@onready var block_root: Node2D = $BlockRoot # node where all the blocks will be stored
@onready var cursor: AnimatedSprite2D = %Cursor #add cursor in the inspector
@onready var lava_overlay: AnimatedSprite2D = $Lava
@onready var lava2_overlay: AnimatedSprite2D = $Lava/Lava2
@onready var lava3_overlay: AnimatedSprite2D = $Lava/Lava3
@onready var lines: Node2D = $Lines

# MODIFIER VARIABLES
var level_modifiers : Array[Modifier] = []
var _rng = RandomNumberGenerator.new() #used for randomly spreading modifiers among tiles
@onready var tile_root: Node2D = $TileRoot # node where all the blocks will be stored


# SIGNALS
# todo: placement is yet to be processed
# When a block is placed (L shape = 4 calls)
signal block_placed(cell: Vector2i, element: Elements.Id) # todo: material?
# When a shape is placed (L shape = 1 call)
signal shape_placed(cells: Array[Vector2i], element: Elements.Id) # todo: material?
# When shape cannot be placed
signal placement_rejected(offsets: Array[Vector2i])
signal level_cleared(delta: int)
signal game_over()

# VARIABLES
# Stores the occupied cells for blocks and tile modifiers both
var cell_to_block: = {} # key: Vector2i, value: Block
var tiles_to_block: = {} # key: Vector2i, value: Modifier
var tiles_to_block_nodes: = {} #key: Vector2i, value: Sprite2d node. holds the nodes created by tiles.
# Keeps track of cell that is aimed at
var hovered_cell := Vector2i (-1, -1) 
var _last_hovered: Vector2i = Vector2i(-999, -999)

var lava_row: int = grid_height
var is_animating: bool = false

var _level_cleared_fired: bool = false

var _bubble_scale_tex: CurveTexture
var _bubble_fade_tex: GradientTexture1D

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
	shape_placed.connect(_on_shape_placed)
	GameManager.shape_rotated.connect(lines.queue_redraw)
	_fit_lava()
	await get_tree().process_frame
	_update_grid_position()
	get_viewport().size_changed.connect(_update_grid_position)

# Checker for an array of blocks (a shape) if it can be placed in required cell
func can_place(offsets: Array[Vector2i], origin: Vector2i, element: Elements.Id) -> bool:
	var has_foundation := false
	# Check every block in an array
	for offset in offsets:
		# Get coordinates of to-be-placed block
		var cell := origin + offset - Vector2i(1,1) if GameManager._active_card.card_data.shape.display_name != "I-shape" else origin + offset
		
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
		
		#check if the tile modifier will allow it
		if (cell in tiles_to_block.keys()):
			if (tiles_to_block[cell].Type == 0 && tiles_to_block[cell].element != element):
				return false
			if (tiles_to_block[cell].Type == 1 && tiles_to_block[cell].element == element):
				return false
		
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
func place(offsets: Array[Vector2i], origin: Vector2i, element: Elements.Id, mat :MaterialData) -> bool:
	if is_animating:
		return false
	
	if GameManager.is_end_turn_in_progress:
		return false
	
	if not can_place(offsets, origin, element):
		return false
	
	# For each block, register it in the grid
	var placed: Array[Vector2i] = []
	for offset in offsets: #subtracting this last vector to centre the shape's offsets around 0,0
		var cell := origin + offset - Vector2i(1,1) if GameManager._active_card.card_data.shape.display_name != "I-shape" else origin + offset
		placed.append(cell)
	
	# Signal for each new block that is has been placed on a certain cell
	for cell in placed:
		block_placed.emit(cell, element, mat)
	
	shape_placed.emit(placed, element)
	mat.handler.play()
	lines.queue_redraw()
	return true

func reset_level() -> void:
	for block in cell_to_block.values():
		block.queue_free()
	cell_to_block.clear()
	_level_cleared_fired = false
	lava_row = grid_height
	lava_overlay.position = Vector2(0, float(lava_row) * cell_size)
	lines.queue_redraw()

func rise_lava(n: int) -> void:
	if is_animating:
		return
	var target := maxi(objective_row, lava_row - n)
	lava_row = target
	var target_y := float(target) * float(cell_size)
	var tex := lava_overlay.sprite_frames.get_frame_texture("lava", 0)
	var sprite_h: float = float(tex.get_height()) * lava_overlay.scale.y if tex != null else 0.0
	var bottom_target_y := target_y + sprite_h
	is_animating = true
	var tw := create_tween()
	tw.tween_property(lava_overlay, "position:y", target_y, lava_rise_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	SFX.rise()
	await tw.finished
	
	for key_below_lava in tiles_to_block_nodes.keys().filter(func(x): return x[1] >= lava_row):
		tiles_to_block_nodes[key_below_lava].queue_free()
		tiles_to_block_nodes.erase(key_below_lava)
		tiles_to_block.erase(key_below_lava)
	
	await _run_cascade()
	is_animating = false
	lines.queue_redraw()

func apply_level_data(data: LevelData) -> void:
	for b in cell_to_block.values():
		if is_instance_valid(b):
			b.queue_free()
	cell_to_block.clear()
	
	grid_width  = data.grid_width
	grid_height = data.grid_height
	objective_row = data.objective_row
	lava_row = grid_height + data.lava_delay
	_level_cleared_fired = false
	is_animating = false
	
	#allocating tiles to each modifier
	level_modifiers = data.level_modifiers
	var i = 0
	for modifier in level_modifiers:
		var total_cells = grid_height * grid_width - (objective_row * grid_width) #getting total number of cells
		var num_of_tiles: int = total_cells * 0.05 * modifier.intensity_level
		var bottom_of_grid: int = grid_height - 1
		
		#Lava Mines will not appear on first or second rows
		if (modifier.Type == Modifier.Types.LAVA_MINE):
			num_of_tiles -= 2 * grid_width * 0.05 * modifier.intensity_level
			bottom_of_grid -= 2
		
		i = 0
		while i <= num_of_tiles:
			var random_tile = Vector2i(_rng.randi_range(0,grid_width - 1), _rng.randi_range(objective_row,bottom_of_grid))
			if (random_tile in tiles_to_block.keys() && total_cells > 0): #reroll tile if it's already being used
				total_cells = total_cells - 1
				continue
			if (total_cells <= 0): #no more places to put tiles
				break
			tiles_to_block[random_tile] = modifier.Type
			place_tile(random_tile, modifier)
			total_cells = total_cells - 1
			i = i + 1
			
	_fit_lava()
	lines.queue_redraw()

# Each tick get mouse position to get aimed cell
func _process(delta: float) -> void:
	var local_pos := to_local(get_global_mouse_position())
	var c := coords_to_cell(local_pos)
	# add this to the line below if you want more leeway in placing the blocks: && local_pos.distance_squared_to(cell_to_coords(c))*1.3 < local_pos.distance_squared_to(cell_to_coords(_last_hovered))
	if c != _last_hovered:
		_last_hovered = c
		hovered_cell = c
		lines.queue_redraw()

func _draw() -> void:
	var grid_area := Rect2(
		0.0 - grid_padding,
		0.0 - grid_padding,
		grid_width * cell_size + 2 * grid_padding,
		grid_height * cell_size + 2 * grid_padding
	)
	draw_rect(grid_area, Color(0, 0, 0, 0.5))

# Processor for "block placed" signal: actually spawns the block node
func _on_block_placed(cell: Vector2i, element: Elements.Id, mat : MaterialData) -> void:
	var b := BLOCK.instantiate()
	b.position = cell_to_coords(cell)
	b.element = element
	b.mat = mat
	# todo: setup the material
	block_root.add_child(b)
	cell_to_block[cell] = b

func _on_shape_placed(cells: Array[Vector2i], element: Elements.Id) -> void:
	SFX.place()
	
	#todo: remove the sprite of the mine once its triggered.
	var mine_count : Array[Vector2i] = cells.filter(func (cell): return cell in tiles_to_block.keys() && tiles_to_block[cell].Type == Modifier.Types.LAVA_MINE)
	if (len(mine_count) > 0):
		GameManager.is_end_turn_in_progress = true
		await rise_lava(len(mine_count))
		GameManager.is_end_turn_in_progress = false
		for mine in mine_count:
			tiles_to_block.erase(mine)
			if (mine in tiles_to_block_nodes.keys()):
				tiles_to_block_nodes[mine].queue_free()
				tiles_to_block_nodes.erase(mine)
	
	# Send the win singal once ever, if any placed cell turned the line into finished line above the objective
	if not _level_cleared_fired and objective_row >= 0 and objective_row < grid_height:
		var checked_rows := {}
		for cell in cells:
			if cell.y > objective_row:
				continue
			if checked_rows.has(cell.y):
				continue
			checked_rows[cell.y] = true
			if _is_row_full(cell.y):
				_level_cleared_fired = true
				var buffer := 0
				for y in range(objective_row + 1, lava_row):
					if _is_row_full(y):
						buffer += 1
				level_cleared.emit(buffer)
				break

# todo: debug function, to be removed
func _unhandled_input(event: InputEvent) -> void:
	if GameManager.is_end_turn_in_progress or GameManager.is_level_won:
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and GameManager._active_card != null:
		var test_offsets: Array[Vector2i] = GameManager._active_card.card_data.shape.offsets
		var ok := place(test_offsets, hovered_cell, GameManager._active_card.card_data.element, GameManager._active_card.card_data.material)
		
		if not ok:
			SFX.denied()
			placement_rejected.emit(test_offsets)
		else: 
			cursor.play("throw")

func _run_cascade() -> void:
	if lava_row >= grid_height:
		return
	
	while true:
		var unfinished := _unfinished_rows_in_lava()
		if unfinished.is_empty():
			break
		
		await _flash_rows(unfinished)
		if (len(unfinished) > 0):
			SFX.layer_break()
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

func _fit_lava() -> void:
	if lava_overlay == null or lava_overlay.sprite_frames == null:
		return
	
	var tex := lava_overlay.sprite_frames.get_frame_texture("lava", 0)
	if tex == null:
		return
	
	var total_lava_w := float(grid_width * cell_size)
	var uniform_scale := total_lava_w / float(tex.get_width())
	
	lava_overlay.centered = false
	lava_overlay.scale = Vector2(uniform_scale, uniform_scale)
	lava_overlay.position = Vector2(0, float(lava_row) * float(cell_size))
	
	lava2_overlay.material.set_shader_parameter("clip_global_x", 620.0)
	lava2_overlay.material.set_shader_parameter("keep_left", true)
	lava_overlay.play("lava")
	lava2_overlay.play("lava")
	lava3_overlay.play("lava")

func _update_grid_position() -> void:
	var grid_px := Vector2(grid_width * cell_size, grid_height * cell_size)
	var vp_size := get_viewport_rect().size
	position = Vector2(
		300 - grid_px.x * 0.5,
		vp_size.y * 0.5 - grid_px.y * 0.5
	)
func place_tile(cell: Vector2i, modifier: Modifier) -> void:
	var b := Sprite2D.new()
	b.centered = false
	#index 0 = RED, 1 = BLUE, 2 = GREEN, 3 = YELLOW
	var element_lookup = [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW]
	if (modifier.Type == 0): #as in, its an "exclusive element" tile
		b.texture = load("res://assets/sprites/Exclusive.png")
	elif (modifier.Type == 1): #as in, its an "anti element" tile
		b.texture = load("res://assets/sprites/Anti.png")
	else: #if its an Acid Mine tile
		b.texture = load("res://assets/sprites/Mine.png")
	b.scale = Vector2(0.625,0.625)
	if (modifier.Type < 2):
		b.modulate = Color(element_lookup[modifier.element])
	
	b.position = cell_to_coords(cell)
	# todo: setup the material
	tile_root.add_child(b)
	tiles_to_block[cell] = modifier
	tiles_to_block_nodes[cell] = b #adding node to dict so we can remove it later.
