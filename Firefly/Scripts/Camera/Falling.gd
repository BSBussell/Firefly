extends State

# For when the player is falling
@export_category("Falling State")
@export_group("Transition States")
@export var IDLE: State
@export var FOLLOW: State
@export var LOOKAHEAD: State


@export_group("Parameters")
@export var Cursor_Color: Color
@export var Maximum_Speed: float = 5
@export var Minimum_Speed: float = 5
@export var acceleration: float = 0.1
@export var offset_speed: float = 15
@export var offset_pos: float = -50

@onready var cursor = $"../../Cursor"
@onready var camera_2d = $"../../Camera2D"

var follow_speed: float = 0



## Hold a reference to the parent so that it can be controlled by the state
var control: PlayerCam

# Called on state entrance, setup
func enter() -> void:
	
	#camera_2d.offset.y = -15
	
	# Cast the parent to a playercam
	control = parent as PlayerCam
	
	if cursor.visible:
		cursor.modulate = Cursor_Color
	pass

# Called before exiting the state, cleanup
func exit() -> void:
	
	#camera_2d.offset.y = -35
	
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


	# Camera speed increases the longer it goes, just trying things, helps to ease in
	control.camera_speed = min(Maximum_Speed, control.camera_speed + acceleration)

	# Smoothly move the marker towards the target position
	var blend = 1 - pow(0.5, control.camera_speed * delta)
	control.actual_cam_pos.x = _gerblesh.lerpi(control.actual_cam_pos.x, target_position.x, blend)
	control.actual_cam_pos.y = _gerblesh.lerpi(control.actual_cam_pos.y, target_position.y, blend)
	
	# Set the global position to a rounded position of the actual cam
	control.global_position = control.actual_cam_pos.round()

	# Align the Camera2D node
	control.camera_2d.align()
	

	

func check_state(player):
	
	# IDLE once ground is hit
	if player.velocity.y == 0:
		#if player.velocity.length() >= 100 and not player.current_wj == player.WALLJUMPS.UPWARD:
			#return LOOKAHEAD
		return FOLLOW
			
			
	
	
	#if control.Player.velocity.length() == 0:
		#return IDLE
	
	return null
	
	
