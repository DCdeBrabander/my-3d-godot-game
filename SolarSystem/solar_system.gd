@tool

class_name SolarSystem extends Node3D

@export var Sun: PackedScene
@export var Planet: PackedScene

@export var planet_amount := 5
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

func _enter_tree() -> void:
	connect_events()

func _exit_tree() -> void:
	disconnect_events()
	
func _ready() -> void:
	setup_orbit_materials()
	add_child(HUD)
	add_sun()
	add_planets()
	
func connect_events():
	Signalbus.node_selected.connect(_on_node_selected)
	Signalbus.node_deselected.connect(_on_node_deselected)

func disconnect_events():
	Signalbus.node_selected.disconnect(_on_node_selected)
	Signalbus.node_deselected.disconnect(_on_node_deselected)
	
func _on_node_selected(selected_node: Node):
	if selected_node is Planet:
		reset_all_orbits()
		highlight_orbit_by_planet(selected_node)

func _on_node_deselected(deselected_node: Node):
	if deselected_node is Planet:
		reset_all_orbits()
	
func add_sun() -> void:
	var sun = Sun.instantiate()
	system_center_node = sun
	add_child(sun)

func add_planets() -> void:
	for index in planet_amount:
		var planet: Planet = PlanetFactory.create_planet(
			index, 
			planet_amount, 
			system_center_node
		)
		planets.append(planet)
		add_child(planet)
		
		var orbit_circle = create_orbit_circle(planet)
		var orbit_circle_mesh_instance = orbit_circle.get_child(0) as MeshInstance3D
		orbit_circles.append(orbit_circle_mesh_instance)
		planet_orbit_map[index] = orbit_circle_mesh_instance
		add_child(orbit_circle)

func create_orbit_circle(planet: Planet):
	var orbit_visual = Node3D.new()
	orbit_visual.name = "OrbitCircle"
	
	var points = PackedVector3Array()
	var segments = clamp(int(planet.orbit_radius / 5), 128, 256)  # Fewer segments for smaller orbits

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
	# Default orbit material
	orbit_material = StandardMaterial3D.new()
	orbit_material.albedo_color = Color.CYAN
	orbit_material.emission_enabled = true
	orbit_material.emission = Color.CYAN * 0.3
	orbit_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	orbit_material.albedo_color.a = 0.05
	orbit_material.unshaded = true
	
	# Selected orbit material (brighter, different color)
	orbit_material_highlighted = StandardMaterial3D.new()
	orbit_material_highlighted.albedo_color = Color.WHITE
	orbit_material_highlighted.emission_enabled = true
	orbit_material_highlighted.emission = Color.WHITE * 0.8  # Much brighter
	orbit_material_highlighted.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	orbit_material_highlighted.albedo_color.a = 0.9  # More opaque
	orbit_material_highlighted.unshaded = true

func find_planet_index(planet_node: Node) -> int:
	for i in range(planets.size()):
		if planets[i] == planet_node:
			return i
	return -1

# Reset all orbits to default material
func reset_all_orbits():
	for orbit_circle in orbit_circles:
		orbit_circle.material_override = orbit_material
	active_planet_index = -1

# Alternative: If you want to highlight by planet reference instead of index
func highlight_orbit_by_planet(planet: Planet):
	var planet_index = find_planet_index(planet)
	if planet_index != -1:
		highlight_orbit_animated(planet_index)
		
func highlight_orbit(planet_index: int):
	if planet_index in planet_orbit_map:
		var orbit_circle = planet_orbit_map[planet_index]
		orbit_circle.material_override = orbit_material_highlighted
		active_planet_index = planet_index
		
# Optional: Animated transition version
func highlight_orbit_animated(planet_index: int, duration: float = 0.3):
	if planet_index in planet_orbit_map:
		var orbit_circle = planet_orbit_map[planet_index]
		active_planet_index = planet_index
		
		# Create a material to animate
		var animated_material = orbit_material.duplicate()
		orbit_circle.material_override = animated_material
		
		# Animate to selected state
		var tween = create_tween()
		tween.set_parallel(true)
		
		tween.tween_method(
			func(color: Color): animated_material.albedo_color = color,
			orbit_material.albedo_color,
			orbit_material_highlighted.albedo_color,
			duration
		)
		
		tween.tween_method(
			func(emission: Color): animated_material.emission = emission,
			orbit_material.emission,
			orbit_material_highlighted.emission,
			duration
		)
