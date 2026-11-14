# Holder of all the data about the card: its shape, element and material

class_name CardData
extends Resource

@export var shape: ShapeData
@export var element: Elements.Id = Elements.Id.RED
@export var material: MaterialData
