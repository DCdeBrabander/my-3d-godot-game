@tool

extends Node

var generated_names: Array = []

func generate_planet_name(use_numeral := true) -> String:
	var prefixes = [
		"Zor", "Vel", "Xan", "Thal", "Kor", "Lum", "Nex", "Vor", "Gal", "Syr", "Dro", "Tyr"
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
