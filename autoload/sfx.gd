extends Node

const BUTTON := preload("res://assets/sfx/button_big.wav")
const HOVER := preload("res://assets/sfx/hover_over.wav")
const UPGRADE := preload("res://assets/sfx/upgrade.wav")
const SELECT := preload("res://assets/sfx/select_pop.wav")
const PLACE := preload("res://assets/sfx/placed.wav")
const ROTATE := preload("res://assets/sfx/rotate_woosh.wav")
const DRAW := preload("res://assets/sfx/draw.wav")
const ERROR := preload("res://assets/sfx/error_006.ogg")

const FAN_UP := preload("res://assets/sfx/card-fan-1.wav")
const FAN_DOWN := preload("res://assets/sfx/card-fan-2.wav")

const BREAK := preload("res://assets/sfx/lava.wav")
const RISE := preload("res://assets/sfx/rise.wav")

const POOL_SIZE := 10
var _pool: Array[AudioStreamPlayer] = []
var _next := 0

# A single AudioStream can only play one sound at a time
# So playing multiple in a rapid succession means they cut off
# Solution: create a pool of AudioStreams to use
func _ready() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)

func play(stream: AudioStream, volume_db := 0.0, pitch_scale := 1.0) -> void:
	var p := _pool[_next]
	_next = (_next + 1) % POOL_SIZE
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch_scale
	p.play()

func button() -> void:
	play(BUTTON)

func hover() -> void:
	play(HOVER)

func upgrade() -> void:
	play(UPGRADE)

func select() -> void:
	play(SELECT)

func place() -> void:
	play(PLACE)

func rotate() -> void:
	play(ROTATE)

func draw() -> void:
	play(DRAW)

func denied() -> void:
	play(ERROR)

func many_draw() -> void:
	play(FAN_UP)

func many_discard() -> void:
	play(FAN_DOWN)

func layer_break() -> void:
	play(BREAK)

func rise() -> void:
	play(RISE)
