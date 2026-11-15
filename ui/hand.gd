extends Control

# SETTINGS
@export var min_visible_width: float = 30.0

# CONSTANTS
const CARD := preload("res://game_objects/card.tscn")
var cards: Array[Control] = []

# SIGNALS
# when card is selected
signal card_selected(card: Control, card_index: int)

func _ready() -> void:
	resized.connect(_layout)

# Ini the hand: create the cards
func setup(data_array: Array[CardData]) -> void:
	_clear()
	for data in data_array:
		var card: Control = CARD.instantiate()
		card.setup(data)
		add_child(card)
		card.clicked.connect(_on_card_clicked)
		cards.append(card)
	_layout()

# Destroy all cards
func _clear() -> void:
	for card in cards:
		card.queue_free()
	cards.clear()

# Draws the cards from hand
func _layout() -> void:
	var n := cards.size()
	# No cards or hand's node is literally nothing - skip
	if n == 0 or size.x <= 0.0:
		return
	
	# Get the card's width
	var card_w: float = cards[0].custom_minimum_size.x
	if card_w <= 0.0:
		return
	
	# Step is distance between cards (their top left)
	var step: float
	# One card - no need for step
	if n == 1:
		step = 0.0
	else:
		# Find the distance between two left edges of cards such that all will fit in hand
		# Substracting one card's width because final card will be shown fully,
		# unlike all cards before it that will be covered by new card after 'step' distance
		var raw_step := (size.x - card_w) / float(n - 1)
		# Limit the step to be between minimum setting and entire card's width
		# todo: maybe make a maximum slightly less - because card has ribbons at the edges
		step = clamp(raw_step, min_visible_width, card_w)
	
	# Calcualte total width of all cards  (distance between all but final card, plus final card's width)
	var total_w: float = step * (n - 1) + card_w
	# Starting coordinate (extra space in hand between start and finish is split equally)
	var start_x: float = (size.x - total_w) * 0.5
	
	# for each card, from left to right
	for i in n:
		var card: Control = cards[i] # get the card node
		card._rest_position = Vector2(start_x + step * i, 0) # set its resting position
		card._rest_z = i # Each next card will be on top when resting
		card.position = card._rest_position # set its real position
		card.z_index = card._rest_z # set its real layer

# Process card's signal - signal it to GameManager
# Not doing it directly from Card to GameManager because GameManager can't access Card's signal directly 
func _on_card_clicked(card: Control) -> void:
	card_selected.emit(card, cards.find(card))

func _on_grid_shape_placed(cells: Array[Vector2i], element: Elements.Id) -> void:
	print(cards)
	cards.remove_at(GameManager._active_card_index)
	_layout()
	print("this running?")
