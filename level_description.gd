extends Control

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var stats_grid: GridContainer = $MarginContainer/VBoxContainer/StatsGrid
@onready var deck_view: Control = $MarginContainer/VBoxContainer/HBoxContainer/DeckView
@onready var play_button: Button = $MarginContainer/VBoxContainer/PlayButton
@onready var deck_layer: CanvasLayer = $CanvasLayer
@onready var cursor_animation: AnimatedSprite2D = $CanvasLayer/Cursor

@onready var settings_button: Button = $SettingsButton
@onready var back_button: Button = $Control2/OptionMenu/MarginContainer/VBoxContainer/GridContainer/BackButton
@onready var settings_panel: Control = $Control2

@onready var MasterSlider = $Control2/OptionMenu/MarginContainer/VBoxContainer/GridContainer/MasterSlider
@onready var MusicSlider = $Control2/OptionMenu/MarginContainer/VBoxContainer/GridContainer/MusicSlider
@onready var SFXSlider = $Control2/OptionMenu/MarginContainer/VBoxContainer/GridContainer/SFXSlider

func _ready() -> void:
	GameManager.play_slide_in(self)
	if GameManager.deck == null:
		GameManager.init_deck()
	
	GameManager.cursor_layer = deck_layer
	GameManager.cursorAnimation = cursor_animation
	
	var level_number = GameManager.current_level_data.level_number + 1  if GameManager.current_level_data != null else 1 
	var data = LevelFactory.generate(level_number)
	
	#the Faster Lava modifier is applied here, so that it appears on the level description
	if data.level_modifiers.any(func(x): return x.Type == Modifier.Types.FASTER_LAVA):
		data.lava_delay += 1 #if lava modifier exists, the lava is delayed by 2 turns
		data.lava_per_turn *= 2 #if lava modifier exists, lava speed is doubles	

	deck_view.bind(GameManager.deck)
	deck_view.clicked.connect(func(pile): GameManager.open_pile_viewer(pile, "Deck"))
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	back_button.pressed.connect(_on_back_pressed)
	_populate(data)
	data.level_modifiers = data.level_modifiers.filter(func (x): return x.Type != Modifier.Types.FASTER_LAVA)
	GameManager.current_level_data = data

func _populate(data: LevelData) -> void:
	title_label.text = data.display_name
	for child in stats_grid.get_children():
		child.queue_free()
	
	var rows_from_bottom := data.grid_height - data.objective_row
	var first_visible_turn := data.lava_delay + 2
	_add_row("Grid Size", "%d x %d" % [data.grid_width, data.grid_height])
	
	var level_modifier_string = ""
	if (len(data.level_modifiers) > 0):
		level_modifier_string += "   ("
		for modifier in data.level_modifiers:
			level_modifier_string += " * " + modifier.get_display_name()
		level_modifier_string += " * )"
	_add_row("Modifiers", "%d" % [len(data.level_modifiers)] + level_modifier_string)
	
	_add_row("Objective", "Full layer at %d (from bottom) or higher" % [rows_from_bottom])
	if data.lava_delay > 0:
		_add_row("Acid begins", "Turn %d (%d safe turn%s)" % [
			first_visible_turn, data.lava_delay, "" if data.lava_delay == 1 else "s"
		])
	else:
		_add_row("Acid begins", "Turn 2 (no delay)")
	
	_add_row("Acid per turn", "%d layer%s" % [data.lava_per_turn, "" if data.lava_per_turn == 1 else "s"])
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
	SFX.button()
	GameManager.start_level()

func _on_settings_pressed() -> void:
	SFX.button()
	GameManager.remove_card()
	settings_panel.visible = true
	settings_button.visible = false
	MasterSlider.value = Utils.getAudio("Master")
	MusicSlider.value = Utils.getAudio("Music")
	SFXSlider.value = Utils.getAudio("SFX")

func _on_back_pressed() -> void:
	SFX.button()
	settings_panel.visible = false
	settings_button.visible = true

func _on_master_slider_value_changed(value: float) -> void:
	Utils.changeAudio("Master",value)

func _on_music_slider_value_changed(value: float) -> void:
	Utils.changeAudio("Music",value)

func _on_sfx_slider_value_changed(value: float) -> void:
	Utils.changeAudio("SFX",value)
