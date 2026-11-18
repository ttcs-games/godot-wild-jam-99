extends Control

@export var Reward_amount : int = 0
@export var total_cards_choice = 10 #how many cards are displayed when a reward is picked

@onready var RewardButtons : Array[Button] = [$VBoxContainer/Button, $VBoxContainer/Button2, $VBoxContainer/Button3, $VBoxContainer/Button4, $VBoxContainer/Button5]
@onready var ClickableDeck := $DeckView
@onready var RewardOptionsBox := $VBoxContainer
@onready var NextLevelButton: Button = $NextLevelButton
var Rewards : Array[Reward] = []
var index_of_reward_applied : int
var reward_strings : Array[String] = []
var cards_to_apply_rewards = [[], [], [], [], []]
var _rng := RandomNumberGenerator.new()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Reward_amount = GameManager.REWARD_AMOUNT #REWARD_AMOUNT should be changed before this scene is triggered
	Reward_amount = 5
	#remove this line later as this scene will always be triggered after the level.
	if GameManager.deck == null:
		GameManager.init_deck()
	
	#setting cursorlayer and animation so that the deck_viewer works
	GameManager.cursorAnimation = $CursorLayer2/Cursor
	GameManager.cursor_layer = $CursorLayer2
	
	ClickableDeck.bind(GameManager.deck)
	ClickableDeck.clicked.connect(func(pile): GameManager.open_pile_viewer(pile, "Deck"))
	
	NextLevelButton.pressed.connect(GameManager.finish_rewards)
	
	GameManager.reward_applied.connect(reward_applied_aftermath)
	
	var i = 0
	while i < Reward_amount:
		#randomly defining what kind of reward and how many cards it can affect
		var newReward : Reward
		if len(GameManager.deck._cards) > 10: #if the player has less than ten cards, they shouldn't be allowed to remove more.
			newReward= Reward.new(_rng.randi_range(0,4),_rng.randi_range(1,3))
		else:
			newReward= Reward.new(_rng.randi_range(1,4),_rng.randi_range(1,3))
		
		#making sure this reward isn't the same as another reward
		if (Rewards.any(newReward.equals)):
			continue
		
		#adding text to the button
		RewardButtons[i].text = RewardText(i,newReward)
		reward_strings.append(RewardButtons[i].text) #used later when the deck view is created
		
		#activating the buttons that are connected to the rewards
		RewardButtons[i].disabled = false
		Rewards.append(newReward)
		
		i = i + 1
		
	#creating the list of cards on which each reward can be applied
	create_sub_decks()

#all five buttons are connected to the same function, just giving different indexes
func _on_button_pressed(button_index: int) -> void:
	index_of_reward_applied = button_index
	var Reward_Given := Rewards[button_index]
	var cards_affected := GameManager.deck
	
	#handling adding cards. It's the simplest reward.
	if Reward_Given.Type == Reward.Types.ADD:
		for i in range(Reward_Given.amount):
			cards_affected.add(Reward_Given.Card_added)
			
		RewardButtons[button_index].disabled = true
	
	else:
		RewardOptionsBox.visible = false #disappearing the box so that the cards are the only thing on screen
		
		#the lines below get the cards that are at the indexes specified in cards_to_apply_rewards[button_index], then returns them as an array
		var subset_of_deck = CardPile.new()
		var card_var: Array[CardData]
		card_var.assign(cards_to_apply_rewards[button_index].map(func(i): return cards_affected._cards[i]))
		subset_of_deck.add_all(card_var)
		
		GameManager.reward_to_apply = Reward_Given
		GameManager._reward_chosen = true
		
		var viewer_text := "%s!" % [reward_strings[button_index]]
		
		GameManager.open_pile_viewer(subset_of_deck, viewer_text, total_cards_choice, false)
		GameManager._open_viewer.close_requested.connect(_on_deck_viewer_closed)

func _on_deck_viewer_closed() -> void:
	GameManager.reward_to_apply = null
	GameManager._reward_chosen = false
	RewardOptionsBox.visible = true #reappearing the cards once award is selected

#This function changes the text of the buttons depending on what kind of reward is given
func RewardText(button_index: int, newReward: Reward) -> String:
	#creating reward button text
	var text := ""
	
	if (newReward.Type == Reward.Types.ADD):
		var data := newReward.Card_added
		var material_name := "?" if data.material == null else data.material.display_name
		var element_name := Elements.display_name(data.element)
		var shape_name := "?" if data.shape == null else data.shape.display_name
		
		text = "Add %d %s %s %s Card(s) to your Deck" % [newReward.amount,material_name, element_name, shape_name]
	
	elif (newReward.Type == Reward.Types.REMOVE):
		text = "Remove %d Card(s) from your Deck" % [newReward.amount]
		
	elif (newReward.Type == Reward.Types.TRAIT):
		var material_name := newReward.Trait_added.display_name
		text = "Change %d Card(s) to %s material" % [newReward.amount, material_name]
		
	elif (newReward.Type == Reward.Types.CHANGE_SHAPE):
		var shape_name := newReward.Shape_change.display_name
		text = "Change %d Card(s) to %s" % [newReward.amount,shape_name]
		
	elif (newReward.Type == Reward.Types.CHANGE_ELEMENT):
		var element_name := Elements.display_name(newReward.Element_change)
		text = "Change %d Card(s) to %s Element" % [newReward.amount,element_name]
	
	return text

func reward_applied_aftermath():
	#disabling the reward that was applied so it can't be applied over and over
	RewardButtons[index_of_reward_applied].disabled = true
	#reshuffling the sub decks so that an error won't be raised
	create_sub_decks()
	

#creates up to five nested arrays of indexes for the deck. these are the cards on which rewards can be applied
func create_sub_decks():
	cards_to_apply_rewards = [[], [], [], [], []]
	
	#the cards which the rewards can be applied to are decided as soon as the scene begins.
	var original_deck = GameManager.deck._cards
	var i = 0
	for single_reward in Rewards:
		var indexes : Array[int] = []
		#im making this second array so that I don't get duplicate random numbers
		var all_indexes = range(len(original_deck))
		
		#don't need to create a sub-deck in case cards are being added.
		if (single_reward.Type == Reward.Types.ADD):
			i = i + 1
			continue
		
		#making sure useless cards are not given as choices for using the reward
		if (single_reward.Type == Reward.Types.TRAIT):
			all_indexes = all_indexes.map(func (j): return j if original_deck[j].material != single_reward.Trait_added else null)
		if (single_reward.Type == Reward.Types.CHANGE_SHAPE):
			all_indexes = all_indexes.map(func (j): return j if original_deck[j].shape.offsets != single_reward.Shape_change.offsets else null)
		if (single_reward.Type == Reward.Types.CHANGE_ELEMENT):
			all_indexes = all_indexes.map(func (j): return j if original_deck[j].element != single_reward.Element_change else null)
	
		all_indexes = all_indexes.filter(func (j): return j != null)
		
		#second condition is error handling. e.g deck full of yellow cards. reward is change to yellow
		while (len(indexes) < total_cards_choice && len(all_indexes) != 0):
			var random_num = all_indexes.pick_random()
			indexes.append(random_num)
			all_indexes.erase(random_num)
		
		cards_to_apply_rewards[i] = indexes
		i = i + 1
