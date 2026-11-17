class_name  MaterialHandler

var path: Dictionary

func _init() -> void:
	path = {
	"Basic": preload("res://data/materials/basic_material.tres"),
	"Brick": preload("res://data/materials/brick_material.tres"),
	"Grass": preload("res://data/materials/grass_material.tres"),
	"Glass": preload("res://data/materials/glass_material.tres"),
	"Ice": preload("res://data/materials/ice_material.tres"),
	"Slime": preload("res://data/materials/slime_material.tres"),
}
#used to make material 
func make_Material(card : CardData, material:String):
	#block.mat= path[material]
	card.material = path[material]
	print(card.material)


func play_grass(card_deck :CardPile, block : Node2D, card : CardData):
	#make_Material(card,"grass")
	#draw 1
	card_deck.draw(1)


func play_glass():
	pass


	
	
