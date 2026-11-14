class_name CardFactory

const L_SHAPE = preload("res://data/shapes/L_shape.tres")
const SQUARE_SHAPE = preload("res://data/shapes/square_shape.tres")
const I_SHAPE = preload("res://data/shapes/I_shape.tres")

const BASIC_MATERIAL = preload("res://data/materials/basic_material.tres")

static func make(shape: ShapeData, element: Elements.Id, material: MaterialData) -> CardData:
	var card := CardData.new()
	card.shape = shape
	card.element = element
	card.material = material
	return card
	
static func standard_deck() -> Array[CardData]:
	var deck: Array[CardData] = []
	
	deck.append(make(L_SHAPE, Elements.Id.RED, BASIC_MATERIAL))
	deck.append(make(L_SHAPE, Elements.Id.BLUE, BASIC_MATERIAL))
	deck.append(make(L_SHAPE, Elements.Id.GREEN, BASIC_MATERIAL))
	deck.append(make(L_SHAPE, Elements.Id.YELLOW, BASIC_MATERIAL))
	
	deck.append(make(I_SHAPE, Elements.Id.RED, BASIC_MATERIAL))
	deck.append(make(I_SHAPE, Elements.Id.BLUE, BASIC_MATERIAL))
	deck.append(make(I_SHAPE, Elements.Id.GREEN, BASIC_MATERIAL))
	deck.append(make(I_SHAPE, Elements.Id.YELLOW, BASIC_MATERIAL))
	
	deck.append(make(SQUARE_SHAPE, Elements.Id.RED, BASIC_MATERIAL))
	deck.append(make(SQUARE_SHAPE, Elements.Id.BLUE, BASIC_MATERIAL))
	deck.append(make(SQUARE_SHAPE, Elements.Id.GREEN, BASIC_MATERIAL))
	deck.append(make(SQUARE_SHAPE, Elements.Id.YELLOW, BASIC_MATERIAL))
	
	return deck
