class_name LevelData
extends Resource

@export var level_number: int = 1
@export var display_name: String = "Level 1"

@export var grid_width: int = 10
@export var grid_height: int = 18

# Absolute row index (0 = top). Objective = this row or any above.
@export var objective_row: int = 8

@export var lava_per_turn: int = 1
@export var draw_per_turn: int = 8

@export var is_boss_level: bool = false
