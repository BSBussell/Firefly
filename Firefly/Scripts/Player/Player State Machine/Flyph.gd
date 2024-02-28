
class_name Flyph
extends CharacterBody2D

@export_category("Movement Resource")
@export var movement_states: Array[PlayerMovementData]
#@export var base_movement : PlayerMovementData
#@export var speed_movement: PlayerMovementData

@export var star: CPUParticles2D
@export var debug_info: Label


# Nodes
@onready var animation = $Visuals/AnimatedSprite2D
@onready var StateMachine = $StateMachine
@onready var spotlight = $Visuals/Spotlight
@onready var light_animator = $Visuals/Spotlight/light_animator
@onready var trail = $Visuals/Trail
@onready var starting_position = global_position


# Movement State Shit
@onready var movement_data = movement_states[0]
@onready var max_level = len(movement_states) - 1

# Velocity Units
@onready var speed = movement_data.MAX_SPEED * 16 # Adjust for tile size
@onready var accel = movement_data.ACCEL * 16
@onready var friction = movement_data.FRICTION * 16
@onready var turn_friction = movement_data.TURN_FRICTION * 16

# Adjust Slide Values
@onready var slide_friction = movement_data.SLIDE_FRICTION * 16
@onready var hill_speed = movement_data.HILL_SPEED * 16
@onready var hill_accel = movement_data.HILL_ACCEL * 16

# Air Speed
@onready var air_speed = movement_data.AIR_SPEED * 16 
@onready var air_accel = movement_data.AIR_ACCEL * 16 
@onready var air_frict = movement_data.AIR_FRICT * 16 

# Projectile Motion / Jump Math
@onready var jump_actual_height = movement_data.MAX_JUMP_HEIGHT * 16 # Convert to tile size
@onready var jump_velocity: float = ((-2.0 * jump_actual_height) / movement_data.JUMP_RISE_TIME)
@onready var jump_gravity: float = (-2.0 * jump_actual_height) / (movement_data.JUMP_RISE_TIME * movement_data.JUMP_RISE_TIME)
@onready var fall_gravity: float = (-2.0 * jump_actual_height) / (movement_data.JUMP_FALL_TIME * movement_data.JUMP_FALL_TIME)

# Wall Jump
@onready var walljump_height = movement_data.WALL_JUMP_HEIGHT * 16
@onready var walljump_velocity = ((-2.0 * walljump_height) / movement_data.JUMP_RISE_TIME)

@onready var walljump_horizontal_velocity = (( movement_data.WALL_JUMP_DISTANCE) / movement_data.JUMP_RISE_TIME)

# The velocity of our ff
@onready var ff_velocity = jump_velocity / movement_data.FASTFALL_MULTIPLIER
@onready var ff_gravity: float = fall_gravity * movement_data.FASTFALL_MULTIPLIER


const JUMP_DUST = preload("res://Scenes/Player/particles/jump_dust.tscn")
const LANDING_DUST = preload("res://Scenes/Player/particles/landing_dust.tscn")

enum ANI_STATES { 
	
	CRAWL,
	CROUCH,
	FALLING,
	IDLE,
	JUMP,
	LANDING,
	RUNNING,
	STANDING_UP,	# From Crawl
	WALKING
	
}

var fastFalling = false
var airDriftDisabled = false
var wallJumping = false
var turningAround = false

#@onready var cacheAirdrift = movement_data.AIR_DRIFT_MULTIPLIER

var current_animation: ANI_STATES
var prev_animation: ANI_STATES
var restart_animation: bool = false

var vertical_axis = 0
var horizontal_axis = 0


# Players Movement Score
var movement_level = 0

var score = 0

const MAX_ENTRIES = 120

var speed_buffer = []
var landings_buffer = []

var average_speed = 0
var average_ff_landings = 0

var tmp_modifier = 0

# I'm Being really annoying about this btw
func _ready() -> void:
	
	# Setting up our buffers
	speed_buffer.resize(MAX_ENTRIES)
	landings_buffer.resize(MAX_ENTRIES)
	
	speed_buffer.fill(0.5)
	landings_buffer.fill(0.5)

	print(jump_gravity)


	
	# Initialize the State Machine pass self to it
	StateMachine.init(self)
	
func _unhandled_input(event: InputEvent) -> void:
	
	
	# Ok for some reason my joystick is giving like 0.9998 which when holding left, which apparently
	# is enough for my player to move considerably slower than like i want them to... so im just gonna
	horizontal_axis = snappedf( Input.get_axis("Left", "Right"), 0.5 ) 
	vertical_axis = snappedf(Input.get_axis("Down", "Up"), 0.5 ) # idek if im gonna use this one lol
	
	print(horizontal_axis)
	
	# Debug shit
	if OS.is_debug_build():
		if Input.is_action_just_pressed("debug_up"):
			change_state(1)
		elif Input.is_action_just_pressed("debug_down"):
			change_state(0)
	
	StateMachine.process_input(event)
	
func _physics_process(delta: float) -> void:
	
	StateMachine.process_physics(delta)
	
	update_speed(abs(velocity.x))
	
func _process(delta: float) -> void:
	
	
	if restart_animation:
		animation.set_frame_and_progress(0,0)
		
	# Only update animations if we've changed animations
	if prev_animation != current_animation or restart_animation:
		update_animations()
		restart_animation = false
		
	prev_animation = current_animation
	
	# Let each component do their frame stuff
	StateMachine.process_frame(delta)

	score = (0.4 * average_ff_landings + 0.6 * average_speed) + tmp_modifier
	debug_info.text = "%.02f" % average_speed
	

func update_animations():
	
	match current_animation:
		
		# Basic Animations
		ANI_STATES.IDLE:
			animation.play("idle")	
		ANI_STATES.WALKING:
			animation.play("walking")
		ANI_STATES.RUNNING:
			animation.play("running")
		
		# Crouch Animations
		ANI_STATES.CRAWL:
			#print("crawl: played")
			animation.play("crawl")
		ANI_STATES.CROUCH:
			animation.play("crouch")
		ANI_STATES.STANDING_UP:
			animation.play("stand up")
		
		# Air/Jump Animations
		ANI_STATES.JUMP:
			animation.play("jump")
		ANI_STATES.FALLING:
			animation.play("falling")
		ANI_STATES.LANDING:
			animation.play("landing")
		
		
func _on_animated_sprite_2d_animation_finished():
	
	StateMachine.animation_end()

func update_speed(new_speed):
	
	var percentage_value = new_speed / speed
	
	# Add the new speed value to the buffer and remove the oldest entry
	speed_buffer.pop_front()
	speed_buffer.append(percentage_value)
	# Update the average speed using reduce()
	average_speed = speed_buffer.reduce(func(acc, num): return acc + num) / speed_buffer.size()

func update_ff_landings(did_ff_land):
	# Add the new fast-fall landing value (1.0 for yes, 0.0 for no) to the buffer and remove the oldest entry
	landings_buffer.pop_front()
	landings_buffer.append(did_ff_land)
	# Update the average fast-fall landings using reduce()
	average_ff_landings = landings_buffer.reduce(func(acc, num): return acc + num) / landings_buffer.size()


func update_score():
	
	score = (0.4 * average_ff_landings + 0.6 * average_speed)
	score += tmp_modifier
	
	
	
	if score >= movement_data.UPGRADE_SCORE and movement_level != max_level:
		
		change_state(movement_level + 1)
		
	elif score <= movement_data.DOWNGRADE_SCORE and movement_level != 0:
		
		change_state(movement_level - 1)
		


func _on_momentum_time_timeout():
	update_score()
	pass
	
# A public facing method that can be called by other scripts (ex, collectibles) in order to increase
# 	Player's momentum value
func add_momentum(amount: float, weight: float) -> void:
	tmp_modifier += amount
	await get_tree().create_timer(weight).timeout
	tmp_modifier -= amount

# Recalculating variables changing state
# This is a big weird but by doing it like this it enables us to jump around levels
# In debug or just whatever
func change_state(level: int):
	
	# This should only be called when im lazy
	#if level == movement_level:
		#return
	
	# If we leveling up
	if level > movement_level:
		star.emitting = true 
		light_animator.play("turn_up")
		
	else:
		light_animator.play("turn_down")
		
	movement_level = level
	
	# Ok set the new movement level
	movement_data = movement_states[movement_level]
	
	# Recalc Speed:
	speed = movement_data.MAX_SPEED * 16
	accel = movement_data.ACCEL * 16
	friction = movement_data.FRICTION * 16
	turn_friction = movement_data.TURN_FRICTION * 16
	
	# Slide Values ReCalculated
	slide_friction = movement_data.SLIDE_FRICTION * 16
	hill_speed = movement_data.HILL_SPEED * 16
	hill_accel = movement_data.HILL_ACCEL * 16
	
	# Recalc Air values lol kinda miserable but i like how this works
	air_speed = movement_data.AIR_SPEED * 16 
	air_accel = movement_data.AIR_ACCEL * 16 
	air_frict = movement_data.AIR_FRICT * 16 
	
	# Projectile Motion
	jump_actual_height = movement_data.MAX_JUMP_HEIGHT * 16 # Convert to tile size
	jump_velocity = ((-2.0 * jump_actual_height) / movement_data.JUMP_RISE_TIME)
	jump_gravity = (-2.0 * jump_actual_height) / (movement_data.JUMP_RISE_TIME * movement_data.JUMP_RISE_TIME)
	fall_gravity = (-2.0 * jump_actual_height) / (movement_data.JUMP_FALL_TIME * movement_data.JUMP_FALL_TIME)


	# The velocity of our ff
	ff_velocity = jump_velocity / movement_data.FASTFALL_MULTIPLIER
	ff_gravity = fall_gravity * movement_data.FASTFALL_MULTIPLIER

	# Visual
	trail.length = movement_data.TRAIL_LENGTH

func kill():
	
	trail.clear_points()
	global_position = starting_position

func _on_hazard_detector_area_entered(area):
	kill()

