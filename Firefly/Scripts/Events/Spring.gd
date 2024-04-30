extends Area2D

@onready var sprite_2d = $Sprite2D
@onready var boing_ = $"Boing!"


@export_category("Spring Properties")
@export_subgroup("ONLY TOUCH IN PARENT SCENE")
## The Max height of our jump in tiles
@export var MAX_SPRING_HEIGHT: float = 4			# The max height of our jump in tiles because im so silly like that

## The Time it takes us to reach that height
@export var SPRING_RISE_TIME: float = 0.25			# The time it takes to reach that height

@export var MAX_JUMP_BOOST_HEIGHT: float = 6

@export var JUMP_BOOST_RISE_TIME: float = 0.3

## Potentially Unused lol
@export var SPRING_HORIZ_BOOST: float = 60		# The max speed added on jumping

@export var SPRING_SQUASH: Vector2 = Vector2(1.5, 0.5)

var primed: bool = false

var spring_actual_height: float
var spring_velocity: float
var spring_gravity: float

var spring_jb_height: float
var spring_jb_velocity: float
var spring_jb_gravity: float

var jump_buffer: Timer
var post_jump_buffer: Timer

# Called when the node enters the scene tree for the first time.
func _ready():
	
	spring_actual_height = MAX_SPRING_HEIGHT * 16
	spring_velocity = ((-2.0 * spring_actual_height) / SPRING_RISE_TIME)
	spring_gravity = (-2.0 * spring_actual_height) / (SPRING_RISE_TIME * SPRING_RISE_TIME)
	
	
	spring_jb_height = MAX_JUMP_BOOST_HEIGHT * 16
	spring_jb_velocity = ((-2.0 * spring_jb_height) / JUMP_BOOST_RISE_TIME)
	spring_jb_gravity = (-2.0 * spring_jb_height) / (JUMP_BOOST_RISE_TIME ** 2)
	
	pass # Replace with function body.



var flyph: Flyph

func _on_body_entered(body: Flyph):
	
	# If this spring is currently being pressed do nothing
	if primed: return
	
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
	
# Effects on spring down
func spring_down_fx():
	
	# Play spring bounce animation, jump to "spring pressed" frame
	sprite_2d.play("bounce")
	sprite_2d.frame = 2
	
	# Vibrate controller
	Input.start_joy_vibration(1, 0.1, 0.3, 0.11)

# Effect on spring launch
func spring_up_fx():
	
	# Just Sound :3
	boing_.play(0)

func spring_jump():
	
	# Values for the launch function
	var launch_velocity: Vector2 = Vector2.ZERO
	var launch_gravity: float = 0.0
	
	# The horizontal momentum; this value will be based on the players current movement speed
	var momentum: Vector2 = Vector2.ZERO
	
	# Check if player is boosting upward by pressing a on the spring
	# This is ordered intentionally to not consume a jump if the player is already jumping
	if flyph.attempt_post_jump() or flyph.attempt_jump() and not flyph.wallJumping:
		
		# Needed in order to prevent double jump inputs
		flyph.consume_jump()
		
		# Se tthe launch velocity and gravity to the spring_jb values
		launch_velocity.y = spring_jb_velocity
		launch_gravity = spring_jb_gravity
		
		# Recklessly allow Speed to stack if you are doing jump boosts
		momentum = _jump_boost_momentum_set()
		
		# Make the SFX higher
		boing_.pitch_scale = 1.3
		
	# Otherwise we just bounce off the spring
	else:
		
		# Initial Values in a vaccum and an upright spring
		launch_velocity.y = spring_velocity
		launch_gravity = spring_gravity
	
		
		momentum = _bounce_momentum_set()
			
		# Play audio at default pitch
		boing_.pitch_scale = 1.0
		
	
	# Rotate the launch velocity to match the springs rotation
	launch_velocity = launch_velocity.rotated(rotation)
	
	
	# Then we align the momentum to work with the springs rotation
	# (Momentum is set in the direction of the rotation)
	momentum = _set_momentum_sign(momentum)
	
	# Add our "adjusted" momentum to the launch
	launch_velocity += momentum
	
	flyph.launch(launch_velocity, launch_gravity, SPRING_SQUASH)
	
	
	# If we're launching horizontally lock input to that direction for time
	if abs(rotation) > 0:
		flyph.lock_h_dir(sign(launch_velocity.x), 0.2)


## Do Momentum Math for a Job Boost
func _jump_boost_momentum_set() -> Vector2:
	
	var momentum: Vector2 = Vector2.ZERO
	

	# Recklessly allow Speed to stack if you are doing jump boosts
	momentum.x = min(flyph.velocity.x, flyph.speed) * 0.6
	momentum.x += (flyph.velocity.x - momentum.x)

	# Y Momentum
	momentum.y = _y_momentum_set()

	return momentum
	
## Do Momentum for a basic bounce
func _bounce_momentum_set() -> Vector2:
	
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
		
