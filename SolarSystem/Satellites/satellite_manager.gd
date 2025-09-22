extends Node

var satellite_scene = preload("res://SolarSystem/Satellites/Satellite.tscn")
var satellites: Array[Satellite] = []
	
func spawn_satellite(planet: Node3D):
	var satellite = satellite_scene.instantiate()
	satellite.set_orbit_target(planet)
	add_child(satellite)
	satellites.append(satellite)
