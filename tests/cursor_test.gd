# Test field for checking Hand, Card and Cursor interaction

extends Node2D

@onready var hand: Control = $Control/Hand2
@onready var grid: Node2D = $Grid
@onready var cursor_layer: CanvasLayer = $Control/CursorLayer2
@onready var cursor_animation: AnimatedSprite2D = $Control/CursorLayer2/Cursor
@onready var deck_view: Control = $Control/DeckView
@onready var discard_view: Control = $Control/DiscardView
@onready var turn_label: Label = $HUD/VBoxContainer/TurnLabel
@onready var end_turn_button: Button = $HUD/VBoxContainer/EndTurnButton
@onready var victory_panel: Control = $VictoryLayer/VictoryPanel
@onready var buffer_line: Label = $VictoryLayer/VictoryPanel/CenterContainer/MarginContainer/VBoxContainer/BufferLabel
@onready var continue_button: Button = $VictoryLayer/VictoryPanel/CenterContainer/MarginContainer/VBoxContainer/ContinueButton

func _ready() -> void:
	# Init GameManager with hand and cursor layer
	GameManager.hand = hand
	GameManager.cursor_layer = cursor_layer
	GameManager.cursorAnimation = cursor_animation
	GameManager.grid = grid
	
	# Wire hand's signal to be processed by GameManager
	hand.card_selected.connect(GameManager.select_card)
	grid.game_over.connect(GameManager.end_run)
	
	# Set the hand to be filled with the whole deck
	#GameManager.init_deck()
	#GameManager.start_level()
	
	deck_view.bind(GameManager.deck)
	deck_view.clicked.connect(func(pile): GameManager.open_pile_viewer(pile, "Deck"))
	
	discard_view.bind(GameManager.discard)
	discard_view.clicked.connect(func(pile): GameManager.open_pile_viewer(pile, "Discarded"))
	
	end_turn_button.pressed.connect(func(): GameManager.end_turn(turn_label))
	
	turn_label.text = "Turn %d" % GameManager.turn_number
	grid.game_over.connect(GameManager.end_run)
	grid.apply_level_data(GameManager.current_level_data)
	
	grid.level_cleared.connect(_on_level_cleared)
	continue_button.pressed.connect(_on_continue_pressed)
	
	GameManager.start_turn()

func _on_level_cleared(buffer: int) -> void:
	GameManager.is_level_won = true
	GameManager.remove_card()
	GameManager.REWARD_AMOUNT = 3 + buffer
	victory_panel.visible = true
	var plural := "" if buffer == 1 else "s"
	buffer_line.text = "Built %d full layer%s above lava  +%d reward%s" % [
		buffer, plural, buffer, plural
	]

func _on_continue_pressed() -> void:
	GameManager.finish_level()
