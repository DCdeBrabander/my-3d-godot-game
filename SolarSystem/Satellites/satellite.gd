extends CharacterBody3D

class_name Satellite

@export var orbit_speed: float = 1.0
@export var orbit_distance: float = 15.0

var target_planet: Node3D
var current_orbit_planet: Planet
var is_selected: bool = false

var orbit_angle: float = 0.0
var orbit_radius: float = 0.0
var orbit_tilt: float = 0.0  # Random tilt angle
var orbit_rotation: float = 0.0  # Random rotation around Y axis

func _ready():
	orbit_angle = randf() * TAU
	orbit_tilt = randf_range(-PI/4, PI/4)  # Random tilt up to 45 degrees
	orbit_rotation = randf() * TAU  # Random rotation around planet
	
func set_orbit_target(planet: Planet):
	current_orbit_planet = planet

func _physics_process(delta):
	if current_orbit_planet:
		orbit_planet(delta)

func orbit_planet(delta: float):
	if current_orbit_planet == null: 
		return
#
	orbit_angle += orbit_speed * delta
	var x = orbit_distance * cos(orbit_angle)
	var z = orbit_distance * sin(orbit_angle)
	var y = 0.0
	
	var orbit_pos = Vector3(x, y, z)
	
	# Apply random tilt (rotation around X axis)
	orbit_pos = orbit_pos.rotated(Vector3.RIGHT, orbit_tilt)
	
	# Apply random rotation (rotation around Y axis) 
	orbit_pos = orbit_pos.rotated(Vector3.UP, orbit_rotation)
	
	# Set final position relative to planet
	global_position = current_orbit_planet.global_position + orbit_pos
