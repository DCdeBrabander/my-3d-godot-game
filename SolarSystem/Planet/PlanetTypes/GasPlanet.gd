@tool
class_name GasPlanet extends Planet

const RADIUS_RANGE = Vector2(6.0, 15.0)

func _setup_type_surface():
	if mesh_instance and mesh_instance.get_active_material(0):
		var material = mesh_instance.get_active_material(0) as StandardMaterial3D
		if material:
			material.albedo_color = Color.STEEL_BLUE
