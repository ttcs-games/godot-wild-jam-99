extends Control

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var stats_grid: GridContainer = $MarginContainer/VBoxContainer/StatsGrid
@onready var deck_view: Control = $MarginContainer/VBoxContainer/DeckView
@onready var play_button: Button = $MarginContainer/VBoxContainer/PlayButton
@onready var deck_layer: CanvasLayer = $CanvasLayer
@onready var cursor_animation: AnimatedSprite2D = $CanvasLayer/Cursor

func _ready() -> void:
	if GameManager.deck == null:
		GameManager.init_deck()
	
	GameManager.cursor_layer = deck_layer
	GameManager.cursorAnimation = cursor_animation
	
	var level_number = GameManager.current_level_data.level_number if GameManager.current_level_data != null else 1 
	var data = LevelFactory.generate(level_number)
	deck_view.bind(GameManager.deck)
	deck_view.clicked.connect(func(pile): GameManager.open_pile_viewer(pile, "Deck"))
	play_button.pressed.connect(_on_play_pressed)
	_populate(data)
	GameManager.current_level_data = data

func _populate(data: LevelData) -> void:
	title_label.text = data.display_name
	for child in stats_grid.get_children():
		child.queue_free()
	
	var rows_from_bottom := data.grid_height - data.objective_row
	_add_row("Grid Size", "%d × %d" % [data.grid_width, data.grid_height])
	_add_row("Objective", "Layer %d from top (%d from bottom)" % [data.objective_row, rows_from_bottom])
	_add_row("Lava per turn", "%d layer%s" % [data.lava_per_turn, "" if data.lava_per_turn == 1 else "s"])
	_add_row("Draw per turn", "%d card%s" % [data.draw_per_turn, "" if data.draw_per_turn == 1 else "s"])

func _add_row(label_text: String, value_text: String) -> void:
	var l := Label.new()
	l.text = label_text
	l.add_theme_font_size_override("font_size", 20)
	l.modulate = Color(0.7, 0.7, 0.8)
	var v := Label.new()
	v.text = value_text
	v.add_theme_font_size_override("font_size", 20)
	stats_grid.add_child(l)
	stats_grid.add_child(v)

func _on_play_pressed() -> void:
	GameManager.start_level()
