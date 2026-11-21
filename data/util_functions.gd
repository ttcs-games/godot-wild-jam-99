# Helper script, containing common functions to use in any script
class_name Utils

## Get the smallest rectangle that can contain the shape (all the blocks) [br]
## example: for L shape it would be a 2x3 box
static func bounding_box(offsets: Array[Vector2i]) -> Rect2i:
	# no blocks - empty box
	if offsets.is_empty():
		return Rect2i()
	
	# get coordinates for top left (min) and bottom right (max)
	var min_p := offsets[0]
	var max_p := offsets[0]
	# check each block's coordinates
	for o in offsets:
		# get minimum x and y coordinates independently
		min_p = Vector2i(min(min_p.x, o.x), min(min_p.y, o.y))
		# get maximum x and y coordinates independently
		max_p = Vector2i(max(max_p.x, o.x), max(max_p.y, o.y))
	
	# form a rectangle which could fit the shape. Add extra (1,1)!
	# because stored coordinates start at 0: a (0,0) block still needs (1,1) rectangle to fit
	return Rect2i(min_p, max_p - min_p + Vector2i.ONE)

# Replace [ with a special character (to not confuse rich text with tag start)
static func escape_bbcode(text: String) -> String:
	return text.replace("[", "[lb]")

static func getAudio(busName):
	var busIndex = AudioServer.get_bus_index(busName)
	return AudioServer.get_bus_volume_linear(busIndex)

static func changeAudio (busName:String, value:float):
	var busIndex = AudioServer.get_bus_index(busName)
	AudioServer.set_bus_volume_db(busIndex, linear_to_db(value) )
	AudioServer.set_bus_mute(busIndex, value<0.01)
