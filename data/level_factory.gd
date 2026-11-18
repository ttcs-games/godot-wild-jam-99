class_name LevelFactory

static func generate(level_number: int) -> LevelData:
	var d := LevelData.new()
	d.level_number = level_number
	var boss := level_number % 3 == 0
	
	if boss:
		d.display_name = "Boss Level %d" % (level_number/3)
	else:
		d.display_name = "Level %d" % level_number

	d.is_boss_level = boss
	d.grid_width   = 8 + level_number/2
	d.grid_height  = 14 + level_number
	d.lava_per_turn = 1 + int((level_number - 1) / 3)
	d.lava_delay = maxi(0, 3-level_number)
	d.draw_per_turn = 8 - int(level_number / 3)
	d.objective_row = maxi(1, d.grid_height - 5 - (level_number - 1))
	return d
