extends Control

# SETTINGS
@export var min_visible_width: float = 30.0

# CONSTANTS
const CARD := preload("res://game_objects/card.tscn")
const ANIM_SINGLE := 0.30 # per-card duration for single draw/discard
const ANIM_BATCH_PER_CARD := 0.15  # per-card duration for batched
const ANIM_STAGGER := 0.03 # delay between cards in a batch

var cards: Array[Control] = []
var _is_animating := false
var _move_tween: Tween
var _pending_layout := false

# SIGNALS
# when card is selected
signal card_selected(card: Control, card_index: int)

func _ready() -> void:
	resized.connect(_layout)

# Ini the hand: create the cards
func setup(data_array: Array[CardData]) -> void:
	clear()
	for data in data_array:
		var card: Control = CARD.instantiate()
		card.setup(data)
		add_child(card)
		card.clicked.connect(_on_card_clicked)
		cards.append(card)
	_sort_cards()
	_layout()

func get_cards_data() -> Array[CardData]:
	var out: Array[CardData] = []
	for card in cards:
		out.append(card.card_data)
	return out

func draw_batch(data_array: Array[CardData], from_pos: Vector2 = Vector2(-150, -150)) -> void:
	print("[draw_batch] CALLED with ", data_array.size(), " cards. cards.size()=", cards.size(), " frame=", Engine.get_frames_drawn())
	if data_array.is_empty():
		return
	_kill_all_tweens()
	if _move_tween != null and _move_tween.is_valid():
		_move_tween.kill()
	_move_tween = create_tween()
	_is_animating = true
	
	# Create new cards
	var new_cards: Array[Control] = []
	for data in data_array:
		var card: Control = CARD.instantiate()
		card.setup(data)
		card.position = from_pos
		card.modulate.a = 0.0
		card.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(card)
		card.clicked.connect(_on_card_clicked)
		cards.append(card)
		new_cards.append(card)
	
	_sort_cards()
	
	var n := data_array.size()
	var per_card := ANIM_SINGLE if n == 1 else ANIM_BATCH_PER_CARD
	var stagger := 0.0 if n == 1 else ANIM_STAGGER
	var targets := _compute_targets(cards)
	
	var total := cards.size()
	var card_w: float = cards[0].custom_minimum_size.x
	var step := _compute_step(total, card_w)
	_move_tween.set_parallel(true)
	# Move new and existing cards around
	for i in cards.size():
		var card := cards[i]
		card._rest_position = targets[i]
		card._rest_z = i
		card.z_index = i
		_set_card_hitbox(card, step, i == total - 1)
		# existing card needs no delay to move
		var idx_in_new := new_cards.find(card)
		var delay := 0.0 if idx_in_new < 0 else stagger * idx_in_new
		_move_tween.tween_property(card, "position", targets[i], per_card).set_delay(delay)
		# only new cards to fade-in
		if idx_in_new >= 0:
			_move_tween.tween_property(card, "modulate:a", 1.0, per_card * 0.5).set_delay(delay)
	
	await _move_tween.finished
	for card in new_cards:
		card.mouse_filter = MOUSE_FILTER_STOP
	_is_animating = false
	if _pending_layout:
		_layout()

func draw_one(data: CardData, from_pos: Vector2 = Vector2(-150, -150)) -> void:
	await draw_batch([data], from_pos)

func discard_batch(to_remove: Array[Control], to_pos: Vector2 = Vector2(800, -150)) -> void:
	if to_remove.is_empty():
		return
	
	if _move_tween != null and _move_tween.is_valid():
		_move_tween.kill()
	_move_tween = create_tween()
	_is_animating = true
	
	var n := to_remove.size()
	var per_card := ANIM_SINGLE if n == 1 else ANIM_BATCH_PER_CARD
	var stagger := 0.0 if n == 1 else ANIM_STAGGER
	
	for card in to_remove:
		if card._tween != null and card._tween.is_valid():
			card._tween.kill()
		card.mouse_filter = MOUSE_FILTER_IGNORE
	
	var remaining: Array[Control] = []
	for card in cards:
		if card not in to_remove:
			remaining.append(card)

	_move_tween.set_parallel(true)
	# Move cards away and disappear
	for i in to_remove.size():
		var card := to_remove[i]
		var delay := stagger * i
		_move_tween.tween_property(card, "position", to_pos, per_card).set_delay(delay)
		_move_tween.tween_property(card, "modulate:a", 0.0, per_card).set_delay(delay)
	
	# Move around staying cards
	if remaining.size() > 0:
		var targets := _compute_targets(remaining)
		var card_w: float = remaining[0].custom_minimum_size.x
		var step := _compute_step(remaining.size(), card_w)
		for i in remaining.size():
			var card := remaining[i]
			card._rest_position = targets[i]
			card._rest_z = i
			card.z_index = i
			_set_card_hitbox(card, step, i == remaining.size() - 1)
			_move_tween.tween_property(card, "position", targets[i], per_card)
	
	await _move_tween.finished
	
	# Actually delete removed cards
	for card in to_remove:
		cards.erase(card)
		card.queue_free()
	
	_is_animating = false
	
	if _pending_layout:
		_layout()

func discard_one(card: Control, to_pos: Vector2 = Vector2(800, -150)) -> void:
	await discard_batch([card], to_pos)

# Destroy all cards
func clear() -> void:
	for card in cards:
		card.queue_free()
	cards.clear()

# Draws the cards from hand
func _layout() -> void:
	if _is_animating:
		_pending_layout = true
		return
	_pending_layout = false
	
	var n := cards.size()
	if n == 0:
		return
	
	var card_w: float = cards[0].custom_minimum_size.x
	var targets := _compute_targets(cards)
	var step := _compute_step(n, card_w)
	for i in n:
		var card := cards[i]
		card._rest_position = targets[i]
		card._rest_z = i
		card.position = card._rest_position
		card.z_index = card._rest_z
		_set_card_hitbox(card, step, i == n - 1)

func _kill_all_tweens() -> void:
	for card in cards:
		if card._tween != null and card._tween.is_valid():
			card._tween.kill()

func _sort_cards() -> void:
	cards.sort_custom(func(a, b): return CardData.compare_for_display(a.card_data, b.card_data))

# Find the resting location for each card in a hand
func _compute_targets(list: Array[Control]) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var n := list.size()
	if n == 0:
		return out
	
	var card_w: float = list[0].custom_minimum_size.x

	if size.x <= 0.0 or card_w <= 0.0:
		for _i in n: out.append(Vector2.ZERO)
		return out
	
	var step: float
	if n == 1:
		step = 0.0
	else:
		var raw_step := (size.x - card_w) / float(n - 1)
		step = clamp(raw_step, min_visible_width, card_w)
	
	var total_w: float = step * (n - 1) + card_w
	var start_x: float = (size.x - total_w) * 0.5
	for i in n:
		out.append(Vector2(start_x + step * i, 0))
	return out
	
# Process card's signal - signal it to GameManager
# Not doing it directly from Card to GameManager because GameManager can't access Card's signal directly 
func _on_card_clicked(card: Control) -> void:
	card_selected.emit(card, cards.find(card))

func _on_grid_shape_placed(cells: Array[Vector2i], element: Elements.Id) -> void:
	print("shape placed")
	var card: Control = GameManager._active_card
	if card == null or not cards.has(card):
		return
	GameManager.discard_card(card.card_data)
	GameManager.remove_card()
	cards.erase(card)
	discard_one(card)

func _compute_step(n: int, card_w: float) -> float:
	if n <= 1 or size.x <= 0.0:
		return 0.0
	var raw_step := (size.x - card_w) / float(n - 1)
	return clamp(raw_step, min_visible_width, card_w)

func _set_card_hitbox(card: Control, step: float, is_last: bool) -> void:
	var w := card.custom_minimum_size.x
	card.set_hitbox_width(w if is_last else minf(step, w))
