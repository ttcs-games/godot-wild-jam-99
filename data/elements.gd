# Global enum for all element types
# Allows getting the ID for each element
# Provides helper-functions for hue shift value and display name for each element, also check for opposing elements
  
class_name Elements
enum Id { RED, BLUE, GREEN, YELLOW }

static func color(e: Id) -> float:
	return [0, 250, 125, 50][e]

static func display_name(e: Id) -> String:
	return ["Fire", "Water", "Ground", "Lightning"][e]

static func opposes(a: Id, b: Id) -> bool:
	return false # todo: actual check
