class_name IcePlanet extends Planet

func setup_planet_type():
	# Set ice planet color
	if mesh_instance and mesh_instance.get_active_material(0):
		var material = mesh_instance.get_active_material(0) as StandardMaterial3D
		if material:
			material.albedo_color = Color.LIGHT_CYAN
