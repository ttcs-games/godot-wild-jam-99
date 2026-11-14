# A singular tile represeting a part of a shape
# Only stores its element and material so it can select correct sprite and color itself

extends Sprite2D

@export var element: Elements.Id = Elements.Id.RED
# todo: material, sprite assignment

# When created, set shift the hue equal to its assigned element
func _ready() -> void:
	var mat := material as ShaderMaterial
	mat.set_shader_parameter("shift_amount", Elements.color(element))
