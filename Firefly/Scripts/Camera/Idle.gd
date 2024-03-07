extends State

@export_category("Idle State")
@export_group("Transition States")
@export var FOLLOW: State

@export_group("Properties")

# The percentage away from screen the player can be without leaving this state
@export var idle_Margin: Vector4 = Vector4(0.3, 0.3, 0.3, 0.3)
@export var mega_Margin: Vector4 = Vector4(0.5, 0.5, 0.5, 0.5)

# How quickly the camera will move to a stop
@export var deceleration_speed: float = 0.5


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
	if control.camera_speed != 0: settle_cam(delta, control.Player)
	return check_state(control.Player)

# Processing Physics in this state, returns nil or new state
func process_physics(delta: float) -> State:
	
	# Only one of these will be called
	if control.camera_speed != 0: settle_cam(delta, control.Player)
	return check_state(control.Player)
	
	
func settle_cam(delta: float, Player: Flyph):
	# Our Center / Starting Position
	var target_position = control.Player.global_position - control.startingPos


	# Camera speed decreases the longer it goes, just trying things, helps to ease in
	control.camera_speed = max(0, control.camera_speed - deceleration_speed)

	# Smoothly move the marker towards the target position
	control.actual_cam_pos.x = _gerblesh.lerpi(control.actual_cam_pos.x, target_position.x, control.camera_speed * delta)
	control.actual_cam_pos.y = _gerblesh.lerpi(control.actual_cam_pos.y, target_position.y, control.camera_speed * delta)

	# Set the global position to a rounded position of the actual cam
	control.global_position = control.actual_cam_pos.round()

	# Align the Camera2D node
	control.camera_2d.align()
	

func check_state(Player) -> State:
	
	if has_escape_margin(Player, idle_Margin) and Player.is_on_floor():
		return FOLLOW
	
	# Even if they're in the air if they get too far we should start following them
	elif has_escape_margin(Player, mega_Margin):
		return FOLLOW
	
	return null
	
	
func has_escape_margin(Player, margin):
	var player_pos = Player.global_position
	var camera_pos = control.camera_2d.global_position
	var camera_size = Vector2(320, 180)
	
	
	var left_margin = camera_pos.x - margin.x * camera_size.x / 2
	var right_margin = camera_pos.x + margin.y * camera_size.x / 2
	var top_margin = camera_pos.y - margin.z * camera_size.y / 2
	var bottom_margin = camera_pos.y + margin.w * camera_size.y / 2

	return player_pos.x < left_margin || player_pos.x > right_margin || player_pos.y < top_margin || player_pos.y > bottom_margin

	
	

	

