extends Node

# Game state
var is_paused: bool = false

# Signals for different input types
signal game_action(action: String)
signal game_paused(paused: bool)

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS # Work even when game is paused
	print("Simple Input Manager ready")
	
# Handle system-wide inputs first
func _input(event: InputEvent):
	_handle_global_inputs(event)
	
# Handle game inputs (only if UI didn't use them)
func _unhandled_input(event: InputEvent):
	_handle_game_inputs(event)

func _handle_global_inputs(event: InputEvent):
	if event.is_action_pressed("pause_game"):
		toggle_pause()
		get_viewport().set_input_as_handled()
	
	if event.is_action_pressed("toggle_fullscreen"):
		toggle_fullscreen()
		get_viewport().set_input_as_handled()

func _handle_game_inputs(event: InputEvent):
	# Spacebar to spawn object
	if event.is_action_pressed("spawn_object"):
		game_action.emit("spawn_object")
	
	# Other game actions
	if event.is_action_pressed("ui_accept"):  # Enter key
		game_action.emit("interact")
	
	if event.is_action_pressed("ui_cancel"):  # Usually ESC, but we use it for pause
		game_action.emit("cancel")

# SYSTEM FUNCTIONS
func toggle_pause():
	is_paused = !is_paused
	get_tree().paused = is_paused
	game_paused.emit(is_paused)
	print("Game paused: ", is_paused)

func toggle_fullscreen():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
