extends Control
@onready var Mainmenu = $CenterContainer
@onready var OptionMenu = $OptionMenu
@onready var Credits = $Credits
@onready var MasterSlider = $OptionMenu/MarginContainer/VBoxContainer/GridContainer/MasterSlider
@onready var MusicSlider = $OptionMenu/MarginContainer/VBoxContainer/GridContainer/MusicSlider
@onready var SFXSlider = $OptionMenu/MarginContainer/VBoxContainer/GridContainer/SFXSlider

func _ready() -> void:
	GameManager.play_slide_in(self)

func _on_play_button_pressed() -> void:
	randomize()
	SFX.button()
	GameManager.start_run()

func _on_options_button_pressed() -> void:
	SFX.button()
	Mainmenu.visible = false
	OptionMenu.visible = true
	MasterSlider.value = Utils.getAudio("Master")
	MusicSlider.value = Utils.getAudio("Music")
	SFXSlider.value = Utils.getAudio("SFX")

func _on_quit_button_pressed() -> void:
	SFX.button()
	Mainmenu.visible = false
	Credits.visible = true

#Option Menu

func _on_back_button_pressed() -> void:
	SFX.button()
	Mainmenu.visible = true
	OptionMenu.visible = false
	Credits.visible = false

func _on_master_slider_value_changed(value: float) -> void:
	Utils.changeAudio("Master",value)


func _on_music_slider_value_changed(value: float) -> void:
	Utils.changeAudio("Music",value)


func _on_sfx_slider_value_changed(value: float) -> void:
	Utils.changeAudio("SFX",value)
