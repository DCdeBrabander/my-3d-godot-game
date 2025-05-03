@tool

class_name Planet extends Node3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var body: StaticBody3D = $StaticBody3D

@onready var body_outline: ShaderMaterial
@onready var has_focus: bool = false

@export var MIN_RADIUS := 10
@export var MAX_RADIUS := 30

@export var orbit_radius: float = 10.0
@export var orbit_speed: float = 0.001  # Radians per second
@export var orbit_center_node: Node3D

var angle: float = 0.0
var rotate_around := Vector3.ZERO

var _planet_name: String = ""
@export var planet_name: String:
	get: return _planet_name
	set(value): _planet_name = value

var _planet_index: int = 1
@export var planet_index: int:
	get: return _planet_index
	set(value): _planet_index = value

func _init() -> void:
	Signalbus.node_selected.connect(_on_entity_selected)
	
func _ready() -> void:
	planet_name = Utils.generate_planet_name(randf() < 0.5)
	body_outline = mesh_instance.get_active_material(0).next_pass as ShaderMaterial
	
	orbit_radius = 5.0 + planet_index * 5.0
	orbit_speed = planet_index * 0.1
	
	body.set_meta("owner_node", self)
	add_to_group("hoverable")
	add_to_group("clickable")
		
	print("Planet '%s' is ready" % planet_name)
	
func _process(delta: float):
	if orbit_center_node == null: 
		return
#
	angle += orbit_speed * delta
	var x = orbit_radius * cos(angle)
	var z = orbit_radius * sin(angle)
	
	# Set position relative to orbit center
	global_position = orbit_center_node.global_position + Vector3(x, 0, z)
	
	# Set the position relative to the orbit center node (parent node)
	#position = Vector3(x, 0, z)
	
func _on_mouse_over(state: bool):
	if has_focus: return
	show_outline(state)

func show_outline(state: bool):
	if state: fade_outline(1.0)
	else: fade_outline(0.0)

func set_center(position: Vector3) -> void:
	rotate_around = position

func _on_entity_selected(node: Node):
	var selected = node == self
	has_focus = selected
	show_outline(selected)

func fade_outline(to_value: float, duration := 0.2):
	if body_outline.get_shader_parameter("outline_strength") == to_value:
		return
		
	var tween := get_tree().create_tween()
	tween.tween_property(body_outline, "shader_parameter/outline_strength", to_value, duration)
