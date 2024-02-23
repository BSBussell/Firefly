extends State

@export var FOLLOW: State

@export var idle_Margin: Vector4 = Vector4(0.3, 0.3, 0.3, 0.3)


## Hold a reference to the parent so that it can be controlled by the state
var control: PlayerCam

# Called on state entrance, setup
func enter() -> void:
	
	# Cast the parent to a playercam
	control = parent as PlayerCam
	pass

# Called before exiting the state, cleanup
func exit() -> void:
	pass

# Processing Frames in this state, returns nil or new state
func process_frame(delta: float) -> State:
	
	# Only one of these will be called
	return check_state(control.Player)

# Processing Physics in this state, returns nil or new state
func process_physics(delta: float) -> State:
	
	# Only one of these will be called
	return check_state(control.Player)
	

func check_state(Player) -> State:
	
	if has_escape_margin(Player):
		return FOLLOW
	
	return null
	
	
func has_escape_margin(Player):
	var player_pos = Player.global_position
	var camera_pos = control.camera_2d.global_position
	var camera_size = Vector2(320, 180)
	
	
	var left_margin = camera_pos.x - idle_Margin.x * camera_size.x / 2
	var right_margin = camera_pos.x + idle_Margin.y * camera_size.x / 2
	var top_margin = camera_pos.y - idle_Margin.z * camera_size.y / 2
	var bottom_margin = camera_pos.y + idle_Margin.w * camera_size.y / 2

	return player_pos.x < left_margin || player_pos.x > right_margin || player_pos.y < top_margin || player_pos.y > bottom_margin

	
	

	

