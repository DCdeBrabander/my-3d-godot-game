@tool

extends Node3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

@export var MIN_RADIUS := 30
@export var MAX_RADIUS := 100

func _ready():
	#set_color(Color.YELLOW)
	position = Vector3(0, 0, 0)
	#set_size()

func set_color(color: Color):
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission = color
	mesh_instance.material_override = mat
	
func set_size() -> void:
	var radius = randf_range(MIN_RADIUS, MAX_RADIUS)
	
	# Create a new sphere mesh
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 1.0
	sphere_mesh.radial_segments = 32  # smoother sphere (optional)
	sphere_mesh.rings = 16  # more vertical segments (optional)

	sphere_mesh.radius = Vector3.ONE * radius
	#mesh_instance.height = radius
	
	mesh_instance.mesh = sphere_mesh
	pass
