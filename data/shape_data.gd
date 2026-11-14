# Holder of the structure of the shape (array of vectors, normalized - starts at 0,0)
# Example: L shape is an array of (0,0) (0,1) (0,2) (1,2)

class_name ShapeData
extends Resource

@export var offsets: Array[Vector2i] = []
@export var display_name: String = "Shape"
