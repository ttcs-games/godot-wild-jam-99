# base_handler.gd
class_name BaseHandler
extends Resource

func play() -> void:
	pass

# Rules: override these in children
func needs_foundation() -> bool:
	return false

func can_place_anywhere() -> bool:   # skips the lava-row restriction
	return false

func ignores_opposition() -> bool:
	return false
 
