extends Control

var Reward_amount : int = 0
var _rng := RandomNumberGenerator.new()

@onready var RewardButtons : Array[Button] = [$VBoxContainer/Button, $VBoxContainer/Button2, $VBoxContainer/Button3, $VBoxContainer/Button4, $VBoxContainer/Button5]
var Rewards : Array[Reward] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Reward_amount = GameManager.REWARD_AMOUNT #REWARD_AMOUNT should be changed before this scene is triggered
	
	for i in range(Reward_amount):
		#randomly defining what kind of reward and how many cards it can affect
		var newReward := Reward.new(_rng.randi_range(0,4),_rng.randi_range(1,5))
		
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
			pass #todo
		
		elif (newReward.Type == Reward.Types.CHANGE_SHAPE):
			var shape_name := "?" if newReward.Shape_change == null else newReward.Shape_change.display_name
			RewardButtons[button_index].text = "Change %d Card(s) to %s" % [newReward.amount,shape_name]
			
		elif (newReward.Type == Reward.Types.CHANGE_ELEMENT):
			var element_name := Elements.display_name(newReward.Element_change)
			RewardButtons[button_index].text = "Change %d Card(s) to %s" % [newReward.amount,element_name]

#all five buttons are connected to the same function, just giving different indexes
func _on_button_pressed(button_index: int) -> void:
	var Reward_Given := Rewards[button_index]
	
	
