# Test field for checking Hand, Card and Cursor interaction

extends Control

@onready var hand: Control = $Hand2
@onready var cursor_layer: CanvasLayer = $CursorLayer2

func _ready() -> void:
	# Init GameManager with hand and cursor layer
	GameManager.hand = hand
	GameManager.cursor_layer = cursor_layer
	
	# Wire hand's signal to be processed by GameManager
	hand.card_selected.connect(GameManager.select_card)
	
	# Set the hand to be filled with the whole deck
	GameManager.init_deck()
	GameManager.start_turn()
