extends Control

@onready var restart_button: Button = $CenterContainer/VBoxContainer/RestartButton
@onready var menu_button: Button = $CenterContainer/VBoxContainer/MenuButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	MusicManager.play_loss()
	GameManager.play_slide_in(self)
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)


func _on_restart_pressed() -> void:
	SFX.button()
	GameManager.start_run()

func _on_menu_pressed() -> void:
	SFX.button()
	GameManager.transition_to_scene("res://Main_menu.tscn")
