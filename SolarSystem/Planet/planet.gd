@tool

# Planet is an "Abstract Class" 
# and are extended by Rocky, Ice, Gas, .... planets
class_name Planet extends Node3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var body: StaticBody3D = $StaticBody3D

@onready var body_outline: ShaderMaterial
@onready var has_focus: bool = false

@export var orbit_speed: float = 0.1  # Radians per second
@export var orbit_center_node: Node3D

var rotate_around := Vector3.ZERO

var _planet_name: String = ""
@export var planet_name: String:
	get: return _planet_name
	set(value): _planet_name = value

var _planet_index: int = 1
@export var planet_index: int:
	get: return _planet_index
	set(value): _planet_index = value

var _orbit_angle: float = 0.0
@export var orbit_angle: float:
	get: return _orbit_angle
	set(value): _orbit_angle = value
	
var _orbit_radius: float = 10.0
@export var orbit_radius: float:
	get: return _orbit_radius
	set(value): _orbit_radius = value

func _enter_tree() -> void:
	Signalbus.connect("node_selected", _on_entity_selected)
	Signalbus.connect("node_deselected", _on_entity_deselected);

func _exit_tree() -> void:
	Signalbus.disconnect("node_selected", _on_entity_selected)
	Signalbus.disconnect("node_deselected", _on_entity_deselected);
	
func _on_static_body_3d_mouse_entered() -> void:
	_on_mouse_over(true)

func _on_static_body_3d_mouse_exited() -> void:
	_on_mouse_over(false)

func _ready() -> void:
	planet_name = Utils.generate_planet_name()
	body_outline = mesh_instance.get_active_material(0).next_pass as ShaderMaterial
	
	body.set_meta("owner_node", self)
	add_to_group("hoverable")
	add_to_group("clickable")
	
	planet_type_setup()
	
	#print(position, ", ", orbit_radius, ", ", orbit_angle)
	print("Planet '%s' is ready" % planet_name)
	
func _process(delta: float):
	if orbit_center_node == null: 
		return
#
	orbit_angle += orbit_speed * delta
	var x = orbit_radius * cos(orbit_angle)
	var z = orbit_radius * sin(orbit_angle)
	
	# Set position relative to orbit center
	global_position = orbit_center_node.global_position + Vector3(x, 0, z)
	
func _on_mouse_over(state: bool):
	if has_focus: return
	show_outline(state)

func show_outline(state: bool) -> void:
	if state: fade_outline(1.0)
	else: fade_outline(0.0)

func set_center(position: Vector3) -> void:
	rotate_around = position

# Some entity has been selected, check if its this node
# TODO: maybe we dont need to subscribe to event listener for ALL entities. (refactor in future)
func _on_entity_selected(node: Node):
	print('planet._on_entity_selected')
	var selected = node == self
	has_focus = selected
	show_outline(selected)

func _on_entity_deselected(node: Node):
	print('planet._on_entity_deselected')
	var deselected = node == self
	has_focus = deselected
	show_outline(deselected)

func fade_outline(to_value: float, duration := 0.2):
	if body_outline.get_shader_parameter("outline_strength") == to_value:
		return
		
	var tween := get_tree().create_tween()
	tween.tween_property(body_outline, "shader_parameter/outline_strength", to_value, duration)

# Simple defnitions, these are overridden in child-planets.
func planet_type_setup():
	self.setup_type_surface()
	self.setup_type_size()
	
func setup_type_surface(): pass

func setup_type_size():
	var collision_shape = find_child("CollisionShape3D", true, false)
	var radius: float = Utils.pick_from_range_with_bias(
		self.RADIUS_RANGE
	)
		
	if mesh_instance and mesh_instance.mesh is SphereMesh:
		var sphere := mesh_instance.mesh as SphereMesh
		sphere.radius = radius
		sphere.height = radius * 2.0
		
		if collision_shape and collision_shape.shape is SphereShape3D:
			var collision_sphere := collision_shape.shape as SphereShape3D
			collision_sphere.radius = sphere.height * 1.25
