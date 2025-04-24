@tool

extends Node3D

@export var Sun: PackedScene
@export var Planet: PackedScene
@export var PlanetAmount := 10

@onready var MainCamera: Camera3D = $MainCamera

# In the future it could be a black hole? 
var system_center_node: Node3D

func _ready() -> void:
	add_sun()
	add_planets()
	
func add_sun() -> void:
	var sun = Sun.instantiate()
	system_center_node = sun
	add_child(sun)
	
func add_planets() -> void:
	for index in PlanetAmount: 
		var planet = Planet.instantiate()
		planet.position = Vector3((index + 1) * 5, 0, 0)
		planet.orbit_center_node = system_center_node
		planet.planet_index = index 
		add_child(planet)
