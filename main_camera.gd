extends Camera3D

var rotation_speed = 0.005
var zoom_speed = 2.0

var current_hover_node: Node
var current_active_node: Node

func _ready():
	# Zoom the camera back on Z axis (common for perspective)
	transform.origin = Vector3(0, 10, 50)  # (X, Y, Z)

	# Optional: look at the center of the scene
	look_at(Vector3.ZERO, Vector3.UP)
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_check_hover(event.position)
		
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			rotate_y(-event.relative.x * rotation_speed)
			rotate_x(-event.relative.y * rotation_speed)

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			translate(Vector3(0, 0, -zoom_speed))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			translate(Vector3(0, 0, zoom_speed))
			
		if event.button_index == MOUSE_BUTTON_LEFT:
			_check_click(event.position)
	
	elif event is InputEventKey and event.pressed:
		var move_amount := 1.0
		match event.keycode:
			KEY_W: translate(Vector3(0, move_amount, 0))
			KEY_S: translate(Vector3(0, -move_amount, 0))
			KEY_A: translate(Vector3(-move_amount, 0, 0))
			KEY_D: translate(Vector3(move_amount, 0, 0))

func _check_hover(mouse_pos: Vector2) -> void:
	var raycast_object = _raycast(mouse_pos)
	
	if raycast_object:
		var hovered_object = _get_parent_node(raycast_object.collider)
		
		#if current_hover_node and current_hover_node != hovered_object: 
			#current_hover_node.call_deferred("set_mouse_over", false)

		if hovered_object.is_in_group("hoverable") and hovered_object.has_method("set_mouse_over"):
			hovered_object.call_deferred("set_mouse_over", true)
			
		current_hover_node = hovered_object
		return
	
	if current_hover_node:
		current_hover_node.call_deferred("set_mouse_over", false)
		current_hover_node = null

func _check_click(mouse_pos: Vector2):
	var result = _raycast(mouse_pos)
	if result:
		var clicked = result.collider
		var object = _get_parent_node(clicked)

		if current_active_node and current_active_node != object: 
			current_active_node.call_deferred("set_active", false)

		if object.is_in_group("clickable") and object.has_method("set_active"):
			object.call_deferred("set_active", true)
			
		current_active_node = object
		return
		
	current_active_node and current_active_node.call_deferred("set_active", false)	

func _raycast(mouse_pos: Vector2) -> Dictionary:
	var from = project_ray_origin(mouse_pos)
	var to = from + project_ray_normal(mouse_pos) * 1000
	var space_state = get_world_3d().direct_space_state
	return space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))

func _get_parent_node(object: Node) -> Node:
	if object.has_meta("owner_node"):
		return object.get_meta("owner_node")
	
	# maybe we want to implement get_parent() directly later on
	
	return object
