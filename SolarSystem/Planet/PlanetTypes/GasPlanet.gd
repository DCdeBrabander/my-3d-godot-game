@tool
class_name GasPlanet extends Planet

const RADIUS_RANGE = Vector2(6.0, 15.0)

func setup_type_surface():
	if not mesh_instance or not mesh_instance.get_active_material(0): return
	
	var material = mesh_instance.get_active_material(0) as StandardMaterial3D
	
	if material:
		material.albedo_color = Color.STEEL_BLUE
