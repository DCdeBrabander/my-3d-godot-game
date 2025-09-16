@tool

class_name SolarSystem extends Node3D

@export var Sun: PackedScene
@export var Planet: PackedScene

@export var planet_amount := 8
@export var orbit_material: StandardMaterial3D
@export var orbit_material_highlighted: StandardMaterial3D

@onready var MainCamera: Camera3D = $MainCamera
@onready var HUD: CanvasLayer = preload("res://UI/HUD.tscn").instantiate()
@onready var PlanetFactory: PlanetFactory = $PlanetFactory

# In the future it could be a black hole? 
var system_center_node: Node3D

# Orbit management
var planets: Array[Planet] = []
var orbit_circles: Array[MeshInstance3D] = []
var planet_orbit_map: Dictionary = {}  # planet_index -> orbit_circle
var active_planet_index: int = -1

# TODO: Use as AU ?
var universal_unit = 1.0

func _ready() -> void:
	#set_orbit_circle_style()
	add_child(HUD)
	add_sun()
	add_planets()
	
func add_sun() -> void:
	var sun = Sun.instantiate()
	system_center_node = sun
	add_child(sun)

func add_planets() -> void:
	for index in planet_amount:
		var planet = PlanetFactory.create_planet(
			index, 
			planet_amount, 
			system_center_node
		)
		add_child(planet)
		
		var orbit_circle = create_orbit_circle(planet)
		orbit_circles.append(orbit_circle)
		planet_orbit_map[index] = orbit_circle
		add_child(orbit_circle)

func create_orbit_circle(planet: Planet):
	var orbit_visual = Node3D.new()
	orbit_visual.name = "OrbitCircle"
	
	var points = PackedVector3Array()
	var segments = clamp(int(planet.orbit_radius / 5), 64, 256)  # Fewer segments for smaller orbits

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
	
	return orbit_visual
	
func setup_orbit_materials():
	# Default orbit material - subtle
	orbit_material = StandardMaterial3D.new()
	orbit_material.albedo_color = Color(1.0, 1.0, 1.0, 0.15)  # Slightly more visible than 0.01
	orbit_material.flags_unshaded = true
	orbit_material.flags_transparent = true
	orbit_material.no_depth_test = true  # Prevents z-fighting
	orbit_material.vertex_color_use_as_albedo = false
	
	# Highlighted orbit material - bright and visible
	orbit_material_highlighted = StandardMaterial3D.new()
	orbit_material_highlighted.albedo_color = Color(1.0, 1.0, 0.0, 0.8)  # Bright yellow
	orbit_material_highlighted.flags_unshaded = true
	orbit_material_highlighted.flags_transparent = true
	orbit_material_highlighted.no_depth_test = true
	orbit_material_highlighted.vertex_color_use_as_albedo = false

# Public API for orbit highlighting
func highlight_planet_orbit(planet_index: int):
	# Unhighlight current orbit if any
	if active_planet_index >= 0:
		unhighlight_current_orbit()
	
	# Highlight the requested orbit
	if planet_orbit_map.has(planet_index):
		var orbit_circle = planet_orbit_map[planet_index]
		orbit_circle.material_override = orbit_material_highlighted
		active_planet_index = planet_index

func unhighlight_current_orbit():
	if active_planet_index >= 0 and planet_orbit_map.has(active_planet_index):
		var orbit_circle = planet_orbit_map[active_planet_index]
		orbit_circle.material_override = orbit_material
		active_planet_index = -1

func unhighlight_all_orbits():
	for orbit_circle in orbit_circles:
		orbit_circle.material_override = orbit_material
	active_planet_index = -1

# Signal handlers
func _on_planet_selected(planet_index: int):
	highlight_planet_orbit(planet_index)

func _on_planet_deselected():
	unhighlight_current_orbit()

# Utility functions
func get_planet_by_index(index: int) -> Planet:
	if index >= 0 and index < planets.size():
		return planets[index]
	return null

func get_active_planet() -> Planet:
	return get_planet_by_index(active_planet_index)

# For external systems to trigger highlighting
func set_active_planet(planet_index: int):
	highlight_planet_orbit(planet_index)

func clear_active_planet():
	unhighlight_current_orbit()

# Optional: Toggle all orbit visibility
func set_orbits_visible(visible: bool):
	for orbit_circle in orbit_circles:
		orbit_circle.visible = visible
