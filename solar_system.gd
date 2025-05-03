@tool

extends Node3D

@export var Sun: PackedScene
@export var Planet: PackedScene
@export var PlanetAmount := 10

@onready var MainCamera: Camera3D = $MainCamera
@onready var hud: CanvasLayer = preload("res://UI/HUD.tscn").instantiate()

# In the future it could be a black hole? 
var system_center_node: Node3D

func _ready() -> void:
	add_child(hud)
	add_sun()
	add_planets()
	
func add_sun() -> void:
	var sun = Sun.instantiate()
	system_center_node = sun
	#system_center_node.rotation = Vector3.ZERO # for now
	add_child(sun)
	
func add_planets() -> void:
	for index in PlanetAmount: 
		var planet = Planet.instantiate()
		
		# Positioning planets in a circular orbit
		var angle = index * (360 / PlanetAmount)  # Equal spacing
		var orbit_radius = (index + 1) * 5
		planet.position = Vector3(orbit_radius * cos(deg_to_rad(angle)), 0, orbit_radius * sin(deg_to_rad(angle)))
		
		#planet.position = Vector3((index + 1) * 5, 0, 0)
		
		planet.orbit_center_node = system_center_node
		planet.planet_index = index 
		add_child(planet)
