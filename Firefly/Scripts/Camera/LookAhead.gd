extends State

@export_category("Look Ahead State")
@export_group("Transition States")
@export var FOLLOW: State
@export var IDLE: State
@export var FALLING: State

@export_group("Parameters")
@export var Max_Distance: int = 80
@export var speed: float = 5
@export var acceleration: float = 0.1

@export var offset_smoothing: float = 0.5

@export var horizontal_weight: float = 2
@export var vertical_weight: float = 0.2

@onready var cursor = $"../../Cursor"

var offset: Vector2 = Vector2.ZERO

## Hold a reference to the parent so that it can be controlled by the state
var control: PlayerCam

# Called on state entrance, setup
func enter() -> void:
	
	# Make cursor Teal
	if cursor.visible:
		cursor.material.set_shader_parameter("redVal", 0)
	
	offset = Vector2.ZERO
	
	
	# Cast the parent to a playercam
	control = parent as PlayerCam
	pass

# Called before exiting the state, cleanup
func exit() -> void:
	
	# For debuggins lol
	if cursor.visible:
		cursor.material.set_shader_parameter("redVal", 1)
	pass

# Processing Frames in this state, returns nil or new state
func process_frame(delta: float) -> State:
	
	# Only one of these will be called
	move_cursor(delta, control.Player)
	return check_state(control.Player)

# Processing Physics in this state, returns nil or new state
func process_physics(delta: float) -> State:
	
	# Only one of these will be called
	move_cursor(delta, control.Player)
	return check_state(control.Player)
	

	
func move_cursor(delta, Player):
	
	# Our Center / Starting Position
	var target_position = Player.global_position - control.startingPos
	
	# The vector we are basing everything off of
	var velocity = Player.velocity
	
	# This is how far we will offset from our center
	
	
	# Since we are in lookahead mode we always want the camera to be setting an offset instead of sitting still
	#offset.x = control.smoothed_velocity.x * horizontal_weight
	#offset.y = control.smoothed_velocity.y * vertical_weight
	
	# Gradually increase the lookahead offset
	var desired_offset = Vector2(velocity.x * horizontal_weight, velocity.y * vertical_weight)
	offset = offset.lerp(desired_offset, delta * offset_smoothing)

	
	
	# Ensure we aren't further than the max offset
	if offset.length() > Max_Distance:
		# Get the normalized value then set the length to max_offset
		offset = offset.normalized() * Max_Distance
			
	# Add our offset to the target position
	target_position += offset
	

	# Calculate dynamic speed based on distance, starting at the follow cam's speed and accelerating to a max speed
	# var distance_to_target = (target_position - control.actual_cam_pos).length()
	# control.camera_speed = min(control.camera_speed + distance_to_target * acceleration, speed)
	
	# Calculate dynamic speed based on distance, starting at the follow cam's speed and accelerating to a max speed
	var distance_to_target = (target_position - control.actual_cam_pos).length()
	var speed_factor = clamp(distance_to_target / Max_Distance, 0, 1)  # Normalize the factor between 0 and 1
	control.camera_speed = lerp(control.camera_speed, speed, speed_factor)  # Ease-in function for speed
	
	# Smoothly move the marker towards the target position
	var blend = 1 - pow(0.5, control.camera_speed * delta)
	control.actual_cam_pos.x = _gerblesh.lerpi(control.actual_cam_pos.x, target_position.x, blend)
	control.actual_cam_pos.y = _gerblesh.lerpi(control.actual_cam_pos.y, target_position.y, blend)
	
	# Set the global position to a rounded position of the actual cam
	control.global_position = control.actual_cam_pos.round()
			
	# BTW spent the day debugging this code trying to fix it just to find
	# Someone on github be like "yeah doing this makes it work btw"
	control.camera_2d.align()
	
	
func check_state(player):
	
	# If player is falling lets show the ground below
	if player.velocity.y > control.fallingThres:
		return FALLING
	
	#if player.velocity.length() == 0:
		#return IDLE
	
	if (player.velocity.length() < 100 or player.wallJumping and not player.turningAround) or player.dying:
		control.camera_speed = FOLLOW.Minimum_Speed
		return FOLLOW
	return null
