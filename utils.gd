extends Node

var prefixes = [
	"Zor", "Vel", "Xan", "Thal", "Kor", "Lum", "Nex", "Vor", "Gal", "Syr", "Dro", "Tyr"
]

var suffixes = [
	"on", "ar", "us", "ex", "ia", "or", "is", "en", "ax", "ium"
]

var numerals = [
	"I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"
]

func generate_planet_name(use_numeral := true) -> String:
	var name = prefixes.pick_random() + suffixes.pick_random()
	if use_numeral and randf() < 0.5:
		name += " " + numerals.pick_random()
	return name
