extends Node

@onready var player_a: AudioStreamPlayer = $ChillPlayer
@onready var player_b: AudioStreamPlayer = $GamePlayer

var _active: AudioStreamPlayer
var _inactive: AudioStreamPlayer
var _tween: Tween

const SILENT_DB := -80.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Start both at the exact same moment. They will stay in sync forever.
	player_a.play(0.0)
	player_b.play(0.0)
	player_a.volume_db = 0.0
	player_b.volume_db = SILENT_DB
	_active = player_a
	_inactive = player_b

## Crossfade to the other track.
## duration = 0 -> instant swap (still beat-perfect because they're in sync)
func switch_track(duration: float = 0.6) -> void:
	if _tween:
		_tween.kill()

	if duration <= 0.0:
		_active.volume_db = SILENT_DB
		_inactive.volume_db = 0.0
	else:
		_tween = create_tween().set_parallel(true)
		_tween.tween_property(_active,   "volume_db", SILENT_DB, duration)
		_tween.tween_property(_inactive, "volume_db", 0.0,       duration)

	var tmp := _active
	_active = _inactive
	_inactive = tmp
