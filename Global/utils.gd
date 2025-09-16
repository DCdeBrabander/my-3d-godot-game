@tool

extends Node

var generated_names: Array = []

func generate_planet_name(use_numeral := true) -> String:
	var prefixes = [
		"Zor", "Vel", "Xan", "Thal", "Kor", "Lum", "Nex", "Vor", "Gal", "Syr", "Dro", "Tyr", "Lyn"
	]

	var suffixes = [
		"on", "ar", "us", "ex", "ia", "or", "is", "en", "ax", "ium"
	]

	var numerals = [
		"I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"
	]
	
	var random_name = prefixes.pick_random() + suffixes.pick_random()
	
	if use_numeral and randf() < 0.5:
		random_name += " " + numerals.pick_random()
	
	if generated_names.has(random_name):
		return generate_planet_name(use_numeral)
		
	generated_names.push_front(random_name)
	return random_name

# Determine a planet size (radius) from a range using a curve.
func pick_from_range_with_bias(range: Vector2) -> float:
	var rmin = range.x
	var rmax = range.y

	# Bias toward the middle of the range by averaging two uniform samples
	var u = (randf() + randf()) / 2.0   # triangular distribution
	var radius = lerp(rmin, rmax, u)

	return round(radius * 100.0) / 100.0
