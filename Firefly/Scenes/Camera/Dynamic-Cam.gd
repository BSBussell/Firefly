extends State

# Camera movement parameters
## The color of the camera target when we are in this
@export var Cursor_Color: Color

## The maximum speed the camera will move
@export var Maximum_Speed: Vector2 = Vector2(25, 25)
@export var Minimum_Speed: Vector2 = Vector2(5, 5)

## The default acceleration
@export var BaseAcceleration: Vector2 = Vector2(0.75, 0.75)

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
var dict_hash: int = 0.0
var settled: bool = true
func calculate_target_position(delta: float) -> Vector2:
	var base_target: Vector2 = player.global_position - control.startingPos
	var offset: Vector2
	
	if not player.dying:
		offset = calc_target_offset(delta)
		
	var position: Vector2 = base_target + offset
	
	
	
	# Check if there are any targets to look at
	var targets_center = get_targets_center()
	if targets_center != Vector2.ZERO:
		
		# Get our blend max
		var blend_max = get_targets_blend()
		var hash: int = control.targets.hash()
		
		# If the dict has changed
		if hash != dict_hash:
			dict_hash = hash
			settled = false
		
		# Slow down the camera when moving for a new target	
		if not settled:
			follow_speed = Minimum_Speed
			accel = Vector2(0.4, 0.4)
		else:
			accel = BaseAcceleration
			
		# Push the multi_target_smoothing up
		multi_target_smoothing = move_toward(multi_target_smoothing, blend_max, 0.01)
		
		position.x = _gerblesh.lerpi(position.x, targets_center.x, multi_target_smoothing)
		position.y = _gerblesh.lerpi(position.y, targets_center.y, multi_target_smoothing)
		
		
		# Lerp the position x amount towards the center of the targets
		position.lerp(targets_center, multi_target_smoothing)
	
		# If we've reached the blend max we've settled
		if multi_target_smoothing == blend_max and not settled:
			settled = true
			print("Settled Camera")
	
	# Otherwise if we're turning off target tracking
	elif multi_target_smoothing != 0.0:
		
		accel = Vector2(0.5, 0.5)
		
		# Reset the hash
		dict_hash = 0
		# Reset the smoothing
		multi_target_smoothing = 0.0

	return position

func calc_target_offset(_delta: float) -> Vector2:
	
	# The default offset
	var offset = Vector2.ZERO
	
	## The rate that the current offset will approach our goal offset
	var blend: Vector2 = Vector2(0.1, 0.1)
	
	# Abs the players velocity only once
	var player_speed: Vector2 = abs(player.velocity)
	
	## If Aerial
	if not player.is_on_floor():
		
		
			
		# If rising
		if player.velocity.y < 0:
			
			var base_rise_speed = player.jump_velocity * 2
			var up_offset = -128
			
			# Using lerp to have us approach fall offset as speed approaches max
			offset.y += lerp(0, up_offset, min(1.0, player_speed.y / base_rise_speed))
			print(offset.y)
			# Set slowly move the offset back to this
			blend.y = 0.05
		
	# If moving quickly horizontally (and not when wall jumping)
	if player_speed.x >= player.speed and not player.wallJumping:
		
		var max_horiz_speed: float = 152 * 1.5
		var horiz_offset: float = 20 * sign(player.velocity.x)
		
		# Normalize our blending
		var normed_blend = (player_speed.x - player.speed) / (max_horiz_speed - player.speed)
		
		
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

func check_state() -> State:
	
	return null


