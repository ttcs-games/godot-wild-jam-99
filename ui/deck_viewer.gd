extends Control

const CARD := preload("res://game_objects/card.tscn")
@onready var title_label: Label = $ColorRect/CenterContainer/Panel/MarginContainer/VBoxContainer/TopBar/TitleLabel
@onready var close_button: Button = $ColorRect/CenterContainer/Panel/MarginContainer/VBoxContainer/TopBar/CloseButton
@onready var card_grid: GridContainer = $ColorRect/CenterContainer/Panel/MarginContainer/VBoxContainer/CardScroll/CardGrid

signal close_requested

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	close_button.pressed.connect(func(): close_requested.emit())
	card_grid.sort_children.connect(_on_grid_sorted)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close_requested.emit()
		get_viewport().set_input_as_handled()

func setup(pile: CardPile, title: String) -> void:
	title_label.text = title
	
	var cards := pile.get_cards_copy()
	cards.sort_custom(CardData.compare_for_display)
	
	for child in card_grid.get_children():
		child.queue_free()
	
	for data in cards:
		var card: Control = CARD.instantiate()
		card.setup(data)
		card_grid.add_child(card)

func _on_grid_sorted() -> void:
	for card in card_grid.get_children():
		card._rest_position = card.position
