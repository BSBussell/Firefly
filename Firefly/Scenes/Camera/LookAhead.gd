extends State

@export var FOLLOW: State

@onready var cursor = $"../../Cursor"


## Hold a reference to the parent so that it can be controlled by the state
var control: PlayerCam

# Called on state entrance, setup
func enter() -> void:
	
	# Make cursor Teal
	cursor.material.set_shader_parameter("redVal", 0)
	
	# Cast the parent to a playercam
	control = parent as PlayerCam
	pass

# Called before exiting the state, cleanup
func exit() -> void:
	
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
	control.smoothed_velocity = control.smoothed_velocity.lerp(velocity, delta * control.velocity_smoothing)
	
	# This is how far we will offset from our center
	var offset: Vector2 = Vector2.ZERO
	





	var offset_triggered = false

	if has_escape_margin(Player) or abs(control.smoothed_velocity.x) > control.horizontal_deadzone:
		offset.x = control.smoothed_velocity.x * control.horizontal_strength
		offset_triggered = true

	if has_escape_margin(Player) or abs(control.smoothed_velocity.y) > control.vertical_deadzone:
		offset.y = control.smoothed_velocity.y * control.vertical_strength
		offset_triggered = true

	if not offset_triggered:
		offset = control.prevOffset
		target_position = control.prevBase

		
	# Check if turning around, by checking if velocity
	#if (offset.x)s

	
		
	
	# Ensure we aren't further than the max offset
	#if offset.length() > control.max_offset:
		# Get the normalized value
	offset = offset.normalized()
		
		# Set the length to now be the max offset
	offset *= control.max_offset
	
	
	control.prevOffset = offset
	control.prevBase = target_position
		
	# Add our offset to the target position
	target_position += offset
	
	
	
	# Smoothly move the marker towards the target position
	control.actual_cam_pos.x = _gerblesh.lerpi(control.actual_cam_pos.x, target_position.x, control.smoothing * delta)
	control.actual_cam_pos.y = _gerblesh.lerpi(control.actual_cam_pos.y, target_position.y, control.smoothing * delta)
	
	
	
	# Set the global position to a rounded position of the actual cam
	control.global_position = control.actual_cam_pos.round()
			
	# BTW spent the day debugging this code trying to fix it just to find
	# Someone on github be like "yeah doing this makes it work btw"
	control.camera_2d.align()
	
	
func has_escape_margin(Player):
	var player_pos = Player.global_position
	var camera_pos = control.camera_2d.global_position
	var camera_size = Vector2(320, 180)
	
	
	var left_margin = camera_pos.x - control.camera_2d.drag_left_margin * camera_size.x / 2
	var right_margin = camera_pos.x + control.camera_2d.drag_right_margin * camera_size.x / 2
	var top_margin = camera_pos.y - control.camera_2d.drag_top_margin * camera_size.y / 2
	var bottom_margin = camera_pos.y + control.camera_2d.drag_bottom_margin * camera_size.y / 2

	return player_pos.x < left_margin || player_pos.x > right_margin || player_pos.y < top_margin || player_pos.y > bottom_margin

	
	
	
func check_state(player):
	
	if player.velocity.length() < 80 or player.wallJumping:
		return FOLLOW
	return null
