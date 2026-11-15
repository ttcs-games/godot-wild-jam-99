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
	#Dirty check here, just making sure the two are opposites
	if ((a == 0 && b == 1) || (a == 1 && b == 0) || (a == 2 && b == 3) || (a == 3 && b == 2)):
		return true
	else:
		return false
