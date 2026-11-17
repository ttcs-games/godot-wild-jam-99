# Info holder of materials: name and description
# Important: does not actually hold any logic about the trait itself
 
class_name MaterialData
extends Resource
enum ID {BRICK,GLASS,GRASS, ICE, SLIME} 
@export var display_name: String = "Basic"
@export var description: String = "Has no additional properties."
@export var sprite :Resource
