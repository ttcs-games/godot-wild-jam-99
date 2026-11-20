class_name Modifier
extends Resource

enum Types {EXCLUSIVE, ANTI, LAVA_MINE, FASTER_LAVA}
const elements = ["Fire", "Water", "Ground", "Lightning"]
const type_name = ["Exclusively", "Anti", "Acid Mines", "Quicker Acid"]

var tiles_affected: Array[Vector2i] = []
var element: Elements.Id = 0
var Type : Types = Types.EXCLUSIVE
var intensity_level: int = 0

func _init(new_type: int, elm: Elements.Id, level: int) -> void:
	Type = new_type
	if new_type < 2:
		element = elm
	intensity_level = level
	
func get_display_name() -> String:
	if Type < 2:
		return "%s %s - Intensity Level %d" % [type_name[Type], elements[element], intensity_level]
	else:
		return "%s - Intensity Level %d" % [type_name[Type], intensity_level]
	

func assign_tiles(tiles: Array[Vector2i]) -> void:
	tiles_affected.assign(tiles)
	
func get_tiles() -> Array[Vector2i]:
	return tiles_affected
	
func equals(b : Modifier) -> bool:
	if (self.Type == b.Type):
		return self.element == b.element
	return false
