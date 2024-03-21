
class_name Flyph
extends CharacterBody2D

@export_category("Movement Resource")
@export var movement_states: Array[PlayerMovementData]

@export_subgroup("MISC")
@export var star: CPUParticles2D
@export var debug_info: Label
@export var meter: TextureProgressBar
@export var MusicPlayer: AudioStreamPlayer

# Our State Machine
@onready var StateMachine = $StateMachine

# Colliders
@onready var standing_collider = $Standing_Collider
@onready var crouching_collider = $Crouching_Collider

@onready var standing_collider_pos = standing_collider.position
@onready var standing_collider_shape = standing_collider.shape.size


# Visual Nodes
@onready var animation = $Visuals/AnimatedSprite2D
@onready var spotlight = $Visuals/Spotlight
@onready var light = $Visuals/Spotlight
@onready var trail = $Visuals/Trail
@onready var deathDust = $Particles/JumpDustSpawner

# Timers
@onready var jump_buffer = $Timers/JumpBuffer
@onready var coyote_time = $Timers/CoyoteTime
@onready var momentum_time = $Timers/MomentumTime

# Vertical Corner Correction Raycasts
@onready var top_left = $Raycasts/VerticalSmoothing/TopLeft
@onready var top_right = $Raycasts/VerticalSmoothing/TopRight

# Horizontal Corner Correction Raycasts
@onready var bottom_right = $Raycasts/HorizontalSmoothing/BottomRight
@onready var step_max_right = $Raycasts/HorizontalSmoothing/StepMaxRight
@onready var right_accuracy = $Raycasts/HorizontalSmoothing/RightAccuracy

@onready var bottom_left = $Raycasts/HorizontalSmoothing/BottomLeft
@onready var step_max_left = $Raycasts/HorizontalSmoothing/StepMaxLeft
@onready var left_accuracy = $Raycasts/HorizontalSmoothing/LeftAccuracy

# Auto Enter Tunnel
@onready var crouch_left = $Raycasts/AutoTunnel/CrouchLeft
@onready var crouch_right = $Raycasts/AutoTunnel/CrouchRight


# Respawn / Death Variables
@onready var starting_position = global_position

# Movement State Shit
@onready var movement_data = movement_states[0]
@onready var max_level = len(movement_states) - 1

# Velocity Units
@onready var speed: float # Adjust for tile size
@onready var accel: float

# Stop distance
@onready var stop_distance: float
@onready var friction: float

@onready var turn_distance: float
@onready var turn_friction: float

# Adjust Slide Values
@onready var slide_distance: float
@onready var slide_friction: float

@onready var hill_speed: float
@onready var hill_accel: float

# Crouch Values
@onready var longjump_velocity: float

# Air Speed
@onready var air_speed: float
@onready var air_accel: float
@onready var air_stop_distance: float
@onready var air_frict: float
@onready var tunnel_jump_accel: float

# Projectile Motion / Jump Math
@onready var jump_actual_height: float
@onready var jump_velocity: float
@onready var jump_gravity: float
@onready var fall_gravity: float

# Wall Jump
@onready var walljump_height: float
@onready var walljump_distance: float

@onready var up_walljump_height: float
@onready var up_walljump_distance: float

@onready var down_walljump_height: float
@onready var down_walljump_distance: float

@onready var walljump_gravity: float
@onready var up_walljump_gravity: float

@onready var walljump_velocity_y: float
@onready var walljump_velocity_x: float

@onready var up_walljump_velocity_y: float
@onready var up_walljump_velocity_x: float

@onready var down_walljump_velocity_y: float
@onready var down_walljump_velocity_x: float

# The velocity of our fast fall
@onready var ff_velocity: float
@onready var ff_gravity: float

# Animation Variable
@onready var run_threshold: float# Jumps helps to do this better

const TILE_SIZE: int = 16

const JUMP_DUST = preload("res://Scenes/Player/particles/jump_dust.tscn")
const LANDING_DUST = preload("res://Scenes/Player/particles/landing_dust.tscn")
const CROUCH_JUMP_DUST = preload("res://Scenes/Player/particles/crouchJumpDust.tscn")
const WJ_DUST = preload("res://Scenes/Player/particles/wallJumpDust.tscn")
const DEATH_DUST = preload("res://Scenes/Player/particles/DeathParticle.tscn")

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

# lol
enum WALLJUMPS { NEUTRAL, UPWARD, DOWNWARD }
var current_wj: WALLJUMPS = WALLJUMPS.NEUTRAL
var current_wj_dir: float = 0

# Various Player States Shared Across Bleh :3
var fastFalling: bool = false
var airDriftDisabled: bool = false
var wallJumping: bool = false
var turningAround: bool = false
var crouchJumping: bool = false
var canCrouchJump: bool = true

# Used for when hitting a wall kills our velocity and we wanna get it back
var prev_velocity_x: float = 0.0


# Animation values
var current_animation: ANI_STATES
var prev_animation: ANI_STATES
var restart_animation: bool = false

# Input values
var vertical_axis: float = 0
var horizontal_axis: float = 0

# DEATH
var dying: bool = false

# Players Movement Score

@onready var glow_manager: Glow_Manager = $GlowManager



var movement_level: int = 0
var score: float = 0

const MAX_ENTRIES: int = 180
const SPEEDOMETER_ENTRIES: int = 120
const FF_ENTRIES: int = 10
const SLIDE_ENTRIES: int = 10

var air_speed_buffer: Array = []
var ground_speed_buffer: Array = []
var slide_buffer: Array = []
var speedometer_buffer: Array = []
var landings_buffer: Array = [] # I think this one might be stupid ngl

var average_speed: float = 0
var air_normalized_average_speed: float = 0
var ground_normalized_average_speed: float = 0
var average_ff_landings: float = 0
var average_slides: float = 0
var tmp_modifier: float = 0


var GLOW_ENABLED: bool = true

# I'm Being really annoying about this btw
func _ready() -> void:
	
	# I hate myself
	calculate_properties()
	
	
	glow_manager.startup()
	# Setting up our buffers
	#air_speed_buffer.resize(MAX_ENTRIES)
	#ground_speed_buffer.resize(MAX_ENTRIES)
	#landings_buffer.resize(FF_ENTRIES)
	#speedometer_buffer.resize(SPEEDOMETER_ENTRIES)
	#slide_buffer.resize(SLIDE_ENTRIES)
#
	#speedometer_buffer.fill(0)
	#air_speed_buffer.fill(0)
	#ground_speed_buffer.fill(0)
	#landings_buffer.fill(0)
	#slide_buffer.fill(0)

	# Initialize the State Machine pass us to it
	StateMachine.init(self)
	
func _unhandled_input(event: InputEvent) -> void:
	
	# Ok for some reason my joystick is giving like 0.9998 which when holding left, which apparently
	# is enough for my player to move considerably slower than like i want them to... so im just gonna
	horizontal_axis = snappedf( Input.get_axis("Left", "Right"), 0.5 ) 
	vertical_axis = snappedf(Input.get_axis("Down", "Up"), 0.5 ) # idek if im gonna use this one lol
	
	# For quickly chaning states
	if OS.is_debug_build():
		if Input.is_action_just_pressed("debug_up") and movement_level != max_level:
			glow_manager.change_state(movement_level + 1)
		if Input.is_action_just_pressed("debug_down") and movement_level > 0:
			glow_manager.change_state(movement_level - 1)
		if Input.is_action_just_pressed("reset"):
			calculate_properties()
	
	StateMachine.process_input(event)
	
func _physics_process(delta: float) -> void:
	
	if not dying:
		# Calls the physics proceess
		StateMachine.process_physics(delta)
		
		
		move_and_slide()
		
		# Corner Smoothing when jumping up
		if velocity.y < 0 and not is_on_wall() :
			jump_corner_correction(delta)
			
		# If they are moving horizontally or trying to move horizontally :3
		if (abs(horizontal_axis) > 0 or abs(velocity.x) > 0):
			horizontal_corner_correction(delta) # Kinda a misleading name but pretty much we will gravitate the player towards small dips that it feels like the character should be able to step up
		
		# Auto Enter Tunnel
		if is_on_wall():
			print(prev_velocity_x)
			auto_enter_tunnel(delta)
		
		## Update Scoring information based on movement speed, etc.
		#update_speed()
		#score = calc_score()
		
		# Store the velocity for next frame
		prev_velocity_x = velocity.x
	
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

	# Display current score for dev purposes.
	# TODO: Use a meter of some kinda for this.
	#debug_info.text = "%.02f" % score
	#meter.set_score(score * 100)

	
# Update the current animation based on the current_Animatino variable
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
		
		

# When an animation ends
func _on_animated_sprite_2d_animation_finished():
	
	StateMachine.animation_end()

# Alternate Collider
# This sucks but idk man
func set_crouch_collider():
	#pass
	standing_collider.position = crouching_collider.position
	standing_collider.shape.size = crouching_collider.shape.size
	
	# Enable the crouching one
	#crouching_collider.disabled = false
	# Then disable the standing one
	#standing_collider.disabled = true
	

func set_standing_collider():
	#pass
	standing_collider.position = standing_collider_pos
	standing_collider.shape.size = standing_collider_shape
	
	# Enable it first
	#standing_collider.disabled = false
	# Then disable the other one
	#crouching_collider.disabled = true

#  Player Assist Methods
#######################################
#######################################

# Auto enter hole
func auto_enter_tunnel(delta):
	
	if (not crouch_left.is_colliding() and not bottom_left.is_colliding()) and get_wall_normal().x > 0: 
		set_crouch_collider()
		velocity.x = prev_velocity_x
		crouchJumping = true
	
	elif (not crouch_right.is_colliding() and not bottom_right.is_colliding()) and get_wall_normal().x < 0:
		set_crouch_collider()
		velocity.x = prev_velocity_x
		crouchJumping = true

# When jumping if theres a corner above us we will attempt to guide the player
# Away from the ceiling in order to help smooth out the collisions
# Easy to see visually if you make raycast and collisions visible and jump near a ceiling
func jump_corner_correction(delta):
	
	# Make the strength of adjustments depented on rising velocity cause
	# That makes it feel more natural for some reason
	var strength = abs(velocity.y) * 0.9
	
	if top_left.is_colliding() and not top_right.is_colliding():
		
		if not test_move(global_transform, Vector2(strength * delta, 0)):
			position.x += strength * delta
	elif not top_left.is_colliding() and top_right.is_colliding():
		if not test_move(global_transform, Vector2(-strength * delta, 0)):
			position.x -= strength * delta
		#position.x -= strength * delta



# What allows the player to "smoothly"(lol) step up from small gaps
func horizontal_corner_correction(delta):
	
	# Ignore this if player is standing on a slant
	if get_floor_normal().x != 0:
		return 
	
	# Adjust the Raycast Length based on usecase (if grounded step we need longer 
	if not is_on_floor():
		set_corner_snapping_length(1)
	else:
		# Make it a bit bigger when doing floor corrections in order to give us a little xtra time to get up lol
		set_corner_snapping_length(3)
	
	var offset = ( bottom_right.position.y - step_max_right.position.y ) + 1
	
	# Right side ledge detected
	if bottom_right.is_colliding() and not step_max_right.is_colliding():
		
		# If we are moviging in that direction or pressing that dir
		if (velocity.x > 0 or horizontal_axis > 0) and round(bottom_right.get_collision_normal().x) == bottom_right.get_collision_normal().x:
			
			# Scan using the shapecast
			right_accuracy.force_shapecast_update()
			
			var collision_y = right_accuracy.get_collision_point(0).y
			
			if collision_y == 0:
				#return
				collision_y = position.y
				
			offset = (position.y - collision_y)
			var correction_speed = 1
			
			if is_on_floor():
				offset += 6
				correction_speed = 250
			else:
				#offset += 2
				correction_speed = 100
			
			# Calculate the desired new position
			var test_y = move_toward(position.y, position.y-offset, delta * correction_speed)

			# Calculate the motion vector
			var motion = Vector2(0, test_y - position.y)

			# Check if the motion would cause a collision
			if not test_move(global_transform, motion):
				# If no collision, update the position
				position.y = test_y

				
	elif bottom_left.is_colliding() and not step_max_left.is_colliding():
		
		# If we are moviging in that direction or pressing that dir
		if (velocity.x < 0 or horizontal_axis < 0)  and round(bottom_left.get_collision_normal().x) == bottom_left.get_collision_normal().x:
			
			# Scan using the shape cast
			left_accuracy.force_shapecast_update()
			
			var collision_y = left_accuracy.get_collision_point(0).y
			
			# If we're tall enough se
			if collision_y == 0:
				collision_y = position.y
				
			offset = (position.y - collision_y)
			
			var correction_speed = 1
			if is_on_floor():
				offset += 6
				correction_speed = 250
			else:
				#offset += 2
				correction_speed = 100
				
			# Attempt to smoothly
			# Calculate the desired new position
			var test_y = move_toward(position.y, position.y-offset, delta * correction_speed)

			# Calculate the motion vector
			var motion = Vector2(0, test_y - position.y)

			# Check if the motion would cause a collision
			if not test_move(global_transform, motion):
				# If no collision, update the position
				position.y = test_y

			

# Allows us to resize our raycasts for forward corner corrections
func set_corner_snapping_length(offset: float):
	
	bottom_right.target_position.x = offset
	step_max_right.target_position.x = offset
	bottom_left.target_position.x = -offset
	step_max_left.target_position.x = -offset
	
	 #this might be real chat
	bottom_right.force_raycast_update()
	bottom_left.force_raycast_update()
	step_max_right.force_raycast_update()
	step_max_left.force_raycast_update()



#  Glow State Functions
#######################################
#######################################

## Record Current Speed
#func update_speed():
	#
	#var new_speed: float = 0.0
	#
	#if (current_wj == WALLJUMPS.UPWARD or current_wj == WALLJUMPS.DOWNWARD):
		#new_speed = abs(velocity.y) * 3
	#else:
		#new_speed = abs(velocity.x)
	#
	#
	#
	#var air_percentage_value = new_speed / air_speed
	#var ground_percentage_value = new_speed / speed
	#
	## Add the new speed value to the buffer and remove the oldest entry
	#air_speed_buffer.pop_front()
	#air_speed_buffer.append(air_percentage_value)
	#
	#ground_speed_buffer.pop_front()
	#ground_speed_buffer.append(ground_percentage_value)
	#
	#speedometer_buffer.pop_front()
	#speedometer_buffer.append(new_speed)
	#
	## Update the average speed using reduce()
	#air_normalized_average_speed = air_speed_buffer.reduce(func(acc, num): return acc + num) / air_speed_buffer.size()
	#ground_normalized_average_speed = ground_speed_buffer.reduce(func(acc, num): return acc + num) / ground_speed_buffer.size()
	#average_speed = speedometer_buffer.reduce(func(acc, num): return acc + num) / speedometer_buffer.size()
#
## Called each landing, we counts how often we land with a fast fall
## The assumption being that a player fast falling often is moving quickly lol
#func update_ff_landings(did_ff_land):
	## Add the new fast-fall landing value (1.0 for yes, 0.0 for no) to the buffer and remove the oldest entry
	#landings_buffer.pop_front()
	#landings_buffer.append(did_ff_land)
	## Update the average fast-fall landings using reduce()
	#average_ff_landings = landings_buffer.reduce(func(acc, num): return acc + num) / landings_buffer.size()
#
## Called on every slide, allows us to count how often the player slides optimally
#func update_slides(was_optimal):
	#
	#slide_buffer.pop_front()
	#slide_buffer.append(was_optimal)
	#
	#average_slides = slide_buffer.reduce(func(acc, num): return acc + num) / slide_buffer.size()
#
## Updates the score and change states if appropriate
#func update_score():
	#
	#score = calc_score()
	#
	#if GLOW_ENABLED:
		#if score >= movement_data.UPGRADE_SCORE and movement_level != max_level:
			#
			#star.emitting = true
			#change_state(movement_level + 1)
			#
		#elif score <= movement_data.DOWNGRADE_SCORE and movement_level != 0:
			#
			#change_state(movement_level - 1)
#
## This is its own function so it can easily be changed
#func calc_score():
	#
	#var ff_score = (0.2 * average_ff_landings)
	#var slide_score = (0.2 * average_slides)
	#
	## Speed Score (these numbers are not arbitrary lmao)
	#var air_spd_score = (0.1625 * air_normalized_average_speed)
	#var ground_spd_score = (0.4875 * ground_normalized_average_speed)
	#
	## Honestly this is probably a shitty way of doing this lmao
	#
	#var spd_score = air_spd_score + ground_spd_score
	#
	#
	#return ff_score + spd_score + slide_score + tmp_modifier
#
## A public facing method that can be called by other scripts (ex, collectibles) in order to increase
## 	Player's momentum value
#func add_score(amount: float, weight: float) -> void:
	#tmp_modifier += amount
	#await get_tree().create_timer(weight).timeout
	#tmp_modifier -= amount
#
#func reset_score():
	#
	#speedometer_buffer.fill(0)
	#air_speed_buffer.fill(0)
	#ground_speed_buffer.fill(0)
	#landings_buffer.fill(0)
	#slide_buffer.fill(0)
#
## Recalculating variables changing state
## This is a big weird but by doing it like this it enables us to jump around levels
## In debug or just whatever
#func change_state(level: int):
	#
	## This should only be called when im lazy
	##if level == movement_level:
		##return
	#
	#movement_level = level
	#
	## Ok set the new movement level
	#movement_data = movement_states[movement_level]
	#
	## Big ass math moment
	#calculate_properties()
	
	
# Recalculated all the players movement properties
#     Necessary because the player parameters are described in ways that are easier to measure,and quantify
#        but also require some math in order to convert these parameters to the actual forces and changes in velocity
func calculate_properties():
	
	# Recalc Speed:
	speed = movement_data.MAX_SPEED * TILE_SIZE
	accel = speed / movement_data.TIME_TO_ACCEL
	
	# Friction math
	stop_distance = movement_data.FRICTION * TILE_SIZE
	friction = (speed * speed) / (2 * stop_distance)
	
	# This ones broken but ill fix it l8r :3
	turn_distance = movement_data.TURN_FRICTION * TILE_SIZE
	turn_friction = (speed * speed) / (2 * turn_distance)
	
	# Slide Values ReCalculated
	slide_distance = movement_data.SLIDE_DISTANCE * TILE_SIZE
	slide_friction = (speed * speed) / (2 * slide_distance)

	hill_speed = movement_data.HILL_SPEED * TILE_SIZE
	hill_accel = hill_speed / movement_data.HILL_TIME_TO_ACCEL
	
	# Recalc Air values
	air_speed = movement_data.AIR_SPEED * TILE_SIZE
	air_accel = air_speed / movement_data.AIR_TIME_TO_ACCEL
	air_stop_distance = movement_data.AIR_FRICT * TILE_SIZE
	air_frict = (air_speed * air_speed) / (2 * stop_distance)
	
	# How fast we can move when hopping through a "tunnel"
	tunnel_jump_accel = air_speed / movement_data.TUNNEL_JUMP_ACCEL
	
	# Projectile Motion
	jump_actual_height = movement_data.MAX_JUMP_HEIGHT * TILE_SIZE
	jump_velocity = ((-2.0 * jump_actual_height) / movement_data.JUMP_RISE_TIME)
	jump_gravity = (-2.0 * jump_actual_height) / (movement_data.JUMP_RISE_TIME * movement_data.JUMP_RISE_TIME)
	fall_gravity = (-2.0 * jump_actual_height) / (movement_data.JUMP_FALL_TIME * movement_data.JUMP_FALL_TIME)

	# Translate Walljump Dimensions
	walljump_height = movement_data.WALL_JUMP_VECTOR.y * TILE_SIZE
	walljump_distance = movement_data.WALL_JUMP_VECTOR.x * TILE_SIZE
	
	# Translate Upward Wall Dimensions
	up_walljump_height = movement_data.UP_WALL_JUMP_VECTOR.y * TILE_SIZE
	up_walljump_distance = movement_data.UP_WALL_JUMP_VECTOR.x * TILE_SIZE

	# Translate Downward Wall Dimensions
	down_walljump_height = movement_data.DOWN_WALL_JUMP_VECTOR.y * TILE_SIZE
	down_walljump_distance = movement_data.DOWN_WALL_JUMP_VECTOR.x * TILE_SIZE
	
	# Walljump Gravity's
	walljump_gravity = (-2.0 * walljump_height) / (movement_data.WJ_RISE_TIME * movement_data.WJ_RISE_TIME)
	up_walljump_gravity = (-2.0 * up_walljump_height) / (movement_data.UP_WJ_RISE_TIME * movement_data.UP_WJ_RISE_TIME)
	
	# Wall Jump Velocities
	walljump_velocity_y = ((-2.0 * walljump_height) / (movement_data.WJ_RISE_TIME))
	walljump_velocity_x = (( walljump_distance) / (movement_data.WJ_RISE_TIME + movement_data.JUMP_FALL_TIME))

	# Upward Wall Jump Velocities
	up_walljump_velocity_y = (( -2.0 * up_walljump_height) / (movement_data.UP_WJ_RISE_TIME))
	up_walljump_velocity_x = (( up_walljump_distance) / (movement_data.UP_WJ_RISE_TIME + movement_data.JUMP_FALL_TIME))

	# Downward Wall Jump Velocities
	down_walljump_velocity_y = ((-2.0 * down_walljump_height) / (movement_data.JUMP_RISE_TIME)) # ya know, this ones a bit wild
	down_walljump_velocity_x = (( down_walljump_distance) / (movement_data.JUMP_RISE_TIME + movement_data.JUMP_FALL_TIME))


	# The velocity of our ff
	ff_velocity = jump_velocity / movement_data.FASTFALL_MULTIPLIER
	ff_gravity = fall_gravity * movement_data.FASTFALL_MULTIPLIER

	# Set timers
	coyote_time.wait_time = movement_data.COYOTE_TIME
	jump_buffer.wait_time = movement_data.JUMP_BUFFER
	momentum_time.wait_time = movement_data.STRICTNESS

	# Visual
	trail.length = movement_data.TRAIL_LENGTH
	run_threshold = movement_data.RUN_THRESHOLD * TILE_SIZE
	
	# Visual: Setting Glow and such
	light.set_brightness(movement_data.BRIGHTNESS)
	trail.set_glow(movement_data.GLOW)
	animation.set_glow(movement_data.GLOW)
	
	# Setup Meter
	if movement_level != max_level:
		meter.update_range(movement_data.DOWNGRADE_SCORE * 100, movement_data.UPGRADE_SCORE * 100)
	
	# So if we are the max level then we set the meter to only go down when the players at risk of losing momentum
	else:
		meter.update_range(0, movement_data.DOWNGRADE_SCORE * 100)
		
		
		

# DEATH RELATED METHODS!
##############################
##############################
# Whatever we need to do when the player dies can be called here
func kill():
	
	trail.clear_points()
	
	# Give dust on landing
	var new_cloud = DEATH_DUST.instantiate()
	new_cloud.set_name("death_dust_temp")
	deathDust.add_child(new_cloud)
	var death_animation = new_cloud.get_node("AnimationPlayer")
	death_animation.play("Start")
	
	animation.visible = false
	dying = true
	
	await get_tree().create_timer(1.5).timeout
	
	_stats.DEATHS += 1
	global_position = starting_position
	velocity = Vector2.ZERO
	animation.visible = true
	dying = false
	glow_manager.change_state(0)
	glow_manager.reset_score()

func _on_hazard_detector_area_entered(area):
	kill()

func _on_hazard_detector_body_entered(body):
	kill()
