extends Control

@export var Reward_amount : int = 0
var _rng := RandomNumberGenerator.new()
@export var total_cards_choice = 10

@onready var RewardButtons : Array[Button] = [$VBoxContainer/Button, $VBoxContainer/Button2, $VBoxContainer/Button3, $VBoxContainer/Button4, $VBoxContainer/Button5]
@onready var ClickableDeck := $DeckView
@onready var RewardOptionsBox := $VBoxContainer
@onready var NextLevelButton: Button = $NextLevelButton
var Rewards : Array[Reward] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#remove this line later as this scene will always be triggered after the level.
	if GameManager.deck == null:
		GameManager.init_deck()
	
	#setting cursorlayer and animation so that the deck_viewer works
	GameManager.cursorAnimation = $CursorLayer2/Cursor
	GameManager.cursor_layer = $CursorLayer2
	ClickableDeck.bind(GameManager.deck)
	ClickableDeck.clicked.connect(func(pile): GameManager.open_pile_viewer(pile, "Deck"))
	
	NextLevelButton.pressed.connect(GameManager.finish_rewards)
	
	Reward_amount = GameManager.REWARD_AMOUNT #REWARD_AMOUNT should be changed before this scene is triggered
	
	for i in range(Reward_amount):
		#randomly defining what kind of reward and how many cards it can affect
		var newReward := Reward.new(_rng.randi_range(0,4),_rng.randi_range(1,3))
		
		#adding text to the button
		addRewardText(i,newReward)
		
		#activating the buttons that are connected to the rewards
		RewardButtons[i].disabled = false
		Rewards.append(newReward)
		

#This function changes the text of the buttons depending on what kind of reward is given
func addRewardText(button_index: int, newReward: Reward):
	#creating reward button text
		if (newReward.Type == Reward.Types.ADD):
			var data := newReward.Card_added
			var material_name := "?" if data.material == null else data.material.display_name
			var element_name := Elements.display_name(data.element)
			var shape_name := "?" if data.shape == null else data.shape.display_name
			
			RewardButtons[button_index].text = "Add %d %s %s %s Card(s) to your Deck" % [newReward.amount,material_name, element_name, shape_name]
		
		elif (newReward.Type == Reward.Types.REMOVE):
			RewardButtons[button_index].text = "Remove %d Card(s) from your Deck" % [newReward.amount]
			
		elif (newReward.Type == Reward.Types.TRAIT):
			var material_name := newReward.Trait_added.display_name
			RewardButtons[button_index].text = "Change %d Card(s) to %s" % [newReward.amount, material_name]
			
		elif (newReward.Type == Reward.Types.CHANGE_SHAPE):
			var shape_name := newReward.Shape_change.display_name
			RewardButtons[button_index].text = "Change %d Card(s) to %s" % [newReward.amount,shape_name]
			
		elif (newReward.Type == Reward.Types.CHANGE_ELEMENT):
			var element_name := Elements.display_name(newReward.Element_change)
			RewardButtons[button_index].text = "Change %d Card(s) to %s Element" % [newReward.amount,element_name]

#all five buttons are connected to the same function, just giving different indexes
func _on_button_pressed(button_index: int) -> void:
	var Reward_Given := Rewards[button_index]
	RewardButtons[button_index].disabled = true #reward is disabled permanently once selected
	
	var cards_affected := GameManager.deck
	
	#handling adding cards. It's the simplest reward.
	if Reward_Given.Type == Reward.Types.ADD:
		for i in range(Reward_Given.amount):
			cards_affected.add(Reward_Given.Card_added)
	
	else:
		RewardOptionsBox.visible = false #disappearing the box so that the cards are the only thing on screen
		cards_affected.shuffle() #shuffling cards before grabbing
		
		GameManager.reward_to_apply = Reward_Given
		GameManager._reward_chosen = true
		
		GameManager.open_pile_viewer(cards_affected, "Cards Affected (Reward will be forfeited if you leave)", total_cards_choice - 1, false)	
		GameManager._open_viewer.close_requested.connect(_on_deck_viewer_closed)

func _on_deck_viewer_closed() -> void:
	GameManager.reward_to_apply = null
	GameManager._reward_chosen = false
	RewardOptionsBox.visible = true #reappearing the cards once award is selected
	
