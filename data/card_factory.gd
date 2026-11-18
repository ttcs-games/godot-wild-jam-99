class_name CardFactory

const L_SHAPE = preload("res://data/shapes/L_shape.tres")
const REVERSEL_SHAPE = preload("res://data/shapes/ReverseL_shape.tres")

const SKEW_SHAPE = preload("res://data/shapes/Skew_shape.tres")
const REVERSESKEW_SHAPE = preload("res://data/shapes/ReverseSkew_shape.tres")

const SQUARE_SHAPE = preload("res://data/shapes/square_shape.tres")
const I_SHAPE = preload("res://data/shapes/I_shape.tres")
const T_SHAPE = preload("res://data/shapes/T_shape.tres")

const BASIC_MATERIAL = preload("res://data/materials/basic_material.tres")

const shape_dict = {"L-shape": L_SHAPE, "Reverse L-shape": REVERSEL_SHAPE, "Skew-shape": SKEW_SHAPE, "Reverse Skew-shape": REVERSESKEW_SHAPE, "Square": SQUARE_SHAPE, "I-shape": I_SHAPE, "T-Shape": T_SHAPE}

static func make(shape: ShapeData, element: Elements.Id, material: MaterialData) -> CardData:
	var card := CardData.new()
	card.shape = shape
	card.element = element
	card.material = material
	return card
	
static func standard_deck() -> Array[CardData]:
	var deck: Array[CardData] = []
	
	deck.append(make(L_SHAPE.duplicate(), Elements.Id.RED, BASIC_MATERIAL))
	deck.append(make(L_SHAPE.duplicate(), Elements.Id.BLUE, BASIC_MATERIAL))
	deck.append(make(L_SHAPE.duplicate(), Elements.Id.GREEN, BASIC_MATERIAL))
	deck.append(make(L_SHAPE.duplicate(), Elements.Id.YELLOW, BASIC_MATERIAL))
	
	deck.append(make(REVERSEL_SHAPE.duplicate(), Elements.Id.RED, BASIC_MATERIAL))
	deck.append(make(REVERSEL_SHAPE.duplicate(), Elements.Id.BLUE, BASIC_MATERIAL))
	deck.append(make(REVERSEL_SHAPE.duplicate(), Elements.Id.GREEN, BASIC_MATERIAL))
	deck.append(make(REVERSEL_SHAPE.duplicate(), Elements.Id.YELLOW, BASIC_MATERIAL))
	
	deck.append(make(SKEW_SHAPE.duplicate(), Elements.Id.RED, BASIC_MATERIAL))
	deck.append(make(SKEW_SHAPE.duplicate(), Elements.Id.BLUE, BASIC_MATERIAL))
	deck.append(make(SKEW_SHAPE.duplicate(), Elements.Id.GREEN, BASIC_MATERIAL))
	deck.append(make(SKEW_SHAPE.duplicate(), Elements.Id.YELLOW, BASIC_MATERIAL))
	
	deck.append(make(REVERSESKEW_SHAPE.duplicate(), Elements.Id.RED, BASIC_MATERIAL))
	deck.append(make(REVERSESKEW_SHAPE.duplicate(), Elements.Id.BLUE, BASIC_MATERIAL))
	deck.append(make(REVERSESKEW_SHAPE.duplicate(), Elements.Id.GREEN, BASIC_MATERIAL))
	deck.append(make(REVERSESKEW_SHAPE.duplicate(), Elements.Id.YELLOW, BASIC_MATERIAL))
	
	deck.append(make(T_SHAPE.duplicate(), Elements.Id.RED, BASIC_MATERIAL))
	deck.append(make(T_SHAPE.duplicate(), Elements.Id.BLUE, BASIC_MATERIAL))
	deck.append(make(T_SHAPE.duplicate(), Elements.Id.GREEN, BASIC_MATERIAL))
	deck.append(make(T_SHAPE.duplicate(), Elements.Id.YELLOW, BASIC_MATERIAL))
	
	deck.append(make(I_SHAPE.duplicate(), Elements.Id.RED, BASIC_MATERIAL))
	deck.append(make(I_SHAPE.duplicate(), Elements.Id.BLUE, BASIC_MATERIAL))
	deck.append(make(I_SHAPE.duplicate(), Elements.Id.GREEN, BASIC_MATERIAL))
	deck.append(make(I_SHAPE.duplicate(), Elements.Id.YELLOW, BASIC_MATERIAL))
	
	deck.append(make(SQUARE_SHAPE.duplicate(), Elements.Id.RED, BASIC_MATERIAL))
	deck.append(make(SQUARE_SHAPE.duplicate(), Elements.Id.BLUE, BASIC_MATERIAL))
	deck.append(make(SQUARE_SHAPE.duplicate(), Elements.Id.GREEN, BASIC_MATERIAL))
	deck.append(make(SQUARE_SHAPE.duplicate(), Elements.Id.YELLOW, BASIC_MATERIAL))
	return deck

static func return_original_shape(card: CardData):
	card.shape = shape_dict[card.shape.display_name]
