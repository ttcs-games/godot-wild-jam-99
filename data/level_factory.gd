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
	var modifiers_count : int = max(0,level_number / 3 - 1)
	modifiers_count += 1 if boss else 0
	
	if boss:
		d.display_name = "Boss Level %d" % (level_number/3)
	else:
		d.display_name = "Level %d" % level_number
	
	#removing useless modifier types
	var possible_modifiers : Array[Modifier.Types] = [Modifier.Types.ONLY_BLUE, Modifier.Types.ONLY_RED, Modifier.Types.ONLY_GREEN, Modifier.Types.ONLY_YELLOW, Modifier.Types.REJECT_BLUE, Modifier.Types.REJECT_RED, Modifier.Types.REJECT_GREEN, Modifier.Types.REJECT_YELLOW]
	possible_modifiers = eliminate_useless_modifiers(possible_modifiers)
	
	#creating modifiers randomly here.
	for i in range(modifiers_count):
		var new_modifier = Modifier.new(_rng.randi_range(0,len(possible_modifiers)), 1) #all modifiers begin at intensity level 1
		if (modifiers.any(func (x): return x.equals(new_modifier))): #if the modifier already exists in current modifiers
			#weird line here. It filters the array for a sub-array containing the modifier that has the same type as ours, then increases its intensity level by 1. sub-array will always have length 1, so we use [0] to get the only element.
			modifiers.filter(func (x): return x.equals(new_modifier))[0].intensity_level += 1
		else:
			modifiers.append(new_modifier)
		
	d.level_modifiers = modifiers
	d.is_boss_level = boss
	d.grid_width = mini(WIDTH_CAP, 8 + level_number/2)
	d.grid_height = mini(HEIGHT_CAP, 14 + level_number)
	d.lava_per_turn = mini(LAVA_SPEED_CAP, 1 + int((level_number - 1) / 3))
	d.lava_delay = maxi(0, 3-level_number)
	d.draw_per_turn = 8 - int(level_number / 3)
	d.objective_row = maxi(1, d.grid_height - 5 - (level_number - 1))
	return d

static func eliminate_useless_modifiers(possible_modifiers: Array[Modifier.Types]) -> Array[Modifier.Types]:
	#this is the dumbest possible way of doing this. I'll replace it with something better if I find it
	var has_blue: bool = false
	var has_red: bool = false
	var has_green: bool = false
	var has_yellow: bool = false
	
	for card in GameManager.deck._cards:
		if (card.element == Elements.Id.BLUE):
			has_blue = true
		if (card.element == Elements.Id.RED):
			has_red = true
		if (card.element == Elements.Id.GREEN):
			has_green = true
		if (card.element == Elements.Id.YELLOW):
			has_yellow = true
	
	possible_modifiers[0] = null if has_blue == false else possible_modifiers[0]
	possible_modifiers[4] = null if has_blue == false else possible_modifiers[4]
	
	possible_modifiers[1] = null if has_red == false else possible_modifiers[1]
	possible_modifiers[5] = null if has_red == false else possible_modifiers[5]
	
	possible_modifiers[2] = null if has_green == false else possible_modifiers[2]
	possible_modifiers[6] = null if has_green == false else possible_modifiers[6]
	
	possible_modifiers[3] = null if has_yellow == false else possible_modifiers[3]
	possible_modifiers[7] = null if has_yellow == false else possible_modifiers[7]
	
	possible_modifiers = possible_modifiers.filter(func(x): return x != null)
	
	return possible_modifiers
	
