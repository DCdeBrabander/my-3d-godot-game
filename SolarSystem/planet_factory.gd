class_name PlanetFactory extends Node

@export var Planet: PackedScene

# TODO: refactor as scenes? 
var planet_types = [RockyPlanet, GasPlanet, IcePlanet]

# TODO: add composition for adding in (for ex) 'atmosphere', comet ring, ...
# TODO: explicitly asking for planet_type is unused at this time
func create_planet(index: int, max_index: int, center_node: Node, planet_type = null):
	var planet: Planet = Planet.instantiate()
		
	# Determine type of planet and load corresponding script into it
	var type = planet_types[randi() % planet_types.size()]
	planet.set_script(type)
	
	# Positioning planets in a circular orbit
	var orbit_radius = get_new_orbit_radius(center_node, index)
	
	var orbit_angle = index * (360 / max_index)
	
	planet.orbit_radius = orbit_radius
	planet.orbit_angle = orbit_angle
	
	planet.position = Vector3(
		orbit_radius * cos(deg_to_rad(orbit_angle)), 
		0, 
		orbit_radius * sin(deg_to_rad(orbit_angle))
	)
	
	planet.orbit_center_node = center_node
	planet.planet_index = index
	
	return planet
	
# Rough approximation of Titius-Bode law
func get_new_orbit_radius(center_node: Node, index: int, base: float = 400.0) -> float:
	var radius = base * (0.4 + 0.3 * pow(2, index))
	return max(radius, center_node.get_radius() * 2)
