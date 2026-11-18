class_name LevelFactory

static func generate(level_number: int) -> LevelData:
	var d := LevelData.new()
	d.level_number = level_number
	d.display_name = "Level %d" % level_number
	
	d.is_boss_level = false
	d.grid_width   = 8 + level_number/2
	d.grid_height  = 14 + level_number
	d.lava_per_turn = 1 + int((level_number - 1) / 3)
	d.draw_per_turn = 8 - int(level_number / 2)
	d.objective_row = maxi(1, d.grid_height - 5 - (level_number - 1))
	return d
