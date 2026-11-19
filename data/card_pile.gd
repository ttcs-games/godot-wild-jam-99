class_name CardPile
extends RefCounted

signal changed

@export var _cards: Array[CardData] = []
var _rng := RandomNumberGenerator.new()

func size() -> int:
	return _cards.size()

func is_empty() -> bool:
	return _cards.is_empty()
	
func clear() -> void:
	_cards.clear()
	changed.emit()

func add(card: CardData) -> void:
	if card == null:
		push_error("CardPile.add: null card")
		return
	_cards.append(card)
	changed.emit()

func add_all(cards: Array[CardData]) -> void:
	for card in cards:
		_cards.append(card)
	changed.emit()
	
func remove(card: CardData) -> void:
	if card == null:
		push_error("CardPile.add: null card")
		return
	_cards.erase(card)
	changed.emit()
	
func remove_all(cards: Array[CardData]) -> void:
	for card in cards:
		_cards.erase(card)
	changed.emit()

func draw_all() -> Array[CardData]:
	var out = _cards.duplicate(true)
	_cards.clear()
	changed.emit()
	return out

func shuffle() -> void:
	_cards.shuffle()

func drawSpecificCard(n:int) -> CardData:
	var return_card := _cards[n]
	_cards.remove_at(n) 
	changed.emit()
	return return_card

func draw(n: int) -> Array[CardData]:
	var out: Array[CardData] = []
	var count := mini(n, _cards.size())
	for i in count:
		out.append(_cards.pop_back())
	if count > 0:
		changed.emit()
	return out

func get_cards_copy() -> Array[CardData]:
	return _cards.duplicate(true)
