@tool

extends Node3D

@export var Sun: PackedScene
@export var Planet: PackedScene
@export var planet_amount := 10
@export var orbit_material: StandardMaterial3D

@onready var MainCamera: Camera3D = $MainCamera
@onready var HUD: CanvasLayer = preload("res://UI/HUD.tscn").instantiate()

# In the future it could be a black hole? 
var system_center_node: Node3D
var planet_types = [RockyPlanet, GasPlanet, IcePlanet]

# TODO: Use as AU ?
var universal_unit = 1.0

func _ready() -> void:
	set_orbit_circle_style()
	add_child(HUD)
	add_sun()
	add_planets()
	
func add_sun() -> void:
	var sun = Sun.instantiate()
	system_center_node = sun
	add_child(sun)
	
func add_planets() -> void:
	for index in planet_amount: 
		var planet: Planet = Planet.instantiate()
		
		# Determine type of planet and load corresponding script into it
		var planet_type = planet_types[randi() % planet_types.size()]
		planet.set_script(planet_type)
		
		# Positioning planets in a circular orbit
		var orbit_radius = get_new_orbit_radius(index)
		
		var orbit_angle = index * (360 / planet_amount)
		
		planet.orbit_radius = orbit_radius
		planet.orbit_angle = orbit_angle
		
		planet.position = Vector3(
			orbit_radius * cos(deg_to_rad(orbit_angle)), 
			0, 
			orbit_radius * sin(deg_to_rad(orbit_angle))
		)
		
		planet.orbit_center_node = system_center_node
		planet.planet_index = index
		add_child(planet)
		create_orbit_circle(planet, orbit_angle)


func get_sun_radius() -> float:
	if not system_center_node or not system_center_node.mesh_instance or not system_center_node.mesh_instance.mesh is SphereMesh:
		return 1.0  # fallback
	
	return system_center_node.mesh_instance.mesh.radius
	
func get_new_orbit_radius(index: int, base: float = 100.0) -> float:
	# Rough approximation of Titius-Bode law
	var radius = base * (0.4 + 0.3 * pow(2, index))
	return max(radius, get_sun_radius() * 2)

func create_orbit_circle(planet: Planet, orbit_angle):
	var orbit_visual = Node3D.new()
	orbit_visual.name = "OrbitCircle"
	
	# Create circle points (same as before)
	var points = PackedVector3Array()
	var segments = 128
	
	for i in range(segments + 1):
		var angle = (i * PI * 2) / segments
		var x = planet.orbit_radius * cos(angle)
		var z = planet.orbit_radius * sin(angle)
		points.append(Vector3(x, 0, z))
	
	# Create mesh without material setup
	var line_mesh = MeshInstance3D.new()
	var array_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINE_STRIP, arrays)
	line_mesh.mesh = array_mesh
	line_mesh.material_override = orbit_material
	
	orbit_visual.add_child(line_mesh)
	orbit_visual.position = system_center_node.global_position
	orbit_visual.rotation = Vector3.ZERO  
	orbit_visual.scale = Vector3.ONE
	
	add_child(orbit_visual)

func set_orbit_circle_style():
	orbit_material = StandardMaterial3D.new()
	orbit_material.albedo_color = Color(1.0, 1.0, 1.0, 0.1)
	orbit_material.flags_unshaded = true
	orbit_material.flags_transparent = true
	orbit_material.vertex_color_use_as_albedo = true  # Optional: if you want colored lines
	#orbit_material.flags_use_point_size = true
