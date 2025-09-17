@tool

extends Node

var generated_names: Array = []

static func generate_planet_name() -> String:
	var syllables = randi_range(2, 4)
	var name = ""
	
	for i in range(syllables):
		var is_first = (i == 0)
		var is_last = (i == syllables - 1)
		
		# Start syllable with consonant (softer start for first syllable)
		if not is_first or randf() > 0.4:
			# 30% chance of consonant cluster, else single consonant
			if randf() < 0.3:
				var clusters = ["bl", "br", "cl", "cr", "dr", "fl", "fr", "gl", "gr", "pl", "pr", "sc", "sk", "sl", "sp", "st", "tr", "th", "ch"]
				name += clusters.pick_random()
			else:
				var consonants = "bcdfghjklmnprstv"
				name += consonants[randi() % consonants.length()]
		
		# Add vowel (weighted for natural distribution)
		var vowel_roll = randi() % 10
		if vowel_roll < 2: name += "a"
		elif vowel_roll < 4: name += "e" 
		elif vowel_roll < 5: name += "i"
		elif vowel_roll < 7: name += "o"
		elif vowel_roll < 8: name += "u"
		elif vowel_roll < 9: name += "ae"
		else: name += "ei"
		
		# Add ending consonant or classical ending
		if is_last and randf() < 0.7:
			var endings = ["us", "is", "um", "on", "an", "os", "as", "or", "ar", "ia"]
			name += endings.pick_random()
		elif not is_last and randf() < 0.3:
			var end_consonants = "mnrstl"
			name += end_consonants[randi() % end_consonants.length()]
	
	# Capitalize and optionally add suffix
	name = name.capitalize()
	
	# 25% chance of numerical suffix
	if randf() < 0.25:
		var suffix_type = randi() % 4
		match suffix_type:
			0: name += " " + str(randi_range(1, 999))
			1: name += " " + char(65 + randi() % 26)
			2: name += " " + "I".repeat(randi_range(1, 5))
			3: name += " " + ["Prime", "Major", "Minor", "Alpha", "Beta"].pick_random()
	
	return name
	
# Determine a planet size (radius) from a range using a curve.
func pick_from_range_with_bias(range: Vector2) -> float:
	var rmin = range.x
	var rmax = range.y

	# Bias toward the middle of the range by averaging two uniform samples
	var u = (randf() + randf()) / 2.0   # triangular distribution
	var radius = lerp(rmin, rmax, u)

	return round(radius * 100.0) / 100.0
