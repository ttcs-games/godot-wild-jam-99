class_name LevelFactory

const WIDTH_CAP = 14
const HEIGHT_CAP = 21
const LAVA_SPEED_CAP = 10 

static func generate(level_number: int) -> LevelData:
	var d := LevelData.new()
	d.level_number = level_number
	var boss := level_number % 3 == 0
	
	#defining number of modifiers and array holding modifiers
	var _rng = RandomNumberGenerator.new()
	var modifiers : Array[Modifier] = []
	var modifiers_count : int = max(5,level_number / 3 - 1)
	modifiers_count += 1 if boss else 0
	
	if boss:
		d.display_name = "Boss Level %d" % (level_number/3)
	else:
		d.display_name = "Level %d" % level_number
	
	#creating modifiers randomly here.
	var i = 0
	var modifier_weights = [1.0, 1.0, 1.0, 1.0] # ["Exclusively", "Anti", "Acid Mines", "Quicker Acid"]
	var element_weights = get_element_weights()
	while i < modifiers_count:
		var new_modifier: Modifier
		if (i == 0): #first modifier is always an element restriction
			new_modifier = Modifier.new(_rng.randi_range(0,1), _rng.rand_weighted(element_weights), 1) #all modifiers begin at intensity level 1
		else:
			new_modifier = Modifier.new(_rng.rand_weighted(modifier_weights), _rng.rand_weighted(element_weights), 1) #all modifiers begin at intensity level 1
		if (modifiers.any(func (x): return x.equals(new_modifier))): #if the modifier already exists in current modifiers
			if (new_modifier.Type == Modifier.Types.FASTER_LAVA):
				continue #quicker lava can only have an intensity level of 1
			#weird line here. It filters the array for a sub-array containing the modifier that has the same type as ours, then increases its intensity level by 1. sub-array will always have length 1, so we use [0] to get the only element.
			modifiers.filter(func (x): return x.equals(new_modifier))[0].intensity_level += 1
		else:
			modifiers.append(new_modifier)
		i = i + 1
		
	d.level_modifiers = modifiers
	d.is_boss_level = boss
	d.grid_width = mini(WIDTH_CAP, 8 + level_number/2)
	d.grid_height = mini(HEIGHT_CAP, 14 + level_number)
	d.lava_per_turn = mini(LAVA_SPEED_CAP, 1 + int((level_number - 1) / 3))
	d.lava_delay = maxi(0, 3-level_number)
	d.draw_per_turn = 8 - level_number/10
	d.objective_row = maxi(1, d.grid_height - 5 - (level_number - 1))
	return d

static func get_element_weights() -> Array[float]:
	#[0] = RED, [1] = BLUE, [2] = GREEN, [3] = YELLOW
	var element_weights: Array[float] = [0.0, 0.0, 0.0, 0.0]
	#checks if the player has cards related to the modifier element. if not, sends false
	for card in GameManager.deck._cards:
		element_weights[card.element] += 1
	return element_weights
	
