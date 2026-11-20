
class_name Reward
extends Node

#Update this if the number of shapes, elements or materials changes
#frankly this is a bunch of bullshit, but I have to make it into arrays for the random reward generation
enum Types { REMOVE, ADD, TRAIT, CHANGE_SHAPE, CHANGE_ELEMENT }
const Shapes: Array[ShapeData] = [CardFactory.L_SHAPE, CardFactory.REVERSEL_SHAPE, CardFactory.SKEW_SHAPE, CardFactory.REVERSESKEW_SHAPE, CardFactory.SQUARE_SHAPE, CardFactory.I_SHAPE, CardFactory.T_SHAPE]
const CardElements: Array[Elements.Id] = [Elements.Id.RED, Elements.Id.BLUE, Elements.Id.GREEN, Elements.Id.YELLOW]
const Materials: Array[MaterialData] = [preload("res://data/materials/brick_material.tres"), preload("res://data/materials/glass_material.tres"), preload("res://data/materials/grass_material.tres"), preload("res://data/materials/ice_material.tres"), preload("res://data/materials/slime_material.tres")]

var Card_added : CardData
var Shape_change : ShapeData
var Element_change: Elements.Id
var Trait_added: MaterialData

var Type: Types = Types.ADD
var amount := 1

func _init(reward_type : int, number_of_rewards: int):
	Type = reward_type
	amount = number_of_rewards
	
	#don't need to do any additional processing if cards are only being removed.
	if (Type == Types.ADD):
		#big line. All it does is make copies of the random cards.
		Card_added = CardFactory.make(Shapes.pick_random(),CardElements.pick_random(),Materials.pick_random())
	elif (Type == Types.TRAIT):
		Trait_added = Materials.pick_random()
	elif (Type == Types.CHANGE_SHAPE):
		Shape_change = Shapes.pick_random()
	elif (Type == Types.CHANGE_ELEMENT):
		Element_change = CardElements.pick_random()
		
func simple_equals (b: Reward) -> bool:
	if (self.Type == b.Type):
		return true
	return false

func equals(b: Reward) -> bool:
	#used to make sure repeat rewards are not given out
	if (self.Type == b.Type):
		if (self.Type == Types.REMOVE):
			return true
		elif (self.Type == Types.TRAIT && self.Trait_added == b.Trait_added):
			return true
		elif (self.Type == Types.CHANGE_SHAPE && self.Shape_change == b.Shape_change):
			return true
		elif (self.Type == Types.CHANGE_ELEMENT && self.Element_change == b.Element_change):
			return true
		elif (self.Type == Types.ADD && self.Card_added.element == b.Card_added.element && self.Card_added.element == b.Card_added.element && self.Card_added.shape == b.Card_added.shape):
			return true
	return false
