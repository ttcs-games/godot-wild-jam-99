extends TextureRect


@export var flip_time := 0.4
@export var lift := 1.1            # card grows slightly mid-flip, set to 1.0 to disable
@export var start_face_up := false

@onready var front: CanvasItem = $Cover
@onready var back: CanvasItem = $Back

var face_up := false
var flipping := false
var base_scale := Vector2.ONE


func _ready() -> void:
	base_scale = scale
	face_up = start_face_up
	_show_face()


func _show_face() -> void:
	front.visible = face_up
	back.visible = not face_up


func flip() -> void:
	if flipping:
		return
	flipping = true

	var half := flip_time * 0.5
	var tween := create_tween()

	# first half: squash to a thin line
	tween.set_parallel(true)
	tween.tween_property(self, "scale:x", 0.0, half) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale:y", base_scale.y * lift, half) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# swap faces at the halfway point
	tween.chain().tween_callback(func():
		face_up = not face_up
		_show_face())

	# second half: expand back out
	tween.chain().set_parallel(true)
	tween.tween_property(self, "scale:x", base_scale.x, half) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale:y", base_scale.y, half) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	tween.chain().tween_callback(func(): flipping = false)


# click the card to flip it
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT and not flipping:
		var visible_face := front if face_up else back
		if visible_face is Sprite2D and visible_face.get_rect().has_point(get_local_mouse_position()):
			flip()
