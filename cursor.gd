extends AnimatedSprite2D


# Called when the node enters the scene tree for the first time.
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN	
	play("idle")

func _process(_delta):
	position.x = get_viewport().get_mouse_position().x
	position.y = get_viewport().get_mouse_position().y+20
		

func _on_animation_finished() -> void:
	if animation == "hover_exit" || animation == "throw":
		play("idle")
