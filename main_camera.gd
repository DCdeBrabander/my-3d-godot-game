extends Camera3D

var rotation_speed = 0.005
var zoom_speed = 2.0
var lerp_speed = 3.0

var current_hover_node: Node
var current_active_node: Node

var min_zoom = 5.0
var max_zoom = 100.0

# Add rotation constraints
var min_pitch = -80.0  # degrees
var max_pitch = 80.0   # degrees

# Track rotation separately
var yaw = 0.0
var pitch = 0.0
var zoom_distance = 50.0

var orbit_center := Vector3.ZERO  # Current center position we're orbiting
var target_orbit_center := Vector3.ZERO  # Where we want the center to be
var current_orbit_target: Node3D = null  # The actual object we're following (if any)

func _ready():
	# Zoom the camera back on Z axis (common for perspective)
	transform.origin = Vector3(0, 10, 50)  # (X, Y, Z)
	
	# Optional: look at the center of the scene
	look_at(Vector3.ZERO, Vector3.UP)

	# Set initial position
	zoom_distance = 50.0
	_update_camera_position()

func _process(delta):
	# If we're supposed to be somewhere else, smoothly move there
	if orbit_center != target_orbit_center:
		orbit_center = orbit_center.lerp(target_orbit_center, lerp_speed * delta)
	
		_update_camera_position()  # Update camera with new center

func _update_camera_position():
	# Convert to radians and apply rotations
	var yaw_rad = deg_to_rad(yaw)
	var pitch_rad = deg_to_rad(pitch)
	
	# Calculate position based on spherical coordinates
	var x = zoom_distance * cos(pitch_rad) * sin(yaw_rad)
	var y = zoom_distance * sin(pitch_rad)
	var z = zoom_distance * cos(pitch_rad) * cos(yaw_rad)
	
	#transform.origin = Vector3(x, y, z)
	#look_at(Vector3.ZERO, Vector3.UP)
	transform.origin = Vector3(x, y, z) + orbit_center  # Add orbit_center offset
	look_at(orbit_center, Vector3.UP)  # Look at orbit_center instead of zero

func _unhandled_input(event: InputEvent) -> void:
	# When mouse is moving inside camera/viewport we want to
	# 1. check if we are hovering objects
	# 2. pan the viewport if we are also pressing right mouse button
	if event is InputEventMouseMotion:
		_check_hover(event.position)
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			move_on_mouse_right_click(event)
	
	# When any mouse button clicks are registered we want to 
	# 1. zoom if scroll-button is being used
	# 2. check if we are clicking on any object
	elif event is InputEventMouseButton:
		zoom_on_mouse_scroll(event)
			
		if event.button_index == MOUSE_BUTTON_LEFT:
			_check_click(event.position)
	
	# When keyboard presses are registered 
	# we want to check if we should move the camera
	elif event is InputEventKey and event.pressed: move_on_key_press(event)

func move_on_key_press(event: InputEventKey):
	var move_amount := 1.0
	match event.keycode:
		KEY_W: translate(Vector3(0, move_amount, 0))
		KEY_S: translate(Vector3(0, -move_amount, 0))
		KEY_A: translate(Vector3(-move_amount, 0, 0))
		KEY_D: translate(Vector3(move_amount, 0, 0))
		
func zoom_on_mouse_scroll(event: InputEventMouseButton):
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		zoom_distance = clamp(zoom_distance - zoom_speed, min_zoom, max_zoom)
		_update_camera_position()
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		zoom_distance = clamp(zoom_distance + zoom_speed, min_zoom, max_zoom)
		_update_camera_position()
		
func move_on_mouse_right_click(event: InputEventMouseMotion):
	yaw += rad_to_deg(event.relative.x * rotation_speed)
	pitch -= rad_to_deg(event.relative.y * rotation_speed)
	pitch = clamp(pitch, min_pitch, max_pitch)
	_update_camera_position()

func _check_hover(mouse_pos: Vector2) -> void:
	var raycast_object = _raycast(mouse_pos)
	
	if raycast_object:
		var hovered_object = _get_parent_node(raycast_object.collider)

		if hovered_object.is_in_group("hoverable") and hovered_object.has_method("_on_mouse_over"):
			hovered_object.call_deferred("_on_mouse_over", true)
			
		current_hover_node = hovered_object
		return
	
	if current_hover_node:
		current_hover_node.call_deferred("_on_mouse_over", false)
		current_hover_node = null

func _check_click(mouse_pos: Vector2):
	# Cast a ray from mouse position 'forward' into the scene (under the mouse)
	var result = _raycast(mouse_pos)
	
	if result:
		var clicked_object = result.collider
		var clicked_node = _get_parent_node(clicked_object)

		# Node seems newly clicked, so make it active
		if current_active_node and current_active_node != clicked_node: 
			current_active_node.call_deferred("set_active", false)

		# If node is registered inside clickable group, send event to it
		if clicked_node.is_in_group("clickable"):
			Signalbus.node_selected.emit(clicked_node)
			
		current_active_node = clicked_node
		set_new_orbit_center(current_active_node.global_position)
		return
	
	# If nothing is clicked but something is active, deactivate it.
	@warning_ignore("standalone_expression")
	current_active_node and current_active_node.call_deferred("set_active", false)
	
func set_new_orbit_center(new_position: Vector3):
	target_orbit_center = new_position
	
	# The _process() function will handle the smooth transition
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
