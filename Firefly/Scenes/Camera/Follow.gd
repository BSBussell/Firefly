extends State

@export var IDLE: State
@export var LOOKAHEAD: State


@export var timer: Timer

@onready var cursor = $"../../Cursor"


## Hold a reference to the parent so that it can be controlled by the state
var control: PlayerCam

# Called on state entrance, setup
func enter() -> void:
	
	timer.start()
	# Cast the parent to a playercam
	control = parent as PlayerCam
	
	
	cursor.material.set_shader_parameter("greenVal", 0.0)
	pass

# Called before exiting the state, cleanup
func exit() -> void:
	
	cursor.material.set_shader_parameter("greenVal", 1.0)
	pass

# Processing Frames in this state, returns nil or new state
func process_frame(delta: float) -> State:
	
	# Only one of these will be called
	move_cursor(delta)
	return check_state(control.Player)

# Processing Physics in this state, returns nil or new state
func process_physics(delta: float) -> State:
	
	# Only one of these will be called
	move_cursor(delta)
	return check_state(control.Player)
	
func move_cursor(delta):
	
	# Our Center / Starting Position
	var target_position = control.Player.global_position - control.startingPos
	
	# The vector we are basing everything off of
	var velocity = control.Player.velocity
	control.smoothed_velocity = control.smoothed_velocity.lerp(velocity, delta * control.velocity_smoothing)
	
	# Smoothly move the marker towards the target position
	control.actual_cam_pos.x = _gerblesh.lerpi(control.actual_cam_pos.x, target_position.x, control.smoothing * delta)
	control.actual_cam_pos.y = _gerblesh.lerpi(control.actual_cam_pos.y, target_position.y, control.smoothing * delta)
	
	# Set the global position to a rounded position of the actual cam
	control.global_position = control.actual_cam_pos.round()
			
	# BTW spent the day debugging this code trying to fix it just to find
	# Someone on github be like "yeah doing this makes it work btw"
	control.camera_2d.align()
	
	
func check_state(player):
	
	# Have to be in follow for X amount of time before can exit
	#if timer.time_left == 0:
		#if player.velocity.length() >= 100 and not player.wallJumping:
			#return LOOKAHEAD
			
	
	if player.velocity.length() == 0:
		return IDLE
	return null
	
	
