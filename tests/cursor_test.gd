# Test field for checking Hand, Card and Cursor interaction

extends Control

@onready var hand: Control = $Hand2
@onready var cursor_layer: CanvasLayer = $CursorLayer2
@onready var cursor_animation: AnimatedSprite2D = %Cursor
@onready var deck_view: Control = $DeckView

func _ready() -> void:
	# Init GameManager with hand and cursor layer
	GameManager.hand = hand
	GameManager.cursor_layer = cursor_layer
	GameManager.cursorAnimation = cursor_animation
	
	# Wire hand's signal to be processed by GameManager
	hand.card_selected.connect(GameManager.select_card)
	
	# Set the hand to be filled with the whole deck
	GameManager.init_deck()
	GameManager.start_turn()
	
	deck_view.bind(GameManager.deck)
	deck_view.clicked.connect(func(pile): GameManager.open_pile_viewer(pile, "Deck"))
