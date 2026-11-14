# ============================================================
#  TETRA SPIRE — Tetris x Slay the Spire x Balatro
#  A complete run-based roguelike built on a full SRS Tetris core.
#
#  HOW TO RUN (Godot 4.x):
#    1. Create a new project in Godot 4 (any renderer).
#    2. Save this file as res://main.gd (drag it into the project dock).
#    3. Create a scene with a single Node2D root, attach main.gd to it,
#       and set it as the main scene (Project Settings > Run > Main Scene).
#    4. Press Play. All UI, audio and effects are generated in code.
#
#  CONTROLS:
#    Left/Right  move        Up / X  rotate CW     Z  rotate CCW
#    Down        soft drop   Space   hard drop     C / Shift  hold
#    P / Esc     pause       Mouse   menus
#
#  HOW IT PLAYS:
#    Clearing lines deals damage = CHIPS x MULT / 8 to the enemy above
#    the stack. Enemies send garbage lines on a timer; garbage that
#    crushes your stack hurts YOU. Between fights, pick your path
#    through the spire: battles, elites, shops, campfires, treasure,
#    and a boss at floor 12. Relics warp the scoring engine.
# ============================================================

extends Node2D

# ---------------- Board constants ----------------

const COLS := 10
const ROWS := 22
const HIDDEN := 2
const VISIBLE_ROWS := 20
const CELL := 30
const BOARD_X := 100.0
const BOARD_Y := 60.0

const GRAV_BASE := 0.9
const DAS_TIME := 0.15
const ARR_TIME := 0.045
const MAX_LOCK_RESETS := 15

enum State { MENU, BATTLE, REWARD, MAP, SHOP, REST, GAMEOVER, WIN }

const COL_BG := Color(0.07, 0.08, 0.11)
const COL_PANEL := Color(0.11, 0.12, 0.17)
const COL_PANEL_BORDER := Color(0.24, 0.28, 0.4)
const COL_TEXT := Color(0.92, 0.94, 0.98)
const COL_DIM := Color(0.6, 0.64, 0.72)
const COL_GOLD := Color(1.0, 0.82, 0.3)
const COL_RED := Color(1.0, 0.35, 0.35)
const COL_GREEN := Color(0.4, 1.0, 0.55)
const COL_ACCENT := Color(0.45, 0.85, 1.0)

const COLORS := [
	Color(0, 0, 0),          # 0 empty
	Color(0.2, 0.9, 1.0),    # 1 I cyan
	Color(1.0, 0.88, 0.2),   # 2 O yellow
	Color(0.75, 0.35, 1.0),  # 3 T purple
	Color(0.3, 1.0, 0.4),    # 4 S green
	Color(1.0, 0.3, 0.3),    # 5 Z red
	Color(0.3, 0.5, 1.0),    # 6 J blue
	Color(1.0, 0.6, 0.2),    # 7 L orange
	Color(0.45, 0.47, 0.52), # 8 garbage
]
const COLOR_INDEX := {"I": 1, "O": 2, "T": 3, "S": 4, "Z": 5, "J": 6, "L": 7}

# ---------------- Piece data (SRS orientations) ----------------

const PIECES := {
	"I": [
		[Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)],
		[Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2), Vector2i(2, 3)],
		[Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2)],
		[Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 3)],
	],
	"O": [
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1)],
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1)],
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1)],
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1)],
	],
	"T": [
		[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
		[Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)],
		[Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)],
		[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2)],
	],
	"S": [
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)],
		[Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2)],
		[Vector2i(1, 1), Vector2i(2, 1), Vector2i(0, 2), Vector2i(1, 2)],
		[Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2)],
	],
	"Z": [
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)],
		[Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)],
		[Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2)],
		[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2)],
	],
	"J": [
		[Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(1, 2)],
		[Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2)],
		[Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2)],
	],
	"L": [
		[Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
		[Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2)],
		[Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(0, 2)],
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2)],
	],
}

# SRS wall kicks, converted to grid coordinates (y grows downward).
const KICKS_JLSTZ := {
	"01": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, 2), Vector2i(-1, 2)],
	"10": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, -2), Vector2i(1, -2)],
	"12": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, -2), Vector2i(1, -2)],
	"21": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, 2), Vector2i(-1, 2)],
	"23": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, 2), Vector2i(1, 2)],
	"32": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, -2), Vector2i(-1, -2)],
	"30": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, -2), Vector2i(-1, -2)],
	"03": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, 2), Vector2i(1, 2)],
}
const KICKS_I := {
	"01": [Vector2i(0, 0), Vector2i(-2, 0), Vector2i(1, 0), Vector2i(-2, 1), Vector2i(1, -2)],
	"10": [Vector2i(0, 0), Vector2i(2, 0), Vector2i(-1, 0), Vector2i(2, -1), Vector2i(-1, 2)],
	"12": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(2, 0), Vector2i(-1, -2), Vector2i(2, 1)],
	"21": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-2, 0), Vector2i(1, 2), Vector2i(-2, -1)],
	"23": [Vector2i(0, 0), Vector2i(2, 0), Vector2i(-1, 0), Vector2i(2, -1), Vector2i(-1, 2)],
	"32": [Vector2i(0, 0), Vector2i(-2, 0), Vector2i(1, 0), Vector2i(-2, 1), Vector2i(1, -2)],
	"30": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-2, 0), Vector2i(1, 2), Vector2i(-2, -1)],
	"03": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(2, 0), Vector2i(-1, -2), Vector2i(2, 1)],
}

# ---------------- Relics ----------------

const RELICS := {
	"hammer": {"name": "Sledgehammer", "desc": "Tetris mult is x3 instead of x2."},
	"crown": {"name": "Combo Crown", "desc": "Combos build twice as fast: +1.0 mult per chain step."},
	"lens": {"name": "T-Spin Lens", "desc": "T-spins deal x4 mult and +10 chips."},
	"coin": {"name": "Lucky Coin", "desc": "+30% gold from battles."},
	"heart": {"name": "Iron Heart", "desc": "+10 max HP, and heal 10 now.", "hp": 10},
	"clock": {"name": "Clockwork Heart", "desc": "Enemies attack 25% slower."},
	"filter": {"name": "Garbage Filter", "desc": "Blocks the first garbage line of each battle."},
	"ram": {"name": "Battering Ram", "desc": "+15 chips on every line clear."},
	"fangs": {"name": "Vampire Fangs", "desc": "Heal 1 HP per line cleared."},
	"thorns": {"name": "Thorns", "desc": "Deal 6 damage to the enemy whenever you receive garbage."},
	"overclock": {"name": "Overclock", "desc": "Pieces fall 25% faster, but all damage +25%."},
	"midas": {"name": "Midas Touch", "desc": "Perfect clears grant +30 extra gold."},
	"wizard": {"name": "Wizard Hat", "desc": "Your first clear each battle deals x3 mult."},
	"boulder": {"name": "Boulder", "desc": "Hard drops deal 1 damage per row dropped."},
	"anvil": {"name": "Anvil", "desc": "Lock delay +50% and +5 chips per clear."},
	"battery": {"name": "Sticky Battery", "desc": "Your combo survives one non-clearing drop per battle."},
}

# ---------------- Enemies ----------------

const ENEMIES := {
	"slime": {"name": "Gel Slime", "hp": 70, "every": 11.0, "garbage": 1},
	"bats": {"name": "Bat Swarm", "hp": 55, "every": 8.5, "garbage": 1, "speed": 0.35},
	"knight": {"name": "Rust Knight", "hp": 100, "every": 12.0, "garbage": 2},
	"golem": {"name": "Stone Golem", "hp": 140, "every": 13.0, "garbage": 2, "elite": true},
	"necro": {"name": "Necromancer", "hp": 110, "every": 7.5, "garbage": 1, "speed": 0.3, "elite": true},
	"warden": {"name": "THE WARDEN", "hp": 280, "every": 8.0, "garbage": 2, "alternate": true, "boss": true, "enrage": true},
}

# ---------------- Run / battle state ----------------

var state: int = State.MENU
var paused := false
var run := {}
var grid: Array = []
var piece := {}
var piece_queue: Array = []
var hold_t := ""
var can_hold := true
var combo := 0
var battery_used := false
var first_clear_used := false
var filter_used := false
var speed_t := 0.0
var grav_t := 0.0
var lock_t := 0.0
var lock_resets := 0
var last_rotate := false
var das_dir := 0
var das_t := 0.0
var arr_t := 0.0
var flash_rows: Array = []
var flash_t := 0.0
var last_score := ""
var enemy := {}
var win_t := 0.0
var shake := 0.0

var map_options: Array = []
var reward_gold := 0
var reward_relics: Array = []
var reward_title := "VICTORY!"
var shop_offers: Array = []

var particles: Array = []
var floats: Array = []
var _buttons: Array = []
var _mouse_pos := Vector2.ZERO
var _sounds := {}

# ---------------- Lifecycle ----------------

func _ready() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))

func _process(delta: float) -> void:
	shake = maxf(shake - delta * 3.0, 0.0)
	_update_fx(delta)
	if state == State.BATTLE and not paused:
		_battle_process(delta)
	queue_redraw()

func _update_fx(delta: float) -> void:
	var keep := []
	for p in particles:
		p.t += delta
		p.p += p.v * delta
		p.v.y += 500.0 * delta
		if p.t < p.life:
			keep.append(p)
	particles = keep
	var kf := []
	for f in floats:
		f.t += delta
		f.p.y -= 45.0 * delta
		if f.t < f.life:
			kf.append(f)
	floats = kf

# ---------------- Input ----------------

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse_pos = event.position
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for b in _buttons:
			if (b.rect as Rect2).has_point(event.position):
				_sfx("click")
				b.cb.call()
				return
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.keycode
		if state == State.MENU and (k == KEY_ENTER or k == KEY_SPACE):
			_new_run()
			return
		if k == KEY_ESCAPE or k == KEY_P:
			if state == State.BATTLE:
				paused = not paused
				return
		if state == State.BATTLE and not paused and win_t <= 0.0:
			match k:
				KEY_LEFT:
					das_dir = -1
					das_t = 0.0
					arr_t = 0.0
					_try_move(-1)
				KEY_RIGHT:
					das_dir = 1
					das_t = 0.0
					arr_t = 0.0
					_try_move(1)
				KEY_UP, KEY_X:
					_try_rotate(1)
				KEY_Z:
					_try_rotate(-1)
				KEY_SPACE:
					_hard_drop()
				KEY_C, KEY_SHIFT:
					_do_hold()

# ---------------- Run flow ----------------

func _new_run() -> void:
	run = {"hp": 60, "max_hp": 60, "gold": 30, "floor_num": 1, "relics": [], "base_chips": 0}
	particles = []
	floats = []
	map_options = _gen_map_options()
	state = State.MAP

func _gen_map_options() -> Array:
	var f: int = run.floor_num
	var opts := ["battle"]
	if f >= 4 and f <= 10 and randf() < 0.6:
		opts.append("elite")
	if f == 4 or f == 8:
		opts.append("shop")
	if f == 5 or f == 9:
		opts.append("rest")
	if randf() < 0.35:
		opts.append("treasure")
	var extra := ["battle", "battle", "treasure", "rest", "shop"]
	while opts.size() < 3:
		var r: String = extra[randi_range(0, extra.size() - 1)]
		if not opts.has(r):
			opts.append(r)
	opts = opts.slice(0, 3)
	opts.shuffle()
	return opts

func _start_room(kind: String) -> void:
	match kind:
		"battle":
			_start_battle(false)
		"elite":
			_start_battle(true)
		"treasure":
			var g := 25
			if has_relic("coin"):
				g = ceili(g * 1.3)
			run.gold += g
			reward_gold = g
			reward_relics = _roll_relics(1)
			reward_title = "TREASURE!"
			state = State.REWARD
		"shop":
			shop_offers = _roll_shop()
			state = State.SHOP
		"rest":
			state = State.REST

func _advance_floor() -> void:
	run.floor_num += 1
	if run.floor_num >= 12:
		_start_battle(false)
	else:
		map_options = _gen_map_options()
		state = State.MAP

func _roll_relics(n: int) -> Array:
	var pool: Array = []
	for id in RELICS:
		if not run.relics.has(id):
			pool.append(id)
	pool.shuffle()
	return pool.slice(0, mini(n, pool.size()))

func _roll_shop() -> Array:
	var ids := _roll_relics(3)
	var offers := []
	for id in ids:
		offers.append({"id": id, "price": 45 + run.floor_num * 3 + randi_range(-10, 10), "sold": false})
	return offers

func _add_relic(id: String) -> void:
	run.relics.append(id)
	var d: Dictionary = RELICS[id]
	if d.has("hp"):
		run.max_hp += int(d.hp)
		run.hp += int(d.hp)
	_sfx("coin")

func _pick_reward_relic(id: String) -> void:
	_add_relic(id)
	_advance_floor()

func _buy_shop(i: int) -> void:
	var offer: Dictionary = shop_offers[i]
	if run.gold >= int(offer.price):
		run.gold -= int(offer.price)
		offer.sold = true
		_add_relic(offer.id)
		_sfx("heal")

func _buy_heal() -> void:
	if run.gold >= 30 and run.hp < run.max_hp:
		run.gold -= 30
		run.hp = mini(int(run.max_hp), int(run.hp) + 15)
		_sfx("heal")

func _rest_heal() -> void:
	run.hp = mini(int(run.max_hp), int(run.hp) + ceili(run.max_hp * 0.35))
	_sfx("heal")
	_advance_floor()

func _rest_forge() -> void:
	run.base_chips += 8
	_sfx("coin")
	_advance_floor()

func has_relic(id: String) -> bool:
	return run.relics.has(id)

# ---------------- Battle setup ----------------

func _start_battle(elite: bool) -> void:
	grid = []
	for r in ROWS:
		grid.append(_empty_row())
	piece_queue = []
	hold_t = ""
	can_hold = true
	combo = 0
	battery_used = false
	first_clear_used = false
	filter_used = false
	speed_t = 0.0
	grav_t = 0.0
	lock_t = 0.0
	lock_resets = 0
	last_rotate = false
	das_dir = 0
	flash_rows = []
	flash_t = 0.0
	last_score = ""
	win_t = 0.0
	paused = false
	var eid: String
	if run.floor_num >= 12:
		eid = "warden"
	elif elite:
		eid = ["golem", "necro"][randi_range(0, 1)]
	else:
		eid = _pick_normal_enemy()
	var def: Dictionary = ENEMIES[eid]
	var hp := int(ceili(def.hp * (1.0 + 0.06 * (run.floor_num - 1))))
	enemy = {"def": def, "hp": hp, "max": hp, "t": 0.0, "alt": false}
	_spawn()
	state = State.BATTLE

func _pick_normal_enemy() -> String:
	var pool := ["slime", "bats"]
	if run.floor_num >= 3:
		pool.append("knight")
	if run.floor_num >= 8:
		pool.append("necro")
	return pool[randi_range(0, pool.size() - 1)]

# ---------------- Core tetris logic ----------------

func _empty_row() -> Array:
	var row := []
	row.resize(COLS)
	row.fill(0)
	return row

func _refill_bag() -> void:
	var bag := ["I", "O", "T", "S", "Z", "J", "L"]
	bag.shuffle()
	for t in bag:
		piece_queue.append(t)

func _spawn() -> void:
	while piece_queue.size() < 8:
		_refill_bag()
	var t: String = piece_queue.pop_front()
	piece = {"t": t, "r": 0, "x": 3, "y": 0}
	grav_t = 0.0
	lock_t = 0.0
	lock_resets = 0
	last_rotate = false
	if _collides(t, 3, 0, 0):
		_player_damage(8, "CRUSHED")
		for r in range(0, 6):
			for c in COLS:
				grid[r][c] = 0
		while _collides(t, piece.x, piece.y, 0) and piece.y > -6:
			piece.y -= 1

func _collides(t: String, px: int, py: int, rot: int) -> bool:
	for off in PIECES[t][rot]:
		var x: int = px + off.x
		var y: int = py + off.y
		if x < 0 or x >= COLS or y >= ROWS:
			return true
		if y >= 0 and grid[y][x] != 0:
			return true
	return false

func _piece_cells(t: String, rot: int, px: int, py: int) -> Array:
	var out := []
	for off in PIECES[t][rot]:
		out.append(Vector2i(px + off.x, py + off.y))
	return out

func _kicks(t: String, from_r: int, to_r: int) -> Array:
	if t == "O":
		return [Vector2i(0, 0)]
	var key := str(from_r) + str(to_r)
	if t == "I":
		return KICKS_I[key]
	return KICKS_JLSTZ[key]

func _reset_lock() -> void:
	if lock_resets < MAX_LOCK_RESETS:
		lock_t = 0.0
		lock_resets += 1

func _try_move(dx: int) -> void:
	if state != State.BATTLE or paused or flash_t > 0.0 or win_t > 0.0:
		return
	if not _collides(piece.t, piece.x + dx, piece.y, piece.r):
		piece.x += dx
		last_rotate = false
		_reset_lock()
		_sfx("move")

func _try_rotate(dr: int) -> void:
	if state != State.BATTLE or paused or flash_t > 0.0 or win_t > 0.0:
		return
	var nr: int = (piece.r + dr + 4) % 4
	for k in _kicks(piece.t, piece.r, nr):
		if not _collides(piece.t, piece.x + k.x, piece.y + k.y, nr):
			piece.r = nr
			piece.x += k.x
			piece.y += k.y
			last_rotate = true
			_reset_lock()
			_sfx("rotate")
			return

func _do_hold() -> void:
	if state != State.BATTLE or paused or flash_t > 0.0 or win_t > 0.0 or not can_hold:
		return
	can_hold = false
	var cur: String = piece.t
	_sfx("rotate")
	if hold_t == "":
		hold_t = cur
		_spawn()
	else:
		var h: String = hold_t
		hold_t = cur
		piece = {"t": h, "r": 0, "x": 3, "y": 0}
		grav_t = 0.0
		lock_t = 0.0
		lock_resets = 0
		last_rotate = false
		if _collides(h, 3, 0, 0):
			_player_damage(8, "CRUSHED")
			for r in range(0, 6):
				for c in COLS:
					grid[r][c] = 0
			while _collides(h, piece.x, piece.y, 0) and piece.y > -6:
				piece.y -= 1

func _hard_drop() -> void:
	if state != State.BATTLE or paused or flash_t > 0.0 or win_t > 0.0:
		return
	var dist := 0
	while not _collides(piece.t, piece.x, piece.y + 1, piece.r):
		piece.y += 1
		dist += 1
	if has_relic("boulder") and dist > 0:
		_deal_damage(dist, false)
	_lock_piece()

func _lock_piece() -> void:
	var t: String = piece.t
	var tspin := false
	if t == "T" and last_rotate:
		tspin = _check_tspin()
	var all_hidden := true
	for c in _piece_cells(t, piece.r, piece.x, piece.y):
		if c.y >= HIDDEN:
			all_hidden = false
		if c.y >= 0:
			grid[c.y][c.x] = COLOR_INDEX[t]
	_sfx("lock")
	can_hold = true
	if all_hidden:
		_player_damage(5, "TOP OUT")
		for r in HIDDEN:
			for c in COLS:
				grid[r][c] = 0
		_spawn()
		return
	var full := []
	for r in ROWS:
		var rowfull := true
		for c in COLS:
			if grid[r][c] == 0:
				rowfull = false
				break
		if rowfull:
			full.append(r)
	if full.is_empty():
		if combo > 0:
			if has_relic("battery") and not battery_used:
				battery_used = true
			else:
				combo = 0
		last_rotate = false
		_spawn()
		return
	for r in full:
		for c in COLS:
			grid[r][c] = 0
	var newgrid := []
	for r in ROWS:
		if not full.has(r):
			newgrid.append(grid[r])
	while newgrid.size() < ROWS:
		newgrid.insert(0, _empty_row())
	grid = newgrid
	flash_rows = full
	flash_t = 0.22
	combo += 1
	battery_used = false
	_spawn_particles(full)
	_score_clear(full.size(), tspin)
	last_rotate = false
	_spawn()

func _check_tspin() -> bool:
	var corners := [Vector2i(piece.x, piece.y), Vector2i(piece.x + 2, piece.y), Vector2i(piece.x, piece.y + 2), Vector2i(piece.x + 2, piece.y + 2)]
	var filled := 0
	for cn in corners:
		if cn.x < 0 or cn.x >= COLS or cn.y >= ROWS:
			filled += 1
		elif cn.y >= 0 and grid[cn.y][cn.x] != 0:
			filled += 1
	return filled >= 3

# ---------------- Scoring (Balatro style: chips x mult) ----------------

func _score_clear(n: int, tspin: bool) -> void:
	var chips: int = [0, 10, 30, 60, 120][n] + int(run.base_chips)
	if has_relic("ram"):
		chips += 15
	if tspin and has_relic("lens"):
		chips += 10
	if has_relic("anvil"):
		chips += 5
	var mult := 1.0
	var step := 1.0 if has_relic("crown") else 0.5
	mult += step * (combo - 1)
	if n == 4:
		mult *= 3.0 if has_relic("hammer") else 2.0
	if tspin:
		mult *= 4.0 if has_relic("lens") else 3.0
	if has_relic("wizard") and not first_clear_used:
		mult *= 3.0
		first_clear_used = true
	var perfect := true
	for r in range(HIDDEN, ROWS):
		for c in COLS:
			if grid[r][c] != 0:
				perfect = false
	if perfect:
		mult *= 2.0
		var g := 30 if has_relic("midas") else 15
		run.gold += g
		_float_text(Vector2(BOARD_X + COLS * CELL * 0.5, BOARD_Y + 200.0), "PERFECT! +%dg" % g, COL_GOLD, true)
	var dmg := ceili(chips * mult / 8.0)
	if has_relic("overclock"):
		dmg = ceili(dmg * 1.25)
	if has_relic("fangs"):
		_heal_player(n)
	last_score = "CHIPS %d  x  MULT %.1f  =  %d DMG" % [chips, mult, dmg]
	if n == 4 or tspin:
		_sfx("tetris")
	else:
		_sfx("clear")
	_deal_damage(dmg, n >= 4 or tspin)

# ---------------- Damage / enemy AI ----------------

func _deal_damage(d: int, big: bool) -> void:
	if d <= 0 or win_t > 0.0:
		return
	enemy.hp -= d
	shake = maxf(shake, 0.6 if big else 0.3)
	var col := Color(1.0, 0.9, 0.3) if big else Color(1.0, 1.0, 1.0)
	_float_text(Vector2(890.0 + randf_range(-60, 60), 150.0), str(d), col, big)
	if enemy.hp <= 0:
		enemy.hp = 0
		win_t = 0.9
		_sfx("win")

func _enemy_interval() -> float:
	var iv: float = enemy.def.every
	if has_relic("clock"):
		iv *= 1.25
	if enemy.def.has("enrage") and enemy.hp < enemy.max * 0.4:
		iv *= 0.6
	return iv

func _enemy_intent() -> String:
	var def: Dictionary = enemy.def
	if def.has("alternate"):
		if enemy.alt:
			return "Haste: pieces will fall faster!"
		return "%d garbage line%s" % [def.garbage, "" if int(def.garbage) == 1 else "s"]
	if float(def.get("speed", 0.0)) > 0.0:
		return "Garbage... or HASTE!"
	return "%d garbage line%s" % [def.garbage, "" if int(def.garbage) == 1 else "s"]

func _enemy_attack() -> void:
	var def: Dictionary = enemy.def
	var use_speed := false
	if def.has("alternate"):
		use_speed = enemy.alt
		enemy.alt = not enemy.alt
	elif float(def.get("speed", 0.0)) > 0.0 and randf() < float(def.speed):
		use_speed = true
	if use_speed:
		speed_t = 9.0
		_float_text(Vector2(BOARD_X + COLS * CELL * 0.5, BOARD_Y + 100.0), "HASTE!", COL_RED, true)
		_sfx("garbage")
	else:
		var g: int = int(def.garbage)
		if has_relic("filter") and not filter_used:
			filter_used = true
			g -= 1
			_float_text(Vector2(BOARD_X + COLS * CELL * 0.5, BOARD_Y + 100.0), "FILTERED!", COL_ACCENT, true)
		if g > 0:
			_add_garbage(g)
		if has_relic("thorns"):
			_deal_damage(6, false)

func _add_garbage(g: int) -> void:
	var lost := 0
	for r in range(0, mini(g, ROWS)):
		for c in COLS:
			if grid[r][c] != 0:
				lost += 1
	_sfx("garbage")
	var hole := randi_range(0, COLS - 1)
	for i in g:
		for r in range(ROWS - 1):
			grid[r] = grid[r + 1]
		var row := _empty_row()
		for c in COLS:
			if c != hole:
				row[c] = 8
		grid[ROWS - 1] = row
	if lost > 0:
		_player_damage(lost * 3, "CRUSHED")
	for r in HIDDEN:
		for c in COLS:
			grid[r][c] = 0
	while _collides(piece.t, piece.x, piece.y, piece.r) and piece.y > -6:
		piece.y -= 1

func _player_damage(d: int, label: String) -> void:
	run.hp -= int(d)
	shake = 1.0
	_sfx("hurt")
	_float_text(Vector2(BOARD_X + COLS * CELL * 0.5, BOARD_Y + 300.0), label, COL_RED, true)
	if run.hp <= 0:
		run.hp = 0
		state = State.GAMEOVER
		_sfx("die")

func _heal_player(n: int) -> void:
	if run.hp < run.max_hp:
		run.hp = mini(int(run.max_hp), int(run.hp) + n)

func _win_battle() -> void:
	var g: int
	if run.floor_num >= 12:
		g = 100
	elif enemy.def.has("elite"):
		g = 50 + run.floor_num * 2
	else:
		g = 20 + run.floor_num * 2 + randi_range(0, 8)
	if has_relic("coin"):
		g = ceili(g * 1.3)
	run.gold += g
	reward_gold = g
	reward_relics = _roll_relics(3)
	if run.floor_num >= 12:
		state = State.WIN
		return
	reward_title = "VICTORY!"
	state = State.REWARD

# ---------------- Battle simulation ----------------

func _battle_process(delta: float) -> void:
	if win_t > 0.0:
		win_t -= delta
		if win_t <= 0.0:
			_win_battle()
		return
	if flash_t > 0.0:
		flash_t -= delta
	# Enemy timer
	enemy.t += delta
	if enemy.t >= _enemy_interval():
		enemy.t = 0.0
		_enemy_attack()
	if speed_t > 0.0:
		speed_t -= delta
	if flash_t > 0.0:
		return
	# Gravity
	var gmul := 1.0
	if speed_t > 0.0:
		gmul *= 0.55
	if has_relic("overclock"):
		gmul *= 0.75
	if Input.is_key_pressed(KEY_DOWN):
		gmul *= 0.05
	var interval := GRAV_BASE * gmul
	grav_t += delta
	while grav_t >= interval:
		grav_t -= interval
		if not _collides(piece.t, piece.x, piece.y + 1, piece.r):
			piece.y += 1
			last_rotate = false
		else:
			break
	# Lock delay
	if _collides(piece.t, piece.x, piece.y + 1, piece.r):
		lock_t += delta
		var max_lock := 0.75 if has_relic("anvil") else 0.5
		if lock_t >= max_lock:
			_lock_piece()
	else:
		lock_t = 0.0
	# DAS auto-repeat
	if das_dir != 0:
		var key := KEY_LEFT if das_dir < 0 else KEY_RIGHT
		if Input.is_key_pressed(key):
			das_t += delta
			if das_t >= DAS_TIME:
				arr_t += delta
				while arr_t >= ARR_TIME:
					arr_t -= ARR_TIME
					_try_move(das_dir)
		else:
			das_dir = 0

# ---------------- Effects ----------------

func _spawn_particles(rows: Array) -> void:
	for r in rows:
		for i in 12:
			particles.append({
				"p": Vector2(BOARD_X + randf_range(0, COLS * CELL), BOARD_Y + (r - HIDDEN) * CELL),
				"v": Vector2(randf_range(-140, 140), randf_range(-240, -40)),
				"col": Color(1.0, randf_range(0.6, 1.0), randf_range(0.2, 0.6)),
				"t": 0.0,
				"life": randf_range(0.4, 0.8),
			})

func _float_text(pos: Vector2, txt: String, col: Color, big: bool = false) -> void:
	floats.append({"p": pos, "txt": txt, "col": col, "t": 0.0, "life": 1.0, "big": big})

# ---------------- Audio ----------------

func _make_sfx(freq: float, dur: float, vol: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / float(rate)
		var env := 1.0 - float(i) / float(n)
		var s := sin(TAU * freq * t) * env * vol
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	return wav

func _sfx(sname: String) -> void:
	if not _sounds.has(sname):
		var spec = {
			"move": [260.0, 0.04, 0.10],
			"rotate": [380.0, 0.05, 0.12],
			"lock": [160.0, 0.06, 0.15],
			"clear": [520.0, 0.12, 0.20],
			"tetris": [700.0, 0.18, 0.25],
			"hurt": [90.0, 0.25, 0.30],
			"garbage": [110.0, 0.15, 0.25],
			"coin": [900.0, 0.08, 0.15],
			"click": [440.0, 0.04, 0.12],
			"heal": [600.0, 0.15, 0.15],
			"die": [60.0, 0.6, 0.30],
			"win": [800.0, 0.4, 0.22],
		}[sname]
		_sounds[sname] = _make_sfx(spec[0], spec[1], spec[2])
	var p := AudioStreamPlayer.new()
	add_child(p)
	p.stream = _sounds[sname]
	p.play()
	p.finished.connect(p.queue_free)

# ---------------- Drawing helpers ----------------

func _font() -> Font:
	return ThemeDB.fallback_font

func _panel(rect: Rect2) -> void:
	draw_rect(rect, COL_PANEL)
	draw_rect(rect, COL_PANEL_BORDER, false, 2.0)

func _text(pos: Vector2, s: String, size: int, col: Color) -> void:
	draw_string(_font(), pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

func _text_c(x: float, y: float, w: float, s: String, size: int, col: Color) -> void:
	draw_string(_font(), Vector2(x, y), s, HORIZONTAL_ALIGNMENT_CENTER, w, size, col)

func _bar(rect: Rect2, frac: float, col: Color) -> void:
	draw_rect(rect, Color(0.05, 0.06, 0.09))
	draw_rect(Rect2(rect.position, Vector2(rect.size.x * clampf(frac, 0.0, 1.0), rect.size.y)), col)
	draw_rect(rect, COL_PANEL_BORDER, false, 2.0)

func _cell(pos: Vector2, size: float, col: Color) -> void:
	draw_rect(Rect2(pos, Vector2(size, size)), col)
	draw_rect(Rect2(pos, Vector2(size, size)), col.lightened(0.4), false, 2.0)
	draw_rect(Rect2(pos + Vector2(3, 3), Vector2(size - 6, size - 6)), col.darkened(0.12))

func _button(rect: Rect2, label: String, cb: Callable, sub: String = "", price: int = -1) -> void:
	var hov: bool = rect.has_point(_mouse_pos)
	draw_rect(rect, Color(0.18, 0.22, 0.32) if hov else Color(0.13, 0.16, 0.23))
	draw_rect(rect, COL_ACCENT if hov else COL_PANEL_BORDER, false, 2.0)
	draw_string(_font(), rect.position + Vector2(16, 30), label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 110, 22, COL_TEXT)
	if sub != "":
		_draw_wrapped(sub, rect.position + Vector2(16, 54), rect.size.x - 32, 15, COL_DIM)
	if price >= 0:
		var afford = run.gold >= price
		draw_string(_font(), Vector2(rect.end.x - 100, rect.position.y + 30), "%dg" % price, HORIZONTAL_ALIGNMENT_RIGHT, 84, 22, COL_GOLD if afford else COL_DIM)
	_buttons.append({"rect": rect, "cb": cb})

func _draw_wrapped(s: String, pos: Vector2, width: float, fsize: int, col: Color) -> void:
	var words := s.split(" ")
	var line := ""
	var y := 0.0
	for w in words:
		var test := (line + " " + w).strip_edges()
		if line != "" and _font().get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x > width:
			draw_string(_font(), pos + Vector2(0, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, col)
			y += fsize + 4
			line = w
		else:
			line = test
	if line != "":
		draw_string(_font(), pos + Vector2(0, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, col)

func _relics_string() -> String:
	if run.relics.is_empty():
		return "(no relics yet)"
	var names := []
	for id in run.relics:
		names.append(String(RELICS[id].name))
	return "  ".join(names)

func _draw_mini_piece(t: String, box_pos: Vector2, box_size: Vector2, mcell: float) -> void:
	var cells: Array = PIECES[t][0]
	var minv := Vector2i(99, 99)
	var maxv := Vector2i(-99, -99)
	for c in cells:
		minv.x = mini(minv.x, c.x)
		minv.y = mini(minv.y, c.y)
		maxv.x = maxi(maxv.x, c.x)
		maxv.y = maxi(maxv.y, c.y)
	var w := (maxv.x - minv.x + 1) * mcell
	var h := (maxv.y - minv.y + 1) * mcell
	var origin := box_pos + Vector2((box_size.x - w) * 0.5, (box_size.y - h) * 0.5)
	for c in cells:
		_cell(origin + Vector2((c.x - minv.x) * mcell, (c.y - minv.y) * mcell), mcell, COLORS[COLOR_INDEX[t]])

func _draw_fx() -> void:
	for p in particles:
		var a: float = 1.0 - p.t / p.life
		draw_rect(Rect2(p.p, Vector2(5, 5)), Color(p.col.r, p.col.g, p.col.b, a))
	for f in floats:
		var a: float = 1.0 - f.t / f.life
		var sz := 30 if f.big else 20
		var w := 400.0
		draw_string(_font(), f.p + Vector2(-w * 0.5, 0), f.txt, HORIZONTAL_ALIGNMENT_CENTER, w, sz, Color(f.col.r, f.col.g, f.col.b, a))

# ---------------- Draw: battle ----------------

func _draw_battle() -> void:
	var off := Vector2.ZERO
	if shake > 0.0:
		off = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake * 6.0
	# Board panel
	var brect := Rect2(BOARD_X - 10 + off.x, BOARD_Y - 10 + off.y, COLS * CELL + 20, VISIBLE_ROWS * CELL + 20)
	_panel(brect)
	# Grid lines
	for c in range(COLS + 1):
		draw_line(Vector2(BOARD_X + c * CELL + off.x, BOARD_Y + off.y), Vector2(BOARD_X + c * CELL + off.x, BOARD_Y + VISIBLE_ROWS * CELL + off.y), Color(1, 1, 1, 0.04))
	for r in range(VISIBLE_ROWS + 1):
		draw_line(Vector2(BOARD_X + off.x, BOARD_Y + r * CELL + off.y), Vector2(BOARD_X + COLS * CELL + off.x, BOARD_Y + r * CELL + off.y), Color(1, 1, 1, 0.04))
	# Stack + garbage
	for r in range(HIDDEN, ROWS):
		for c in COLS:
			if grid[r][c] != 0:
				_cell(Vector2(BOARD_X + c * CELL + off.x, BOARD_Y + (r - HIDDEN) * CELL + off.y), CELL, COLORS[grid[r][c]])
	# Ghost piece
	if not piece.is_empty():
		var gy: int = piece.y
		while not _collides(piece.t, piece.x, gy + 1, piece.r):
			gy += 1
		var gcol: Color = COLORS[COLOR_INDEX[piece.t]]
		gcol.a = 0.22
		for cn in _piece_cells(piece.t, piece.r, piece.x, gy):
			if cn.y >= HIDDEN:
				draw_rect(Rect2(Vector2(BOARD_X + cn.x * CELL + off.x, BOARD_Y + (cn.y - HIDDEN) * CELL + off.y), Vector2(CELL, CELL)), gcol)
		# Active piece
		for cn in _piece_cells(piece.t, piece.r, piece.x, piece.y):
			if cn.y >= HIDDEN:
				_cell(Vector2(BOARD_X + cn.x * CELL + off.x, BOARD_Y + (cn.y - HIDDEN) * CELL + off.y), CELL, COLORS[COLOR_INDEX[piece.t]])
	# Clear flash
	if flash_t > 0.0:
		var a := flash_t / 0.22
		for r in flash_rows:
			draw_rect(Rect2(BOARD_X + off.x, BOARD_Y + (r - HIDDEN) * CELL + off.y, COLS * CELL, CELL), Color(1, 1, 1, a * 0.85))
	# Hold box
	_panel(Rect2(20, 80, 100, 66))
	_text(Vector2(28, 74), "HOLD [C]", 14, COL_DIM)
	if hold_t != "":
		_draw_mini_piece(hold_t, Vector2(24, 88), Vector2(92, 52), 13)
	# Next queue
	_text(Vector2(BOARD_X + COLS * CELL + 34, 74), "NEXT", 16, COL_DIM)
	for i in mini(5, piece_queue.size()):
		var qy := 84.0 + i * 66.0
		_panel(Rect2(BOARD_X + COLS * CELL + 30, qy, 100, 60))
		_draw_mini_piece(piece_queue[i], Vector2(BOARD_X + COLS * CELL + 34, qy + 4), Vector2(92, 52), 13)
	# Combo under board
	if combo > 1:
		_text(Vector2(BOARD_X, BOARD_Y + VISIBLE_ROWS * CELL + 28), "COMBO x%d" % combo, 22, COL_ACCENT)
	if speed_t > 0.0:
		_text(Vector2(BOARD_X + 180, BOARD_Y + VISIBLE_ROWS * CELL + 28), "HURRIED!", 22, COL_RED)
	# Right panel: enemy
	_text(Vector2(560, 90), "FLOOR %d / 12" % run.floor_num, 16, COL_DIM)
	var ename: String = enemy.def.name
	var ecol := COL_TEXT
	if enemy.def.has("boss"):
		ecol = COL_RED if enemy.hp < enemy.max * 0.4 else COL_GOLD
	elif enemy.def.has("elite"):
		ecol = COL_ACCENT
	_text(Vector2(560, 130), ename, 30, ecol)
	if enemy.def.has("boss"):
		_text(Vector2(560 + 320, 130), "BOSS", 18, COL_RED)
	elif enemy.def.has("elite"):
		_text(Vector2(560 + 260, 130), "ELITE", 18, COL_ACCENT)
	_bar(Rect2(560, 145, 680, 26), float(enemy.hp) / float(enemy.max), COL_RED if enemy.def.has("boss") else Color(0.9, 0.4, 0.45))
	_text_c(560, 165, 680, "%d / %d" % [enemy.hp, enemy.max], 16, COL_TEXT)
	var iv := _enemy_interval()
	var remain: float = maxf(iv - enemy.t, 0.0)
	_text(Vector2(560, 205), "Next attack in %.1fs" % remain, 20, COL_RED if remain < 2.0 else COL_DIM)
	_text(Vector2(560, 232), _enemy_intent(), 17, Color(1.0, 0.6, 0.4))
	# Last clear score
	if last_score != "":
		_text(Vector2(560, 280), last_score, 22, COL_GOLD)
	_text(Vector2(560, 312), "Damage = CHIPS x MULT / 8", 14, COL_DIM)
	# Relics
	_text(Vector2(560, 352), "RELICS", 15, COL_DIM)
	_draw_wrapped(_relics_string(), Vector2(560, 372), 660, 15, COL_TEXT)
	# Player
	_text(Vector2(560, 600), "YOU", 18, COL_TEXT)
	_bar(Rect2(620, 585, 420, 22), float(run.hp) / float(run.max_hp), COL_GREEN)
	_text_c(620, 601, 420, "%d / %d HP" % [run.hp, run.max_hp], 14, COL_TEXT)
	_text(Vector2(560, 640), "%dg" % run.gold, 20, COL_GOLD)
	_text(Vector2(650, 640), "Forge bonus: +%d chips" % int(run.base_chips), 15, COL_DIM)
	# Controls hint
	_text(Vector2(BOARD_X, 700), "Arrows move  Up/X rotate  Z ccw  Down soft drop  Space hard drop  C hold  P pause", 13, COL_DIM)
	# Victory banner
	if win_t > 0.0:
		_text_c(560, 420, 680, "VICTORY!", 56, COL_GOLD)
	# Pause overlay
	if paused:
		draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.65))
		_text_c(340, 300, 600, "PAUSED", 52, COL_TEXT)
		_button(Rect2(490, 340, 300, 56), "Resume", func() -> void: paused = false)
		_button(Rect2(490, 410, 300, 56), "Abandon Run", func() -> void: state = State.MENU)

# ---------------- Draw: map ----------------

func _room_info(kind: String) -> Array:
	match kind:
		"battle":
			return ["BATTLE", "A normal foe. Clear lines to slay it. Reward: gold and a relic."]
		"elite":
			return ["ELITE", "A tougher foe with nastier attacks. Rich rewards await."]
		"shop":
			return ["SHOP", "Spend gold on relics and healing."]
		"rest":
			return ["CAMPFIRE", "Heal 35% of your max HP, or forge your chips permanently."]
		"treasure":
			return ["TREASURE", "A free relic and a pile of gold."]
	return ["???", ""]

func _draw_map() -> void:
	_text_c(340, 120, 600, "THE SPIRE", 48, COL_TEXT)
	_text_c(340, 155, 600, "Floor %d of 12 — choose your path" % run.floor_num, 20, COL_DIM)
	for i in map_options.size():
		var info := _room_info(map_options[i])
		var rect := Rect2(140.0 + i * 350.0, 230.0, 320.0, 200.0)
		var kind: String = map_options[i]
		var col := COL_TEXT
		if kind == "elite":
			col = COL_ACCENT
		elif kind == "treasure":
			col = COL_GOLD
		draw_rect(rect, Color(0.13, 0.16, 0.23))
		draw_rect(rect, col, false, 2.0)
		draw_string(_font(), rect.position + Vector2(20, 46), info[0], HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 40, 28, col)
		_draw_wrapped(info[1], rect.position + Vector2(20, 80), rect.size.x - 40, 16, COL_DIM)
		var k := kind
		_buttons.append({"rect": rect, "cb": func() -> void: _start_room(k)})
	# Run HUD
	_draw_run_hud()

func _draw_run_hud() -> void:
	_panel(Rect2(140, 500, 1000, 150))
	_bar(Rect2(170, 525, 400, 24), float(run.hp) / float(run.max_hp), COL_GREEN)
	_text_c(170, 542, 400, "%d / %d HP" % [run.hp, run.max_hp], 15, COL_TEXT)
	_text(Vector2(620, 545), "%d gold" % run.gold, 22, COL_GOLD)
	_text(Vector2(780, 545), "Forge: +%d chips" % int(run.base_chips), 18, COL_ACCENT)
	_text(Vector2(170, 590), "RELICS", 14, COL_DIM)
	_draw_wrapped(_relics_string(), Vector2(240, 590), 880, 16, COL_TEXT)
	_text(Vector2(170, 630), "Clear lines to deal damage: CHIPS x MULT / 8. Tetrises and T-spins multiply!", 15, COL_DIM)

# ---------------- Draw: reward ----------------

func _draw_reward() -> void:
	_text_c(340, 110, 600, reward_title, 48, COL_GOLD)
	_text_c(340, 150, 600, "+%d gold" % reward_gold, 26, COL_GOLD)
	_text_c(340, 185, 600, "Choose a relic:", 20, COL_TEXT)
	for i in reward_relics.size():
		var id: String = reward_relics[i]
		var d: Dictionary = RELICS[id]
		var rect := Rect2(140.0 + i * 350.0, 230.0, 320.0, 170.0)
		draw_rect(rect, Color(0.13, 0.16, 0.23))
		draw_rect(rect, COL_GOLD, false, 2.0)
		draw_string(_font(), rect.position + Vector2(20, 42), d.name, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 40, 24, COL_GOLD)
		_draw_wrapped(d.desc, rect.position + Vector2(20, 74), rect.size.x - 40, 16, COL_TEXT)
		var rid := id
		_buttons.append({"rect": rect, "cb": func() -> void: _pick_reward_relic(rid)})
	_button(Rect2(490, 440, 300, 56), "Skip", func() -> void: _advance_floor())
	_draw_run_hud()

# ---------------- Draw: shop ----------------

func _draw_shop() -> void:
	_text_c(340, 110, 600, "SHOP", 48, COL_GOLD)
	_text_c(340, 150, 600, "You carry %d gold" % run.gold, 22, COL_GOLD)
	for i in shop_offers.size():
		var offer: Dictionary = shop_offers[i]
		var d: Dictionary = RELICS[offer.id]
		var rect := Rect2(140.0 + i * 350.0, 210.0, 320.0, 190.0)
		draw_rect(rect, Color(0.13, 0.16, 0.23))
		draw_rect(rect, COL_PANEL_BORDER, false, 2.0)
		draw_string(_font(), rect.position + Vector2(20, 42), d.name, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 110, 24, COL_TEXT)
		draw_string(_font(), Vector2(rect.end.x - 110, rect.position.y + 42), "%dg" % int(offer.price), HORIZONTAL_ALIGNMENT_RIGHT, 90, 22, COL_GOLD)
		_draw_wrapped(d.desc, rect.position + Vector2(20, 74), rect.size.x - 40, 16, COL_DIM)
		if not offer.sold:
			var idx := i
			_buttons.append({"rect": rect, "cb": func() -> void: _buy_shop(idx)})
		else:
			draw_string(_font(), rect.position + Vector2(20, 160), "SOLD", HORIZONTAL_ALIGNMENT_LEFT, 200, 22, COL_DIM)
	# Heal offer
	var hrect := Rect2(140, 430, 480, 70)
	var hafford = run.gold >= 30 and run.hp < run.max_hp
	draw_rect(hrect, Color(0.13, 0.16, 0.23))
	draw_rect(hrect, COL_GREEN if hafford else COL_PANEL_BORDER, false, 2.0)
	draw_string(_font(), hrect.position + Vector2(20, 32), "Heal 15 HP", HORIZONTAL_ALIGNMENT_LEFT, 260, 22, COL_GREEN if hafford else COL_DIM)
	draw_string(_font(), Vector2(hrect.end.x - 110, hrect.position.y + 32), "30g", HORIZONTAL_ALIGNMENT_RIGHT, 90, 22, COL_GOLD if hafford else COL_DIM)
	_draw_wrapped("Patch yourself up between floors.", hrect.position + Vector2(20, 56), 400, 14, COL_DIM)
	if hafford:
		_buttons.append({"rect": hrect, "cb": func() -> void: _buy_heal()})
	_button(Rect2(700, 430, 300, 70), "Leave Shop", func() -> void: _advance_floor())
	_draw_run_hud()

# ---------------- Draw: rest ----------------

func _draw_rest() -> void:
	_text_c(340, 130, 600, "CAMPFIRE", 48, Color(1.0, 0.7, 0.4))
	_text_c(340, 170, 600, "The fire crackles. What will you do?", 20, COL_DIM)
	_button(Rect2(240, 230, 360, 90), "Rest", func() -> void: _rest_heal(), "Heal 35% of your max HP.")
	_button(Rect2(680, 230, 360, 90), "Forge", func() -> void: _rest_forge(), "Permanently gain +8 chips on every clear.")
	_draw_run_hud()

# ---------------- Draw: menu / end screens ----------------

func _draw_menu() -> void:
	_text_c(140, 200, 1000, "TETRA SPIRE", 72, COL_TEXT)
	_text_c(140, 245, 1000, "A Tetris roguelike — climb 12 floors, slay the Warden", 22, COL_DIM)
	_panel(Rect2(290, 290, 700, 240))
	_text(Vector2(320, 330), "Clear lines to damage the enemy above your stack.", 18, COL_TEXT)
	_text(Vector2(320, 360), "Damage = CHIPS x MULT / 8, Balatro style.", 18, COL_GOLD)
	_text(Vector2(320, 390), "Tetrises x2 mult. T-spins x3. Combos stack +0.5 each.", 18, COL_ACCENT)
	_text(Vector2(320, 420), "Enemies drop garbage on a timer. Getting crushed hurts.", 18, COL_TEXT)
	_text(Vector2(320, 450), "Collect relics, buy power in shops, forge at campfires.", 18, COL_TEXT)
	_text(Vector2(320, 490), "Arrows move · Up/X rotate · Z ccw · Space hard drop · C hold", 16, COL_DIM)
	_button(Rect2(490, 570, 300, 64), "BEGIN THE CLIMB", func() -> void: _new_run())

func _draw_gameover() -> void:
	_text_c(140, 240, 1000, "YOU DIED", 72, COL_RED)
	_text_c(140, 300, 1000, "The spire claims another climber on floor %d." % int(run.floor_num), 24, COL_DIM)
	_text_c(140, 350, 1000, "Relics collected: %d   ·   Gold remaining: %d" % [run.relics.size(), int(run.gold)], 20, COL_TEXT)
	_button(Rect2(490, 430, 300, 64), "Try Again", func() -> void: _new_run())
	_button(Rect2(490, 510, 300, 50), "Main Menu", func() -> void: state = State.MENU)

func _draw_win() -> void:
	_text_c(140, 220, 1000, "THE SPIRE IS CLEARED!", 60, COL_GOLD)
	_text_c(140, 280, 1000, "The Warden lies buried under ten thousand blocks.", 24, COL_TEXT)
	_text_c(140, 330, 1000, "Floor 12  ·  %d relics  ·  %d gold left  ·  %d HP remaining" % [run.relics.size(), int(run.gold), int(run.hp)], 20, COL_DIM)
	_button(Rect2(490, 420, 300, 64), "New Run", func() -> void: _new_run())

# ---------------- Master draw ----------------

func _draw() -> void:
	_buttons = []
	draw_rect(Rect2(0, 0, 1280, 720), COL_BG)
	match state:
		State.MENU:
			_draw_menu()
		State.BATTLE:
			_draw_battle()
		State.MAP:
			_draw_map()
		State.REWARD:
			_draw_reward()
		State.SHOP:
			_draw_shop()
		State.REST:
			_draw_rest()
		State.GAMEOVER:
			_draw_gameover()
		State.WIN:
			_draw_win()
	_draw_fx()
