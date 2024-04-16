extends State

# Camera movement parameters
@export var Cursor_Color: Color
@export var Maximum_Speed: Vector2 = Vector2(25, 25)
@export var Minimum_Speed: Vector2 = Vector2(5, 5)
@export var BaseAcceleration: Vector2 = Vector2(0.75, 0.75)
@export var FallAccel: Vector2 = Vector2(0.00125, 0.125)

@onready var cursor = $"../../Cursor"
@onready var control: PlayerCam 
@onready var player: Flyph

# The acceleratino that's actually used
var accel: Vector2 = Vector2.ZERO

var follow_speed: Vector2 = Vector2.ZERO

var current_target_position: Vector2 = Vector2.ZERO


func enter() -> void:
	
	
	accel = BaseAcceleration
	follow_speed = Minimum_Speed
	
	control = parent as PlayerCam
	player = control.Player
	
	# Set this as the default base position
	current_target_position = player.global_position - control.startingPos
	
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
	follow_speed.x = min(Maximum_Speed.x, follow_speed.x + accel.x)
	follow_speed.y = min(Maximum_Speed.y, follow_speed.y + accel.y)
	
	# Calculate Blend
	var blend: Vector2 = Vector2.ZERO
	blend.x = 1 - pow(0.5, follow_speed.x * delta)
	blend.y = 1 - pow(0.5, follow_speed.y * delta)
	
	# Gerblesh
	control.actual_cam_pos.x = _gerblesh.lerpi(control.actual_cam_pos.x, target_position.x, blend.x)
	control.actual_cam_pos.y = _gerblesh.lerpi(control.actual_cam_pos.y, target_position.y, blend.y)
	
	control.global_position = control.actual_cam_pos.round()
	control.camera_2d.align()

var adjusted_offset: bool = false
func calculate_target_position(delta: float) -> Vector2:
	var goal_target = player.global_position - control.startingPos
	
	
	# If we've modified accel
	if accel != BaseAcceleration:
		
		# Calculate Blend
		var blend: Vector2 = Vector2.ZERO
		blend.x = 1 - pow(0.5, 1 * delta)
		blend.y = 1 - pow(0.5, 1 * delta)
		
		# Lerp Accel towards base Acceleration
		accel.x = lerp(accel.x, BaseAcceleration.x, 0.1)
		accel.y = lerp(accel.y, BaseAcceleration.y, 0.1)
		print(accel)
		
		
	
	## If airborn
	#if not player.is_on_floor():
		#
		#adjusted_offset = true
		#
		#var max_horiz_speed = player.air_speed * 1.2
		#
		#var horiz_offset = 16
		#var offset_x = lerp(0, horiz_offset, min(1.0, player.velocity.x / max_horiz_speed))
		#
		#goal_target.x += round(offset_x)
		#accel.x = FallAccel.x
	#
		## If falling
		#if player.velocity.y > 0:
			#
			#adjusted_offset = true
			#
			## Use Lerp to make it so that as velocity.y approaches max_fall_speed
			#var max_fall_speed = player.movement_data.MAX_FALL_SPEED
			#
			#var fall_offset = 32
			#var offset_y = lerp(0, fall_offset, min(1.0, player.velocity.y / max_fall_speed))
			#
			#goal_target.y += round(offset_y)
			#accel.y = FallAccel.y
	
	if abs(player.velocity.x) >= player.speed and not player.wallJumping:
		goal_target.x += 32 * sign(player.velocity.x)
		
	var blend = 0.1
	var base_target = player.global_position - control.startingPos
	if goal_target != base_target:
		blend = 0.15
	
	# Move the actual target towards our new calc'd goal
	current_target_position = round(lerp(current_target_position, goal_target, blend))
	return current_target_position

func check_state() -> State:
	
	return null
