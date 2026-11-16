# Holder of all the data about the card: its shape, element and material

class_name CardData
extends Resource

@export var shape: ShapeData
@export var element: Elements.Id = Elements.Id.RED
@export var material: MaterialData

static func compare_for_display(a: CardData, b: CardData) -> bool:
	# Primary: element (enum int order)
	if a.element != b.element:
		return a.element < b.element
	# Secondary: material display name
	var am := a.material.display_name if a.material != null else ""
	var bm := b.material.display_name if b.material != null else ""
	if am != bm:
		return am < bm
	# Tertiary: shape display name
	var as_ := a.shape.display_name if a.shape != null else ""
	var bs := b.shape.display_name if b.shape != null else ""
	return as_ < bs
