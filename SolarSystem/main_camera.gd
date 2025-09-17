extends Camera3D

var target_yaw: float = 0.0
var target_pitch: float = 20.0
var rotation_lerp_speed: float = 50.0
var rotation_amount := 45.0  # degrees to rotate

@export var rotation_speed = 0.005
@export var lerp_speed = 3.0

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
	current_zoom_distance = 500
	pitch = 20.0
	target_pitch = 20.0
	yaw = 0.0
	target_yaw = 0.0
	update_camera_position()

func _process(delta: float) -> void:
	animate_to_focus_position(delta)
	animate_rotation(delta)
	update_camera_position()
	
func _unhandled_input(input_event: InputEvent) -> void:
	# When mouse is moving inside camera/viewport we want to
	# 1. check if we are hovering objects
	# 2. pan the viewport if we are also pressing right mouse button
	if input_event is InputEventMouseMotion:
		check_hover(input_event.position)
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			move_on_mouse_right_click(input_event)
	
	# When any mouse button clicks are registered we want to 
	# 1. zoom if scroll-button is being used
	# 2. check if we are clicking on any object
	elif input_event is InputEventMouseButton:
		zoom_on_mouse_scroll(input_event)
			
		if input_event.button_index == MOUSE_BUTTON_LEFT:
			check_click(input_event.position)
	
	# When keyboard presses are registered 
	# we want to check if we should move the camera
	elif input_event is InputEventKey and input_event.pressed: move_on_key_press(input_event)
	
func _get_parent_node(object: Node) -> Node:
	if object.has_meta("owner_node"):
		return object.get_meta("owner_node")
	
	# TODO: maybe we want to implement get_parent() directly later on?
	
	return object
	
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

# TODO: abstract key listener to probably outside camera and use events to hook into (because HUD and stuff)
func move_on_key_press(event: InputEventKey):
	var move_amount := 50.0
	var move_vector := Vector3.ZERO
	
	match event.keycode:
		KEY_W: move_vector = -transform.basis.z  # Camera forward
		KEY_S: move_vector = transform.basis.z   # Camera backward
		KEY_A: move_vector = -transform.basis.x  # Camera left  
		KEY_D: move_vector = transform.basis.x   # Camera right
		KEY_Q: target_yaw = normalize_angle(target_yaw - rotation_amount)     # Rotate left (animated)
		KEY_E: target_yaw = normalize_angle(target_yaw + rotation_amount)    # Rotate right (animated)Rotate right
		KEY_ESCAPE: stop_following()
	
	if move_vector != Vector3.ZERO:
		target_focus += move_vector * move_amount
		manual_focus = true  # Stop following any target
		
func zoom_on_mouse_scroll(event: InputEventMouseButton):
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		current_zoom_distance = clamp(current_zoom_distance - zoom_speed, min_zoom, max_zoom)
		update_camera_position()
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		current_zoom_distance = clamp(current_zoom_distance + zoom_speed, min_zoom, max_zoom)
		update_camera_position()
		
func move_on_mouse_right_click(event: InputEventMouseMotion):
	target_yaw += rad_to_deg(event.relative.x * rotation_speed)
	target_pitch -= rad_to_deg(event.relative.y * rotation_speed)
	target_pitch = clamp(target_pitch, min_pitch, max_pitch)
	
	# For mouse, we want immediate response, so set current values too
	yaw = target_yaw
	pitch = target_pitch

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
		print("RESULT")
		var clicked_object = result.collider
		var clicked_node = _get_parent_node(clicked_object)

		# Node seems newly clicked, so make it active
		# If node is registered inside clickable group, send event to it
		if current_active_node != clicked_node and clicked_node.is_in_group("clickable"):
			Signalbus.node_selected.emit(clicked_node)
			
		current_active_node = clicked_node
		
		if clicked_node is Node3D: set_follow_target(clicked_node)
		return
	
	# If nothing is clicked but something is active, deactivate it.
	print("NO RESULT")
	
func update_focus_position(new_position: Vector3):
	target_focus = new_position

# Much cleaner animate_rotation function
func animate_rotation(delta: float) -> void:
	var yaw_rad = lerp_angle(deg_to_rad(yaw), deg_to_rad(target_yaw), rotation_lerp_speed * delta)
	var pitch_rad = lerp_angle(deg_to_rad(pitch), deg_to_rad(target_pitch), rotation_lerp_speed * delta)
	
	yaw = rad_to_deg(yaw_rad)
	pitch = rad_to_deg(pitch_rad)
	
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


func set_follow_target(target_node: Node3D):
	node_to_follow = target_node
	manual_focus = false
	if target_node: target_focus = target_node.global_position

func stop_following():
	# TODO: We should move this to other event handlers in the future, 
	#       probably into more UI/HUD related class
	Signalbus.node_deselected.emit(node_to_follow)
	node_to_follow = null
	manual_focus = false

func normalize_angle(angle: float) -> float:
	while angle > 180.0:
		angle -= 360.0
	while angle < -180.0:
		angle += 360.0
	return angle
