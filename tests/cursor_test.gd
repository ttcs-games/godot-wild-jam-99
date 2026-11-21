# Test field for checking Hand, Card and Cursor interaction

extends Node2D

@onready var hand: Control = $Control/Hand2
@onready var grid: Node2D = $Grid
@onready var cursor_layer: CanvasLayer = $Control/CursorLayer2
@onready var cursor_animation: AnimatedSprite2D = $Control/CursorLayer2/Cursor
@onready var deck_view: Control = $Control/DeckView
@onready var discard_view: Control = $Control/DiscardView
@onready var turn_label: Label = $EndTurnButton/TurnLabel
@onready var end_turn_button: Button = $EndTurnButton
@onready var victory_panel: Control = $VictoryLayer/VictoryPanel
@onready var title_label: Label = $VictoryLayer/VictoryPanel/CenterContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var buffer_line: Label = $VictoryLayer/VictoryPanel/CenterContainer/MarginContainer/VBoxContainer/BufferLabel
@onready var continue_button: Button = $VictoryLayer/VictoryPanel/CenterContainer/MarginContainer/VBoxContainer/ContinueButton
@onready var finish_button: Button = $VictoryLayer/VictoryPanel/CenterContainer/MarginContainer/VBoxContainer/FinishButton
@onready var cursor: AnimatedSprite2D = %Cursor
@onready var redraw_label: Label = $Control/RedrawButton/RedrawLabel
@onready var info: Panel = $Info
@onready var close_button: Button = $Info/CloseButton
@onready var help_button: Button = $HelpButton
@onready var settings_button: Button = $SettingsButton
@onready var back_button: Button = $Control2/OptionMenu/MarginContainer/VBoxContainer/GridContainer/BackButton
@onready var settings_panel: Control = $Control2

@onready var MasterSlider = $Control2/OptionMenu/MarginContainer/VBoxContainer/GridContainer/MasterSlider
@onready var MusicSlider = $Control2/OptionMenu/MarginContainer/VBoxContainer/GridContainer/MusicSlider
@onready var SFXSlider = $Control2/OptionMenu/MarginContainer/VBoxContainer/GridContainer/SFXSlider

func _ready() -> void:
	GameManager.play_slide_in(self)
	# Init GameManager with hand and cursor layer
	GameManager.hand = hand
	GameManager.cursor_layer = cursor_layer
	GameManager.cursorAnimation = cursor_animation
	GameManager.grid = grid
	GameManager.cursor = cursor
	
	# Wire hand's signal to be processed by GameManager
	hand.card_selected.connect(GameManager.select_card)
	grid.game_over.connect(GameManager.end_run)
	
	#Update the redraw button available uses
	redraw_label.text = "x%d" % [GameManager.redraws]
	
	# Set the hand to be filled with the whole deck
	#GameManager.init_deck()
	#GameManager.start_level()
	
	deck_view.bind(GameManager.deck)
	deck_view.clicked.connect(func(pile): GameManager.open_pile_viewer(pile, "Deck"))
	
	discard_view.bind(GameManager.discard)
	discard_view.clicked.connect(func(pile): GameManager.open_pile_viewer(pile, "Discarded", 1000, false))
	
	end_turn_button.pressed.connect(func(): GameManager.end_turn(turn_label, end_turn_button))
	
	turn_label.text = "Turn %d" % GameManager.turn_number
	grid.apply_level_data(GameManager.current_level_data)
	if (GameManager.current_level_data.level_number == 1):
		info.visible = true
		help_button.visible = false
		settings_button.visible = false
	else:
		info.visible = false
		help_button.visible = true
		settings_button.visible = true
	
	grid.level_cleared.connect(_on_level_cleared)
	continue_button.pressed.connect(_on_continue_pressed)
	finish_button.pressed.connect(_on_finish_pressed)
	close_button.pressed.connect(_on_close_button)
	help_button.pressed.connect(_on_help_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	back_button.pressed.connect(_on_back_pressed)
	GameManager.start_turn()

func _on_level_cleared(buffer: int) -> void:
	GameManager.is_level_won = true
	GameManager.remove_card()
	GameManager.REWARD_AMOUNT = 3 + buffer
	victory_panel.visible = true
	
	if GameManager.current_level_data.level_number == 9:
		continue_button.text = "Continue\n(infinite run)"
		title_label.text = "Congratulations!\nGame won"
	else:
		continue_button.text = "Continue"
		title_label.text = "Level complete"
	
	if GameManager.current_level_data.level_number >= 9:
		finish_button.disabled = false
		finish_button.visible = true
	else:
		continue_button.text = "Continue"
		finish_button.disabled = true
		finish_button.visible = false
	
	var plural := "" if buffer == 1 else "s"
	buffer_line.text = "Built %d full layer%s above lava | +%d reward%s" % [
		buffer, plural, buffer, plural
	]
	MusicManager.play_victory()

func _on_continue_pressed() -> void:
	SFX.button()
	GameManager.finish_level()

func _on_finish_pressed() -> void:
	SFX.button()
	MusicManager.switch_track()
	GameManager.transition_to_scene("res://Main_menu.tscn")


#redraw button's logic is handled here
func _on_redraw_button_pressed() -> void:
	cursor_animation.play("idle")
	GameManager.remove_card() #remove card so the player doesn't hold onto it
	if (GameManager.redraws == 0):
		return
	
	SFX.button()
	var cards_discarded_count = len(hand.cards)
	GameManager.redraws -= 1
	await GameManager._phase_discard_hand()
	await GameManager._phase_draw_hand(cards_discarded_count)

	redraw_label.text = "x%d" % [GameManager.redraws]

func _on_close_button() -> void:
	SFX.button()
	info.visible = false
	help_button.visible = true
	settings_button.visible = true

func _on_help_pressed() -> void:
	SFX.button()
	info.visible = true
	help_button.visible = false
	settings_button.visible = false

func _on_settings_pressed() -> void:
	SFX.button()
	GameManager.remove_card()
	cursor.play("idle")
	settings_panel.visible = true
	help_button.visible = false
	settings_button.visible = false
	MasterSlider.value = Utils.getAudio("Master")
	MusicSlider.value = Utils.getAudio("Music")
	SFXSlider.value = Utils.getAudio("SFX")

func _on_back_pressed() -> void:
	SFX.button()
	settings_panel.visible = false
	help_button.visible = true
	settings_button.visible = true

func _on_master_slider_value_changed(value: float) -> void:
	Utils.changeAudio("Master",value)

func _on_music_slider_value_changed(value: float) -> void:
	Utils.changeAudio("Music",value)

func _on_sfx_slider_value_changed(value: float) -> void:
	Utils.changeAudio("SFX",value)
