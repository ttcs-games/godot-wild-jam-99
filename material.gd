class_name  materials 
enum ID {BRICK,GLASS,GRASS, ICE, SLIME} 

const path = {"brick":"res://assets/sprites/Block Brick.png", "glass": "res://assets/sprites/Block Glass.png", "ice": "res://assets/sprites/Block Ice.png", 	"grass": "res://assets/sprites/Block Grass.png", "slime": "res://assets/sprites/Block Slime.png" }

const discription= {
	"brick":"When placed and touches the same element, draw 1 card from draw pile",
	"grass":"When placed, if there is at least 1 basic card in hand - turn it into Grass and draw 1 card. Cannot be replaced with new Material",
	"glass":"When placed, select a Non-Glass card from discard pile to return into hand",
	"ice": "Ignores element opposition",
	"slime":"Can be placed without foundation Shapes placed next to it dont need foundation Single play for this round"
}

func turn_grass(card_deck :CardPile, cardIndex: int):
	#turn card grass
	
	pass

func grass(card_deck :CardPile, cardIndex: int):
	turn_grass(card_deck,cardIndex)
	#draw 1
	card_deck.draw(1)
	
	
