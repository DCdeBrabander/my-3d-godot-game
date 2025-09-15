extends Camera3D

var rotation_speed = 0.005
var lerp_speed = 3.0

var current_hover_node: Node
var current_active_node: Node

var zoom_speed = 50.0
var min_zoom = 5.0
var max_zoom = 10000.0
var current_zoom_distance = 1000.0

# Add rotation constraints
var min_pitch = -80.0  # degrees
var max_pitch = 80.0   # degrees

# Track rotation separately
var yaw = 0.0
var pitch = 0.0

var current_focus := Vector3.ZERO
var target_focus := Vector3.ZERO
var node_to_follow: Node3D = null
var manual_focus = false
 
# Follow modes
enum FollowMode {
	NONE,           # Free camera
	ORBIT,          # Orbit around target
	CHASE,          # Follow behind target
	FIXED_OFFSET    # Maintain fixed offset from target
}

var follow_mode: FollowMode = FollowMode.NONE
var follow_offset := Vector3.ZERO 	# For FIXED_OFFSET mode
var follow_distance := 50.0 		# For CHASE mode

func _ready():
	# Zoom the camera back on Z axis (common for perspective)
	# and set initial position
	#transform.origin = Vector3(0, 100000, 5000)  # (X, Y, Z)
	
	current_zoom_distance = 500
	pitch = 20.0
	
	update_camera_position()

func _process(delta: float) -> void:
	animate_to_focus_position(delta)
	update_camera_position()
	
func _unhandled_input(event: InputEvent) -> void:
	# When mouse is moving inside camera/viewport we want to
	# 1. check if we are hovering objects
	# 2. pan the viewport if we are also pressing right mouse button
	if event is InputEventMouseMotion:
		check_hover(event.position)
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			move_on_mouse_right_click(event)
	
	# When any mouse button clicks are registered we want to 
	# 1. zoom if scroll-button is being used
	# 2. check if we are clicking on any object
	elif event is InputEventMouseButton:
		zoom_on_mouse_scroll(event)
			
		if event.button_index == MOUSE_BUTTON_LEFT:
			check_click(event.position)
	
	# When keyboard presses are registered 
	# we want to check if we should move the camera
	elif event is InputEventKey and event.pressed: move_on_key_press(event)

func update_camera_position() -> void:
	# Convert to radians and apply rotations
	var yaw_rad = deg_to_rad(yaw)
	var pitch_rad = deg_to_rad(pitch)
	
	# Calculate position based on spherical coordinates
	var x = current_zoom_distance * cos(pitch_rad) * sin(yaw_rad)
	var y = current_zoom_distance * sin(pitch_rad)
	var z = current_zoom_distance * cos(pitch_rad) * cos(yaw_rad)
	
	transform.origin = Vector3(x, y, z) + current_focus  # Add current_focus offset
	look_at(current_focus, Vector3.UP)

func move_on_key_press(event: InputEventKey):
	var move_amount := 1.0
	match event.keycode:
		KEY_W: translate(Vector3(0, move_amount, 0))
		KEY_S: translate(Vector3(0, -move_amount, 0))
		KEY_A: translate(Vector3(-move_amount, 0, 0))
		KEY_D: translate(Vector3(move_amount, 0, 0))
		
func zoom_on_mouse_scroll(event: InputEventMouseButton):
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		current_zoom_distance = clamp(current_zoom_distance - zoom_speed, min_zoom, max_zoom)
		update_camera_position()
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		current_zoom_distance = clamp(current_zoom_distance + zoom_speed, min_zoom, max_zoom)
		update_camera_position()
		
func move_on_mouse_right_click(event: InputEventMouseMotion):
	yaw += rad_to_deg(event.relative.x * rotation_speed)
	pitch -= rad_to_deg(event.relative.y * rotation_speed)
	pitch = clamp(pitch, min_pitch, max_pitch)
	update_camera_position()

func check_hover(mouse_pos: Vector2) -> void:
	var raycast_object = cast_ray_to_pos(mouse_pos)
	
	if raycast_object:
		var hovered_object = _get_parent_node(raycast_object.collider)

		if hovered_object.is_in_group("hoverable") and hovered_object.has_method("_on_mouse_over"):
			hovered_object.call_deferred("_on_mouse_over", true)
			
		current_hover_node = hovered_object
		return
	
	if current_hover_node:
		current_hover_node.call_deferred("_on_mouse_over", false)
		current_hover_node = null

func check_click(mouse_pos: Vector2):
	# Cast a ray from mouse position 'forward' into the scene (under the mouse)
	var result = cast_ray_to_pos(mouse_pos)
	
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
		#update_focus_position(current_active_node.global_position)
		
		if clicked_node is Node3D: set_follow_target(clicked_node)
		return
	
	# If nothing is clicked but something is active, deactivate it.
	@warning_ignore("standalone_expression")
	current_active_node and current_active_node.call_deferred("set_active", false)
	
func update_focus_position(new_position: Vector3):
	target_focus = new_position
	
# The _process() function will handle the smooth transition 
# by giving it the delta
func animate_to_focus_position(delta: float):
	if node_to_follow and not manual_focus:
		target_focus = node_to_follow.global_position
	
	if current_focus.is_equal_approx(target_focus):
		return
		
	current_focus = current_focus.lerp(target_focus, lerp_speed * delta)

func cast_ray_to_pos(mouse_pos: Vector2) -> Dictionary:
	var from = project_ray_origin(mouse_pos)
	var to = from + project_ray_normal(mouse_pos) * 10000000000
	var space_state = get_world_3d().direct_space_state
	return space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))

func _get_parent_node(object: Node) -> Node:
	if object.has_meta("owner_node"):
		return object.get_meta("owner_node")
	
	# maybe we want to implement get_parent() directly later on
	
	return object

func set_follow_target(target: Node3D):
	node_to_follow = target
	manual_focus = false
	if target: target_focus = target.global_position

func stop_following():
	node_to_follow = null
	manual_focus = false
