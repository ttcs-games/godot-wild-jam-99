class_name Modifier
extends Resource

enum Types {ONLY_BLUE, ONLY_RED, ONLY_GREEN, ONLY_YELLOW, REJECT_BLUE, REJECT_RED, REJECT_GREEN, REJECT_YELLOW, LAVA_MINE, FASTER_LAVA}
const display_names = {Types.ONLY_BLUE: "Exclusively Water", Types.ONLY_RED: "Exclusively Fire", Types.ONLY_GREEN: "Exclusively Earth", Types.ONLY_YELLOW: "Exclusively Lightning", Types.REJECT_BLUE: "Anti-Water", Types.REJECT_RED: "Anti-Fire", Types.REJECT_GREEN: "Anti-Earth", Types.REJECT_YELLOW: "Anti-Lightning", Types.LAVA_MINE: "Lava Mine", Types.FASTER_LAVA: "Faster Lava"}

var tiles_affected: Array[Vector2i] = []
var Type : Types = Types.ONLY_BLUE
var intensity_level: int = 0

func _init(new_type: int, level: int) -> void:
	Type = new_type
	intensity_level = level
	
func get_display_name() -> String:
	return "%s - Intensity Level %d" % [display_names[Type], intensity_level]

func assign_tiles(tiles: Array[Vector2i]) -> void:
	tiles_affected.assign(tiles)
	
func get_tiles() -> Array[Vector2i]:
	return tiles_affected
	
func equals(b : Modifier) -> bool:
	return self.Type == b.Type
