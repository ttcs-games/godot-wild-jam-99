# A singular tile represeting a part of a shape
# Only stores its element and material so it can select correct sprite and color itself

extends Sprite2D

@export var element: Elements.Id = Elements.Id.RED
# todo: material, sprite assignment

@onready  var mat: MaterialData = preload("res://data/materials/basic_material.tres")	

# When created, set shift the hue equal to its assigned element
func _ready() -> void:
	var shader := material as ShaderMaterial
	shader.set_shader_parameter("shift_amount", Elements.color(element))
	texture=mat.sprite
