
class_name Reward
extends Node

#Update this if the number of shapes, elements or materials changes
#frankly this is a bunch of bullshit, but I have to make it into arrays for the random reward generation
enum Types { ADD, REMOVE, TRAIT, CHANGE_SHAPE, CHANGE_ELEMENT }
const Shapes: Array[ShapeData] = [CardFactory.L_SHAPE, CardFactory.REVERSEL_SHAPE, CardFactory.SKEW_SHAPE, CardFactory.REVERSESKEW_SHAPE, CardFactory.SQUARE_SHAPE, CardFactory.I_SHAPE, CardFactory.T_SHAPE]
const CardElements: Array[Elements.Id] = [Elements.Id.RED, Elements.Id.BLUE, Elements.Id.GREEN, Elements.Id.YELLOW]
const Materials: Array[MaterialData] = [CardFactory.BASIC_MATERIAL]

var Card_added : CardData
var Shape_change : ShapeData
var Element_change: Elements.Id
#todo: var Trait_added

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
		pass #todo
	elif (Type == Types.CHANGE_SHAPE):
		Shape_change = Shapes.pick_random()
	elif (Type == Types.CHANGE_ELEMENT):
		Element_change = CardElements.pick_random()
