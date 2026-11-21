# Global enum for all element types
# Allows getting the ID for each element
# Provides helper-functions for hue shift value and display name for each element, also check for opposing elements
  
class_name Elements
enum Id { RED, BLUE, GREEN, YELLOW }

static func color(e: Id) -> float:
	return [0, 250, 125, 50][e]

static func display_name(e: Id) -> String:
	return ["Fire", "Water", "Ground", "Lightning"][e]

static func opposing(e: Id) -> Id:
	match e:
		Id.RED:
			return Id.BLUE
		Id.BLUE:
			return Id.RED
		Id.GREEN:
			return Id.YELLOW
		Id.YELLOW:
			return Id.GREEN
		_:
			return Id.RED

static func opposes(a: Id, b: Id) -> bool:
	return opposing(a) == b

static func isSame(a:Id, b:Id)->bool:
	return a == b

static func tint_hex(e: Id, tint_amount: float = 0.5) -> String:
	var base := Color.from_hsv(color(e) / 360.0, 0.85, 1.0)
	return "#" + base.lerp(Color.WHITE, tint_amount).to_html(false)
