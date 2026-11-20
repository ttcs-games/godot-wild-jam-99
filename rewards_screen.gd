extends Control

@export var Reward_amount : int = 0
@export var total_cards_choice = 12 #how many cards are displayed when a reward is picked

@onready var RewardButtons : Array[Button] = [$HBoxContainer/VBoxContainer/Button, $HBoxContainer/VBoxContainer/Button2, $HBoxContainer/VBoxContainer/Button3, $HBoxContainer/VBoxContainer/Button4, $HBoxContainer/VBoxContainer/Button5]
@onready var RedrawButtons : Array[Button] = [$HBoxContainer/RedrawButtonContainer/TextureButton, $HBoxContainer/RedrawButtonContainer/TextureButton2, $HBoxContainer/RedrawButtonContainer/TextureButton3, $HBoxContainer/RedrawButtonContainer/TextureButton4, $HBoxContainer/RedrawButtonContainer/TextureButton5]
@onready var ClickableDeck := $DeckView
@onready var RewardOptionsBox := $HBoxContainer
@onready var NextLevelButton: Button = $NextLevelButton
@onready var RedrawAmountLabel : Label = $"HBoxContainer/RedrawButtonContainer/Redraws Left"

var Rewards : Array[Reward] = []
var index_of_reward_applied : int
var reward_strings : Array[String] = []
var cards_to_apply_rewards = [[], [], [], [], []]
var _rng := RandomNumberGenerator.new()

const TOOLTIP_GAP := 12.0
var _tooltip: PanelContainer = null
var _tooltip_label: RichTextLabel = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.play_slide_in(self)
	Reward_amount = GameManager.REWARD_AMOUNT #REWARD_AMOUNT should be changed before this scene is triggered
	RedrawAmountLabel.text = "x%d" % [GameManager.redraws] #number of redraws the player has
	
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
		if (i < 5): #first five rewards all 
			#randomly defining what kind of reward and how many cards it can affect
			var newReward : Reward
			if (i == 0): #first reward is always one that adds a trait to a card
				newReward= Reward.new(2,1)
			elif len(GameManager.deck._cards) > 10: #if the player has less than ten cards, they shouldn't be allowed to remove more.
				newReward= Reward.new(_rng.randi_range(0,4),1)
			else:
				newReward= Reward.new(_rng.randi_range(1,4),1)
			
			#making sure this reward isn't the same as another reward
			if (Rewards.any(newReward.simple_equals)):
				continue
			
			#activating the buttons that are connected to the rewards
			RewardButtons[i].disabled = false
			
			#disabling redraw button if its a remove card reward
			RedrawButtons[i].disabled = true if newReward.Type == Reward.Types.REMOVE else false
			
			
			RewardButtons[i].mouse_entered.connect(_on_reward_button_hovered.bind(i))
			RewardButtons[i].mouse_exited.connect(_on_reward_button_unhovered)
			Rewards.append(newReward)
			
		else: #if reward amount is over 5, just increments the number of cards affected for a random previous reward
			Rewards.pick_random().amount += 1
			
		i = i + 1
	
	i = 0
	while (i < len(Rewards)):
		RewardButtons[i].text = RewardText(i,Rewards[i])
		reward_strings.append(RewardButtons[i].text) #used later when the deck view is created
		i = i + 1
	
	#creating the list of cards on which each reward can be applied
	create_sub_decks()

#all five buttons are connected to the same function, just giving different indexes
func _on_button_pressed(button_index: int) -> void:
	SFX.button()
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

func _format_reward_tooltip(reward: Reward) -> String:
	if reward == null:
		return ""

	match reward.Type:
		Reward.Types.REMOVE, Reward.Types.CHANGE_SHAPE:
			return ""

		Reward.Types.ADD:
			var data := reward.Card_added
			if data == null:
				return ""
			var element_name := Elements.display_name(data.element)
			var opposing_id := Elements.opposing(data.element)
			var opposing_name := Elements.display_name(opposing_id)
			var mat_name := "?" if data.material == null else data.material.display_name
			var mat_desc := "" if data.material == null else data.material.description
			var shape_name := "?" if data.shape == null else data.shape.display_name

			var elem_hex := Elements.tint_hex(data.element, 0.5)
			var opp_hex := Elements.tint_hex(opposing_id, 0.5)

			var colored_elem := "[color=%s]%s[/color]" % [elem_hex, Utils.escape_bbcode(element_name)]
			var colored_opp := "[color=%s]%s[/color]" % [opp_hex, Utils.escape_bbcode(opposing_name)]

			return "%s %s %s\nOpposes %s\n%s" % [
				colored_elem,
				Utils.escape_bbcode(mat_name),
				Utils.escape_bbcode(shape_name),
				colored_opp,
				Utils.escape_bbcode(mat_desc)
			]

		Reward.Types.TRAIT:
			if reward.Trait_added == null:
				return ""
			return Utils.escape_bbcode(reward.Trait_added.description)

		Reward.Types.CHANGE_ELEMENT:
			var opposing_id := Elements.opposing(reward.Element_change)
			var opposing_name := Elements.display_name(opposing_id)
			var opp_hex := Elements.tint_hex(opposing_id, 0.5)
			var colored_opp := "[color=%s]%s[/color]" % [opp_hex, Utils.escape_bbcode(opposing_name)]
			return "Opposes %s" % [colored_opp]

	return ""

func _on_reward_button_hovered(button_index: int) -> void:
	if button_index < 0 or button_index >= Rewards.size():
		return
	var btn := RewardButtons[button_index]
	if btn.disabled:
		return
	
	SFX.hover()
	var text := _format_reward_tooltip(Rewards[button_index])
	if text.is_empty():
		_hide_tooltip()
		return

	_show_tooltip(btn, text)

func _on_reward_button_unhovered() -> void:
	_hide_tooltip()

func _exit_tree() -> void:
	_hide_tooltip()

func _show_tooltip(anchor: Control, bbcode_text: String) -> void:
	_hide_tooltip()

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.z_index = 2000
	panel.visible = false

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)

	var label := RichTextLabel.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(180, 0)
	label.text = bbcode_text

	margin.add_child(label)
	panel.add_child(margin)
	get_tree().root.add_child(panel)

	_tooltip = panel
	_tooltip_label = label

	await get_tree().process_frame
	if not is_instance_valid(_tooltip) or not is_instance_valid(anchor):
		return
	await get_tree().process_frame
	if not is_instance_valid(_tooltip) or not is_instance_valid(anchor):
		return

	var viewport_size := get_viewport().get_visible_rect().size
	var target_x := anchor.global_position.x + anchor.size.x + TOOLTIP_GAP
	var target_y := anchor.global_position.y

	# Clamp inside viewport so tall/right-edge tooltips stay visible
	target_x = minf(target_x, viewport_size.x - _tooltip.size.x - 8.0)
	target_y = clampf(target_y, 8.0, maxf(8.0, viewport_size.y - _tooltip.size.y - 8.0))
	_tooltip.global_position = Vector2(maxf(target_x, 8.0), target_y)
	_tooltip.visible = true

func _hide_tooltip() -> void:
	if is_instance_valid(_tooltip):
		_tooltip.queue_free()
	_tooltip = null
	_tooltip_label = null

func _on_redraw_button_pressed(button_index: int) -> void:
	if (button_index + 1 > Reward_amount || GameManager.redraws == 0 || RewardButtons[button_index].disabled):
		return
		
	GameManager.redraws -= 1
	RedrawAmountLabel.text = "x%d" % [GameManager.redraws] #number of redraws the player has
	SFX.button()
	
	while (true):
		var newReward : Reward
		#reroll into the same reward, but of a different type.
		newReward= Reward.new(Rewards[button_index].Type,Rewards[button_index].amount)
		
		#making sure this reward isn't the same as another reward
		if (Rewards.any(newReward.equals)):
			continue
		
		#adding text to the button
		RewardButtons[button_index].text = RewardText(button_index,newReward)
		reward_strings[button_index] = RewardButtons[button_index].text 
		
		#activating the buttons that are connected to the rewards
		RewardButtons[button_index].disabled = false
		Rewards[button_index].queue_free()
		Rewards[button_index] = newReward
		
		break
	
	create_sub_decks()
	
	
	
