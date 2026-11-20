extends Control

@export var icon_texture: Texture2D

@onready var icon: TextureRect = $Icon
@onready var count_label: Label = $CountLabel

signal clicked(pile: CardPile)

var pile: CardPile = null
var _bump_tween: Tween = null

func _ready() -> void:
	if icon_texture != null:
		icon.texture = icon_texture

func _exit_tree() -> void:
	unbind()

func bind(p: CardPile) -> void:
	if pile != null and pile.changed.is_connected(_on_changed):
		pile.changed.disconnect(_on_changed)
	if pile != null and pile.show_change.is_connected(_on_show_change):
		pile.changed.disconnect(_on_show_change)
	pile = p
	if pile != null:
		pile.changed.connect(_on_changed)
		pile.show_change.connect(_on_show_change)
	_refresh()

func unbind() -> void:
	if pile != null and pile.changed.is_connected(_on_changed):
		pile.changed.disconnect(_on_changed)
	if pile != null and pile.show_change.is_connected(_on_show_change):
		pile.changed.disconnect(_on_show_change)
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

func _on_show_change() -> void:
	count_label.pivot_offset = count_label.size * 0.5
	if _bump_tween != null and _bump_tween.is_valid():
		_bump_tween.kill()
	
	_bump_tween = create_tween()
	_bump_tween.tween_property(count_label, "scale", Vector2(1.25, 1.25), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_bump_tween.tween_property(count_label, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
