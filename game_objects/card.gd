extends Control

# SETTINGS
const PREVIEW_PADDING := 8.0
const HOVER_SCALE := 1.1
const HOVER_LIFT := Vector2(0, -24)

# CONSTANTS
const SHAPE := preload("res://game_objects/shape.tscn")
@onready var preview_area: Control = $MarginContainer/VBoxContainer/PreviewArea
@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var description_label: Label = $MarginContainer/VBoxContainer/DescriptionLabel

# VARIABLES
var card_data: CardData # the data object
var _rest_position := Vector2.ZERO # resting position of the card
var _rest_z := 0 # resting layer position
var _current_shape: Node2D = null # shape on the card
var _current_offsets: Array[Vector2i] = [] # all the blocks on the card

var _built := false # flag to gurantee only one build call per existance
var _tween: Tween # Object that will represent the card and animate it
var _locked := false # flag to lock the card when selected

# SIGNALS
# When left click is pressed on the card
signal clicked(card: Control)

# Init card
func _ready() -> void:
	_rest_position = position # memorize current position as resting
	resized.connect(_update_pivot) # update pivot on resize
	_update_pivot() # upate pivot (just in case)
	mouse_entered.connect(_on_mouse_entered) 
	mouse_exited.connect(_on_mouse_exited)
	preview_area.resized.connect(_on_preview_resized) # redraw shape on resize
	_try_build() # safe build

# If space for shape on card changed size - redraw it
func _on_preview_resized() -> void:
	if _current_shape != null and not _current_offsets.is_empty():
		_fit_shape(_current_shape, _current_offsets)

# Update anchor to be at the center of the card
# So rotation and scale looks right (grows and rotates while keeping center position locked)
func _update_pivot() -> void:
	pivot_offset = size / 2.0

# Init method for card
func setup(data: CardData) -> void:
	card_data = data # store what kind of card it is
	# Safe build if its actually in a scene (not just created in-code, but added via add_child)
	if is_inside_tree():
		_try_build()

# Safe build (only once, if it has data for card)
func _try_build() -> void:
	if _built or card_data == null:
		return
	_built = true
	_build_visuals(card_data)

# Build the visual information for the card
func _build_visuals(data: CardData) -> void:
	# Fetch material, element, shape name from the card data
	var material_name := "?" if data.material == null else data.material.display_name
	var element_name := Elements.display_name(data.element)
	var shape_name := "?" if data.shape == null else data.shape.display_name
	# Form the Title
	title_label.text = "%s %s %s" % [material_name, element_name, shape_name]
	
	# Form the description from card's material data
	if data.material != null:
		description_label.text = data.material.description
	else:
		description_label.text = ""
	
	# Don't draw a shape if card's data doesnt have it
	if data.shape == null:
		return
	
	# Create a generic shape, init with blocks, element, store it for future reference; then make shape fit into the box
	# todo: init with material type
	var shape := SHAPE.instantiate()
	shape.offsets = data.shape.offsets
	shape.element = data.element
	preview_area.add_child(shape)
	_current_shape = shape
	_current_offsets = data.shape.offsets
	_fit_shape(shape, data.shape.offsets)

# Scale the shape so it fits the box and is placed at the center of the area
func _fit_shape(shape: Node2D, offsets: Array[Vector2i]) -> void:
	# skip if no blocks to draw
	if offsets.is_empty():
		return
		
	# get the smallest rectangle that can contain the shape (all the blocks)  
	var bbox := Utils.bounding_box(offsets)
	# get available area to fit the shape into (size of preview minus the padding from all sides 
	var available := preview_area.size - Vector2.ONE * (PREVIEW_PADDING * 2.0)
	# turn bbox's cells into actual pixel amount, e.g. (2,3)*32px = (64px, 96px)
	var natural = Vector2(bbox.size) * shape.cell_size
	
	# apply smallest scale to fit on both X and Y (1.0 as guard to not scale up)
	# example: available 100px but real shape is 200px -> scale is 0.5
	var fit_scale = min(available.x / natural.x, available.y / natural.y, 1.0)
	shape.scale = Vector2.ONE * fit_scale
	
	# place the shape at the center of the preview (based on its scaled down size)
	var visual_size = natural * fit_scale
	shape.position = (preview_area.size - visual_size) * 0.5

# Signal from mouse entering - make it hover
func _on_mouse_entered() -> void:
	_tween_to_hover(true)
	GameManager.cursor_Hover()

# Signal from mouse exiting - make it unhover if not selected
func _on_mouse_exited() -> void:
	if _locked:
		return
	_tween_to_hover(false)
	GameManager.cursor_Hover_exit()

# Input reading for when card is selected
func _gui_input(event: InputEvent) -> void:
	# If card is already selected - skip
	if _locked:
		return
	# If LMB is pressed - signal (handled by Hand) 
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self)
		accept_event() # stop event from spreading anywhere else

# Make card selected
func lock() -> void:
	_locked = true
	_tween_to_hover(true)
	

# Unselect the card
func unlock() -> void:
	_locked = false
	_tween_to_hover(false)

# Smoothly change visuals for card being hovered or unhovered
func _tween_to_hover(hovered: bool) -> void:
	# Remove the existing visual
	if _tween != null and _tween.is_valid():
		_tween.kill()
	# Make the hovered card's layer to be top
	z_index = 1000 if hovered else _rest_z
	# Create a visual animation
	# Tween.TRANS_BACK + Tween.EASE_OUT : The animation goes over the target values (looks like it "pops outs") 
	_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Set scale slightly bigger and card to move up a bit if hovered over
	# parallel() call means both parameter changes are executed at the same time 
	# animation happens over the span 0.15 seconds
	var target_scale := Vector2.ONE * (HOVER_SCALE if hovered else 1.0)
	var target_pos := _rest_position + (HOVER_LIFT if hovered else Vector2.ZERO)
	_tween.parallel().tween_property(self, "scale", target_scale, 0.15)
	_tween.parallel().tween_property(self, "position", target_pos, 0.15)
