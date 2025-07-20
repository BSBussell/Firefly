extends State

# Camera movement parameters
## The color of the camera target when we are in this
@export var Cursor_Color: Color

## The maximum speed the camera will move
@export var Maximum_Speed: Vector2 = Vector2(20, 20)
@export var Minimum_Speed: Vector2 = Vector2(5, 5)

## The default acceleration
@export var BaseAcceleration: Vector2 = Vector2(0.6, 0.6)

@onready var cursor = $"../../Cursor"
@onready var control: PlayerCam 
@onready var player: Flyph




# The acceleratino that's actually used
var accel: Vector2 = Vector2.ZERO

var follow_speed: Vector2 = Vector2.ZERO

var current_target_offset: Vector2 = Vector2.ZERO


func enter() -> void:
	
	
	accel = BaseAcceleration
	follow_speed = Minimum_Speed
	
	control = parent as PlayerCam
	player = control.Player
	
	# Set this as the default base position
	#current_target_position = player.global_position - control.startingPos
	
	if cursor.visible:
		cursor.modulate = Cursor_Color

func exit() -> void:
	pass

func process_frame(delta: float) -> State:
	move_camera(delta)
	return check_state()

func process_physics(delta: float) -> State:
	move_camera(delta)
	return check_state()

func move_camera(delta):
	
	var target_position = calculate_target_position(delta)
	
	
	
	
	
	# Smoothly move the camera towards the target position
	follow_speed.x = move_toward(follow_speed.x, Maximum_Speed.x, accel.x)
	#min(Maximum_Speed.x, follow_speed.x + accel.x)
	follow_speed.y = move_toward(follow_speed.y, Maximum_Speed.y, accel.y)
	#min(Maximum_Speed.y, follow_speed.y + accel.y)
	
	# Calculate Blend
	var blend: Vector2 = Vector2.ZERO
	blend.x = 1 - pow(0.5, follow_speed.x * delta)
	blend.y = 1 - pow(0.5, follow_speed.y * delta)
	
	# Gerblesh
	control.actual_cam_pos.x = _gerblesh.lerpi(control.actual_cam_pos.x, target_position.x, blend.x)	
	control.actual_cam_pos.y = _gerblesh.lerpi(control.actual_cam_pos.y, target_position.y, blend.y)
	
	control.global_position = control.actual_cam_pos.round()
	control.camera_2d.align()


var multi_target_smoothing: float = 0.0
var smoothing_factor_2: float = 0.0
var dict_hash: int = 0
var settled: bool = true
var current_grouping_offset: Vector2 = Vector2.ZERO

func calculate_target_position(delta: float) -> Vector2:
	
	var base_target: Vector2 = player.global_position - control.startingPos	
	var position: Vector2 = base_target
	var offset: Vector2 = Vector2.ZERO
	
	if not player.dying:
		offset = calc_horiz_offset(delta)
		#position += offset
	
	
	# Check if there are any targets to look at
	var targets_center = get_targets_center()
	
	# Check if the list of targets has changed
	var id = control.targets.hash()
	if id != dict_hash:
		
		print("Resetting smoothing")
		dict_hash = id
		smoothing_factor_2 = 0
		cursor.modulate = "#00FFFF";
	else:
		cursor.modulate = Cursor_Color
	
	
	if targets_center != Vector2.ZERO:
		
		
		
		#var targets_offset: Vector2
		var grouping_offset: Vector2
		grouping_offset = get_targets_offset(position, targets_center)
		
		smoothing_factor_2 = move_toward(smoothing_factor_2, 1.0, 0.01)
		
		# Lerp towards this new offset
		current_grouping_offset = _gerblesh.lerpiVec(current_grouping_offset, grouping_offset, smoothing_factor_2)
		#current_grouping_offset = grouping_offset
		
	
		
	
	# Otherwise if we're turning off target tracking
	else:
		
		# Reset the hash
		dict_hash = 0
		
		# Reset the smoothing
		smoothing_factor_2 = move_toward(smoothing_factor_2, 1.0, 0.01)
		
		# Lerp towards our origin
		current_grouping_offset = _gerblesh.lerpiVec(current_grouping_offset, Vector2.ZERO, smoothing_factor_2)
		
		
		
		
		
	if not player.dying:
		#print("DC: Targets Offset", targets_center)
		#print("DC: Grouping Offset: ",current_grouping_offset)
		#print("DC: Position: ", position)
		# I want it to do this normally
		position += current_grouping_offset
		
		for target in control.targets.values():
			if target.target_snap:
				position = targets_center
	
	return position

func calc_horiz_offset(_delta: float) -> Vector2:
	
	# The default offset
	var offset = Vector2.ZERO
	
	## The rate that the current offset will approach our goal offset
	var blend: Vector2 = Vector2(0.1, 0.1)
	
	# Abs the players velocity only once
	var player_speed: Vector2 = abs(player.velocity)
	
	# If moving quickly horizontally (and not when wall jumping)
	if player_speed.x >= player.speed and not player.wallJumping:
		
		# This is player lowest form max speed * 1.5
		var max_horiz_speed: float = 152 * 1.5
		var horiz_offset: float = 30 * sign(player.velocity.x)
		
		# Normalize our blending
		var normed_blend = (player_speed.x - 152) / (max_horiz_speed - 152)
		
		
		# Using lerp to have us approach horiz offset as speed approaches max
		offset.x += lerpf(0, horiz_offset, min(1.0, normed_blend)) 
		
		
		# Slowly move the offset to this
		blend.x = 0.025
		
	
	
	# If we are returning to zero, ease into it
	if current_target_offset != Vector2.ZERO and offset == Vector2.ZERO:
		blend = Vector2(0.05, 0.05)
		
	

	# Move the actual target towards our new calc'd goal
	current_target_offset.x = _gerblesh.lerpi(current_target_offset.x, offset.x, blend.x)
	current_target_offset.y = _gerblesh.lerpi(current_target_offset.y, offset.y, blend.y)
	
	return current_target_offset
	

# Get all on-screen targets and find the weighted center point between them all
func get_targets_center() -> Vector2:
	var weighted_sum = Vector2.ZERO
	var total_pull_strength = 0.0

	for target in control.targets.values():
		weighted_sum += target.global_position * target.pull_strength
		total_pull_strength += target.pull_strength

	if total_pull_strength > 0:
		return weighted_sum / total_pull_strength  # Weighted average position
	else:
		return Vector2.ZERO  # Return a default position if no targets exist


func get_targets_blend() -> float:
	
	var blend: float = 0.3
	var current_priority: int = -1
	
	for target in control.targets.values():
		if current_priority < target.blend_priority:
			current_priority = target.blend_priority
			blend = target.blend_override
			
		
	return blend




func get_targets_offset(base_target: Vector2, targets_center: Vector2) -> Vector2:
	var blend_max = get_targets_blend()
	
	# Update the smoothing factor
	multi_target_smoothing = move_toward(multi_target_smoothing, blend_max, 0.01)
	
	# Smoothly transition the offset towards the new center
	var current_grouping_position: Vector2 = Vector2.ZERO
	current_grouping_position.x = _gerblesh.lerpi(base_target.x, targets_center.x, multi_target_smoothing)
	current_grouping_position.y = _gerblesh.lerpi(base_target.y, targets_center.y, multi_target_smoothing)


	return current_grouping_position - base_target
	


func check_state() -> State:
	
	return null
