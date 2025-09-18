extends CharacterBody3D

class_name Satellite

@export var orbit_speed: float = 1.0
@export var orbit_distance: float = 10.0

var target_planet: Node3D
var is_selected: bool = false
var orbit_angle: float = 0.0

func set_orbit_target(planet: Node3D):
	target_planet = planet

func _physics_process(delta):
	if target_planet:
		orbit_around_planet(delta)
