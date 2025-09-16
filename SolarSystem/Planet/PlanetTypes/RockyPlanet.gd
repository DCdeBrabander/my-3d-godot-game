@tool 
class_name RockyPlanet extends Planet

const RADIUS_RANGE = Vector2(0.5, 1.8)

func setup_type_surface():
	if mesh_instance and mesh_instance.get_active_material(0):
		var material = mesh_instance.get_active_material(0) as StandardMaterial3D
		if material:
			material.albedo_color = Color.SADDLE_BROWN
