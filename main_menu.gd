extends Control
@onready var Mainmenu = $CenterContainer
@onready var OptionMenu = $OptionMenu
@onready var MasterSlider = $OptionMenu/MarginContainer/VBoxContainer/GridContainer/MasterSlider
@onready var MusicSlider = $OptionMenu/MarginContainer/VBoxContainer/GridContainer/MusicSlider
@onready var SFXSlider = $OptionMenu/MarginContainer/VBoxContainer/GridContainer/SFXSlider

func _ready() -> void:
	GameManager.play_slide_in(self)

func _on_play_button_pressed() -> void:
	randomize()
	GameManager.start_run()

func _on_options_button_pressed() -> void:
	Mainmenu.visible = false
	OptionMenu.visible = true
	MasterSlider.value = getAudio("Master")
	MusicSlider.value = getAudio("Music")
	SFXSlider.value = getAudio("SFX")
	print(getAudio("Master"))

func _on_quit_button_pressed() -> void:
	get_tree().quit()

#Option Menu

func _on_back_button_pressed() -> void:
	Mainmenu.visible = true
	OptionMenu.visible = false



func getAudio(busName):
	var busIndex = AudioServer.get_bus_index(busName)
	return AudioServer.get_bus_volume_linear(busIndex)

func changeAudio (busName:String, value:float):
	var busIndex = AudioServer.get_bus_index(busName)
	AudioServer.set_bus_volume_db(busIndex, linear_to_db(value) )
	AudioServer.set_bus_mute(busIndex, value<0.01)

func _on_master_slider_value_changed(value: float) -> void:
	changeAudio("Master",value)


func _on_music_slider_value_changed(value: float) -> void:
	changeAudio("Music",value)


func _on_sfx_slider_value_changed(value: float) -> void:
	changeAudio("SFX",value)
