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

func get_path(material:String):
	print(path)
	return path[material]
#When placed, select a Non-Glass card from discard pile to return into hand
func play_grass(card_deck :CardPile, block : Node2D, card : CardData):
	card.material = path["Grass"]
	card_deck.draw(1)
#When placed distroyes itself and the same row around it, draw 1 random card for each 2 blocks distroyed
func playGlass(card_deck: CardPile, grid :Node2D ):
	card_deck.draw(grid.count_block())
	grid._break_rows()

func play_glass():
	pass		


	
	
