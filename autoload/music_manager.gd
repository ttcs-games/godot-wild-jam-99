extends Node

@onready var player_a: AudioStreamPlayer = $ChillPlayer
@onready var player_b: AudioStreamPlayer = $GamePlayer

var _active: AudioStreamPlayer
var _inactive: AudioStreamPlayer
var _tween: Tween

const SILENT_DB := -80.0
const FADE_TIME := 1.2

var _victory_stream: AudioStream = load("res://assets/sfx/victory.wav")
var _loss_stream: AudioStream = load("res://assets/sfx/gameover_40.wav")

var _sfx_player: AudioStreamPlayer
var _sfx_tween: Tween
var _sfx_token: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Start both at the exact same moment. They will stay in sync forever.
	player_a.play(0.0)
	player_b.play(0.0)
	player_a.volume_db = 0.0
	player_b.volume_db = SILENT_DB
	_active = player_a
	_inactive = player_b
	
	_sfx_player = AudioStreamPlayer.new()
	add_child(_sfx_player)

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

func play_victory() -> void:
	_play_ducked_sfx(_victory_stream, false)

func play_loss() -> void:
	await _play_ducked_sfx(_loss_stream, true)

func _play_ducked_sfx(stream: AudioStream, swtich: bool) -> void:
	if _sfx_tween:
		_sfx_tween.kill()
	if _sfx_player.playing:
		_sfx_player.stop()
	if _tween:
		_tween.kill()
	
	_sfx_player.stream = stream
	var sfx_len: float  = stream.get_length()
	var fade_dur: float = min(FADE_TIME, sfx_len * 0.5)
	var original_db: float = 0.0
	
	_sfx_tween = create_tween()
	_sfx_tween.tween_property(_active, "volume_db", SILENT_DB, fade_dur)
	
	await get_tree().create_timer(fade_dur * 0.5).timeout
	
	_sfx_player.play()
	var wait_time: float = sfx_len - fade_dur
	if wait_time > 0.0:
		await get_tree().create_timer(wait_time).timeout
	
	var tmp := _active
	_active = _inactive
	_inactive = tmp
	
	_sfx_tween = create_tween()
	_sfx_tween.tween_property(_active, "volume_db", original_db, fade_dur)
	
	await _sfx_tween.finished
