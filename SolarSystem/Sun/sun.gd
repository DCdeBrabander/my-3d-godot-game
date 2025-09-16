@tool

class_name Sun extends Node3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

@export var MIN_RADIUS := 20
@export var MAX_RADIUS := 40

func _ready():
	position = Vector3(0, 0, 0)
		
func set_color(color: Color):
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission = color
	mesh_instance.material_override = mat
	
func set_size() -> void:
	var radius:float = Utils.pick_from_range_with_bias(
		Vector2(MIN_RADIUS, MAX_RADIUS)
	)
		
	if mesh_instance and mesh_instance.mesh is SphereMesh:
		var sphere := mesh_instance.mesh as SphereMesh
		sphere.radius = radius
		sphere.height = radius * 2.0
		#mesh_instance.mesh = sphere
		
func get_radius() -> float:
	if not mesh_instance or not mesh_instance.mesh is SphereMesh:
		return 1.0  # fallback
	
	return mesh_instance.mesh.radius
