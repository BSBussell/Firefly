extends Area2D
class_name Spring

@export var boing_: AudioStreamPlayer2D
@export var sprite_2d: AnimatedSprite2D

signal bounce()

@export_category("Spring Properties")
## The time the player is locked to a direction after a spring launch
@export var SPRING_DIR_LOCK_TIME: float = 0.2

@export_subgroup("ONLY TOUCH IN PARENT SCENE")
## The Max height of our jump in tiles
@export var MAX_SPRING_HEIGHT: float = 4

## The Time it takes us to reach that height
@export var SPRING_RISE_TIME: float = 0.3
## The max height of a spring boosted by a jump
@export var MAX_JUMP_BOOST_HEIGHT: float = 6
## How long it takes to reach that height
@export var JUMP_BOOST_RISE_TIME: float = 0.36

## The scale of the player
@export var SPRING_SQUASH: Vector2 = Vector2(0.5, 1.5)


## The player that jumped on the spring
var flyph: Flyph

## If the spring has been pressed in the last 0.2 seconds.
var primed: bool = false

#
var spring_velocity: float
var spring_gravity: float

var spring_jb_velocity: float
var spring_jb_gravity: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	# Calculate Velocities and such at initialization
	var spring_actual_height: float = MAX_SPRING_HEIGHT * 16
	spring_velocity = ((-2.0 * spring_actual_height) / SPRING_RISE_TIME)
	spring_gravity = (-2.0 * spring_actual_height) / (SPRING_RISE_TIME * SPRING_RISE_TIME)
	
	# Calculate Spring boosted velocities at initialization
	var spring_jb_height: float = MAX_JUMP_BOOST_HEIGHT * 16
	spring_jb_velocity = ((-2.0 * spring_jb_height) / JUMP_BOOST_RISE_TIME)
	spring_jb_gravity = (-2.0 * spring_jb_height) / (JUMP_BOOST_RISE_TIME ** 2)
	


## Overwritten by subclasses
func _on_body_entered(body: Flyph) -> void:
	
	# If this spring is currently being pressed do nothing
	if primed or body.dying: return
	
	print("Entered")
	
	# Prime the spring
	primed = true
	
	# Set Flyph Up
	flyph = body
	
	# Play the effects that queue on spring down
	spring_down_fx()
	
	# Launch the player
	print("Runing Spring_Jump_Routine")
	spring_jump()
	
	# Play Spring Up Fx
	spring_up_fx()
	
	# Re-enable the spring after a short delay to prevent potential re-triggering
	await get_tree().create_timer(0.2).timeout
	primed = false
	reset()
	

func reset():
	pass
	
# Effects on spring down
func spring_down_fx() -> void:
	
	# Play spring bounce animation, jump to "spring pressed" frame
	sprite_2d.stop()
	sprite_2d.play("bounce")
	#sprite_2d.frame = 2
	
	# Vibrate controller
	Input.start_joy_vibration(1, 0.1, 0.3, 0.11)

# Effect on spring launch
func spring_up_fx() -> void:
	
	# Just Sound :3
	boing_.play(0)

func spring_jump() -> void:
	
	# Values for the launch function
	var launch_velocity: Vector2 = Vector2.ZERO
	var launch_gravity: float = 0.0
	
	# The horizontal momentum; this value will be based on the players current movement speed
	var momentum: Vector2 = Vector2.ZERO
	
	var leniancy_max: float = 0.5
	var leniancy_min: float = 0.05
	
	# The faster the player is moving the more leniancy we give for jump boosted spring bounces
	var leniancy_blend: float = abs(flyph.velocity.x)/flyph.air_speed
	print(leniancy_blend)
	var leniancy: float = lerpf(leniancy_min, leniancy_max, leniancy_blend)
	print(leniancy)
	
	# Check if player is boosting upward by pressing a on the spring
	# This is ordered intentionally to not consume a jump if the player is already jumping
	if (flyph.attempt_post_jump() or flyph.attempt_jump(leniancy)) and not flyph.wallJumping:
		
		# Needed in order to prevent double jump inputs
		flyph.consume_jump()
		
		# Se tthe launch velocity and gravity to the spring_jb values
		launch_velocity.y = spring_jb_velocity
		launch_gravity = spring_jb_gravity
		
		# Recklessly allow Speed to stack if you are doing jump boosts
		momentum = _calc_jump_boost_momentum()
		
		# Make the SFX higher
		boing_.pitch_scale = 1.3
		
	# Otherwise we just bounce off the spring
	else:
		
		# Initial Values in a vaccum and an upright spring
		launch_velocity.y = spring_velocity
		launch_gravity = spring_gravity
	
		
		momentum = _calc_bounce_momentum()
			
		# Play audio at default pitch
		boing_.pitch_scale = 1.0
		
	
	# Rotate the launch velocity to match the springs rotation
	launch_velocity = launch_velocity.rotated(rotation)
	
	
	# Then we align the momentum to work with the springs rotation
	# (Momentum is set in the direction of the rotation)
	momentum = _set_momentum_sign(momentum)
	
	# Add our "adjusted" momentum to the launch
	launch_velocity += momentum
	
	# Use player launch function
	flyph.launch(launch_velocity, launch_gravity, SPRING_SQUASH)
	
	
	# If we're launching horizontally lock input to that direction for time
	if abs(rotation) > 0:
		flyph.lock_h_dir(sign(launch_velocity.x), 0.2)


## Do Momentum Math for a Job Boost
func _calc_jump_boost_momentum() -> Vector2:
	
	var momentum: Vector2 = Vector2.ZERO
	

	# Recklessly allow Speed to stack if you are doing jump boosts
	momentum.x = min(flyph.velocity.x, flyph.speed) * 0.6
	momentum.x += (flyph.velocity.x - momentum.x)

	# Y Momentum
	momentum.y = _y_momentum_set()

	return momentum
	
## Do Momentum for a basic bounce
func _calc_bounce_momentum() -> Vector2:
	
	var momentum: Vector2 = Vector2.ZERO
	
	# If not rotated allow h velocity to carry over
	if rotation == 0.0:
		momentum.x = min(flyph.velocity.x, flyph.speed) * 0.5
	
	# If the spring is rotated, this would be very difficult to figure out how to do ngl

	momentum.y = _y_momentum_set()

	return momentum
	

## Gets the Y val for momentum
func _y_momentum_set() -> float:
	
	var momentum: float = 0
	
	# Only carried over between launchers
	if flyph.launched:
		momentum = flyph.velocity.y * 0.5
	
	return momentum
	
func _set_momentum_sign(momentum: Vector2) -> Vector2:
	
	# If rotated point velocity boost in direction of rotation
	if rotation != 0:
		return Vector2(abs(momentum.x) * sign(rotation), momentum.y)
	
	# Otherwise have it be in the direction the player is holding.
	# Enables the player to reverse direction on a spring
	else:
		return Vector2(abs(momentum.x) * sign(flyph.horizontal_axis), momentum.y)
		
