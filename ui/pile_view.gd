extends Control

@export var icon_texture: Texture2D

@onready var icon: TextureRect = $Icon
@onready var count_label: Label = $CountLabel

signal clicked(pile: CardPile)

var pile: CardPile = null

func _ready() -> void:
	if icon_texture != null:
		icon.texture = icon_texture

func _exit_tree() -> void:
	unbind()

func bind(p: CardPile) -> void:
	if pile != null and pile.changed.is_connected(_on_changed):
		pile.changed.disconnect(_on_changed)
	pile = p
	if pile != null:
		pile.changed.connect(_on_changed)
	_refresh()

func unbind() -> void:
	if pile != null and pile.changed.is_connected(_on_changed):
		pile.changed.disconnect(_on_changed)
	pile = null
	_refresh()

func _gui_input(event: InputEvent) -> void:
	if pile == null:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(pile)
		accept_event()

func _on_changed() -> void:
	_refresh()

func _refresh() -> void:
	var count := pile.size() if pile != null else 0
	count_label.text = str(count)
