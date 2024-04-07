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

@export var SPRING_SQUASH: Vector2 = Vector2(0.7, 1.3)

var spring_actual_height: float
var spring_velocity: float
var spring_gravity: float

var spring_jb_height: float
var spring_jb_velocity: float
var spring_jb_gravity: float

var jump_buffer: Timer

# Called when the node enters the scene tree for the first time.
func _ready():
	
	spring_actual_height = MAX_SPRING_HEIGHT * 16
	spring_velocity = ((-2.0 * spring_actual_height) / SPRING_RISE_TIME)
	spring_gravity = (-2.0 * spring_actual_height) / (SPRING_RISE_TIME * SPRING_RISE_TIME)
	
	
	spring_jb_height = MAX_JUMP_BOOST_HEIGHT * 16
	spring_jb_velocity = ((-2.0 * spring_jb_height) / JUMP_BOOST_RISE_TIME)
	spring_jb_gravity = (-2.0 * spring_jb_height) / (JUMP_BOOST_RISE_TIME ** 2)
	
	pass # Replace with function body.



var spring_active: bool = false

var flyph: Flyph
func _on_body_entered(body: Flyph):
	
	#body.set_temp_gravity(parent.spring)
	flyph = body
	
	var buffered_jump: bool = false
	var coyote_timer: Timer
	
	coyote_timer = flyph.get_node("Timers/CoyoteTime")
	jump_buffer = flyph.get_node("Timers/JumpBuffer")
	buffered_jump = jump_buffer.time_left > 0 
	#print(jump_buffer.time_left)
	
	sprite_2d.play("bounce")
	sprite_2d.frame = 1
	
	Input.start_joy_vibration(1, 0.1, 0.3, 0.11)
	
	# The faster the player is going (ie the more likely they are to leave the spring quickly)
	# The shorter the delay. This lets us have a delay sometimes, and if the players moving too fast for this then we don't 
	var timeout: float = 0.1
	timeout = lerpf(0.1, 0.05, flyph.velocity.length() / 300)
	
	# Wait a bit
	await get_tree().create_timer(timeout).timeout
	
	
	var launch_velocity: Vector2
	var launch_gravity: float
	
	launch_velocity.x = 0.0
	launch_velocity.y = spring_velocity
	
	launch_gravity = spring_gravity
	
	print("Rot", rotation)
	
	launch_velocity = launch_velocity.rotated(rotation)
	
	# Both allows player to have initial velocity + allows massive boosts :3
	var normaled_velocity_x = 0
	
	
	# If we're already jumpin :3
	if jump_buffer.time_left > 0 or buffered_jump or Input.is_action_just_pressed("Jump"):
		print("Jump Boost!")
		print(jump_buffer.time_left > 0)
		print(coyote_timer.time_left > 0)
		print("lol")
		launch_velocity.y = spring_jb_velocity
		launch_gravity = spring_jb_gravity
		boing_.pitch_scale = 1.5
		
		print(Input.is_action_just_pressed("Jump"))
		
		# Clear the buffer
		jump_buffer.stop()
		coyote_timer.stop()
		
		# Recklessly allow Speed to stack if you are doing jump boosts
		normaled_velocity_x = min(flyph.velocity.x, flyph.speed) * 0.5
		normaled_velocity_x += (flyph.velocity.x - normaled_velocity_x) * 0.75
		
		
		
	else:
		
		# If not rotated allow h velocity to carry over
		if rotation == 0.0:
			normaled_velocity_x = flyph.velocity.x
			
		boing_.pitch_scale = 1.0
		
	
	
	
	
	# If rotated point velocity boost in direction of rotation
	if rotation != 0:
		normaled_velocity_x = abs(normaled_velocity_x) * sign(rotation)
		#flyph.horizontal_axis = sign(rotation)
	
	
	print("hBoost: ", normaled_velocity_x)
	launch_velocity.x += normaled_velocity_x
	
	# Lets this chain into other springs that launch the player
	if flyph.temp_gravity_active:
		print("Chain :3")
		# Allows chaining without giving a massive boosts
		launch_velocity.y += (flyph.velocity.y * 0.5)
	
	
	
	print(launch_velocity)
	
	boing_.play(0)
	
	flyph.launch(launch_velocity, launch_gravity, SPRING_SQUASH)
	



func _on_body_exited(body: Flyph):

	# Doing this actually sucks
	#spring_active = false
	pass # Replace with function body.


func _on_sprite_2d_animation_finished():
	
	#flyph.spring_body_entered(flyph)
	pass # Replace with function body.
