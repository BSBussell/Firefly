
class_name Flyph
extends CharacterBody2D

@export_category("Movement Resource")
@export var movement_states: Array[PlayerMovementData]

@export_subgroup("MISC")
@export var star: CPUParticles2D
@export var debug_info: Label
@export var meter: TextureProgressBar
@export var MusicPlayer: AudioStreamPlayer

@export_category("Visual Tweaks")
@export_subgroup("Squash Constants")
@export var jump_squash = Vector2(0.6, 1.4)
@export var lJump_squash = Vector2(0.6, 1.4)
@export var wJump_squash = Vector2(0.6, 1.4)
@export var falling_squash = Vector2(0.5, 1.5)
@export var landing_squash = Vector2( 1.5, 0.5)
@export var crouch_squash = Vector2(1.4,0.6)
@export var stand_up_squash = Vector2(1.4, 0.6)
@export var turn_around_squash = Vector2(0.6, 1.0)
@export var death_squash = Vector2(1.5, 0.5)

# Our State Machine
@onready var StateMachine = $StateMachine

# Colliders
@onready var collider = $Collider
@onready var standing_collider = $Standing_Collider
@onready var crouching_collider = $Crouching_Collider

@onready var standing_collider_pos = standing_collider.position
@onready var standing_collider_shape = standing_collider.shape.size


# Visual Nodes
@onready var animation: AnimatedSprite2D = $Visuals/SquishCenter/AnimatedSprite2D
@onready var squish_node: Node2D = $Visuals/SquishCenter
@onready var spotlight: PointLight2D = $Visuals/Spotlight
@onready var light: PointLight2D = $Visuals/Spotlight
@onready var trail: Line2D = $Visuals/Trail
@onready var deathDust: Marker2D = $Particles/JumpDustSpawner

@onready var glow_aura = $Particles/GlowAura
@onready var mega_speed_particles = $Particles/MegaSpeedParticles
@onready var wall_slide_dust = $Particles/WallSlideDust

# Spring (hope ur ok with this spot)
@onready var spring_gravity_active: bool
@onready var spring_gravity: float
@onready var spring_velocity: float
@onready var spring_jump_height: float
@onready var spring_actual_height: float
@onready var in_spring: bool

# Timers
@onready var jump_buffer: Timer = $Timers/JumpBuffer
@onready var coyote_time: Timer = $Timers/CoyoteTime
@onready var momentum_time: Timer = $Timers/MomentumTime

# Vertical Corner Correction Raycasts
@onready var top_left: RayCast2D = $Raycasts/VerticalSmoothing/TopLeft
@onready var top_right: RayCast2D = $Raycasts/VerticalSmoothing/TopRight

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
const RESPAWN_DUST = preload("res://Scenes/Player/particles/RespawnParticle.tscn")

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
var prev_velocity_y: float = 0.0

## The Speed the player was moving before hitting the ground
var landing_speed: float = 0.0

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
	
	# idk why this happens sometimes but on reset occasionally game gets confused
	set_standing_collider()
	
	glow_manager.startup()

	# Initialize the State Machine pass us to it
	StateMachine.init(self)
	
func _unhandled_input(event: InputEvent) -> void:
	
	# Ok for some reason my joystick is giving like 0.9998 which when holding left, which apparently
	# is enough for my player to move considerably slower than like i want them to... so im just gonna
	horizontal_axis = snappedf( Input.get_axis("Left", "Right"), 0.5 ) 
	vertical_axis = snappedf(Input.get_axis("Down", "Up"), 0.5 ) # idek if im gonna use this one lol
	
	# For quickly chaning states
	if OS.is_debug_build():
		if Input.is_action_just_pressed("debug_up"):
			glow_manager.promote()
		if Input.is_action_just_pressed("debug_down") and glow_manager.movement_level > 0:
			glow_manager.demote()
		if Input.is_action_just_pressed("reset"):
			calculate_properties()
	
	StateMachine.process_input(event)
	
func _physics_process(delta: float) -> void:
	
	if not dying:
		# Calls the physics proceess
		StateMachine.process_physics(delta)
		
		# Actual movement operations
		move_and_slide()
		
		# Corner Smoothing when jumping up
		if velocity.y < 0 and not is_on_wall(): jump_corner_correction(delta)
			
		# If they are moving horizontally or trying to move horizontally :3
		if (abs(horizontal_axis) > 0 or abs(velocity.x) > 0): horizontal_corner_correction(delta) # Kinda a misleading name but pretty much we will gravitate the player towards small dips that it feels like the character should be able to step up
		
		# Auto Enter Tunnel
		if is_on_wall(): auto_enter_tunnel(delta)
		
		## Update Scoring information based on movement speed, etc.
		#update_speed()
		#score = calc_score()
		
		# Store the velocity for next frame
		prev_velocity_x = velocity.x
		prev_velocity_y = velocity.y
	
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
	collider.position = crouching_collider.position
	collider.shape.size = crouching_collider.shape.size
	
	# Enable the crouching one
	#crouching_collider.disabled = false
	# Then disable the standing one
	#standing_collider.disabled = true
	

func set_standing_collider():
	#pass
	collider.position = standing_collider.position
	collider.shape.size = standing_collider.shape.size
	
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
		squish_node.squish(crouch_squash)
		crouchJumping = true
	
	elif (not crouch_right.is_colliding() and not bottom_right.is_colliding()) and get_wall_normal().x < 0:
		set_crouch_collider()
		velocity.x = prev_velocity_x
		squish_node.squish(crouch_squash)
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
			squish_node.squish(jump_squash)
	elif not top_left.is_colliding() and top_right.is_colliding():
		if not test_move(global_transform, Vector2(-strength * delta, 0)):
			position.x -= strength * delta
			squish_node.squish(jump_squash)
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
				squish_node.squish( Vector2(1.2, 0.8))

				
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
				offset += 2
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
				squish_node.squish( Vector2(1.2, 0.8))

			

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



##  Glow State Functions
#######################################
#######################################
func enable_glow():
	#glow_manager.reset_score()
	glow_manager.GLOW_ENABLED = true
	
func disable_glow():
	
	# Reset our level and bleh :3
	glow_manager.change_state(0)
	#glow_manager.reset_score()
	glow_manager.GLOW_ENABLED = false
	
# Just an external setter
func add_glow(amount: float) -> void:
	glow_manager.add_score(amount)

func force_glow_update():
	glow_manager.update_score()

func get_glow_score():
	return glow_manager.glow_points

func get_glow_level():
	return glow_manager.movement_level
	
## Automatically use glow as soon as obtained
func enable_auto_glow():
	glow_manager.auto_glow = true

## Requires pressing a button to glow
func disable_auto_glow():
	glow_manager.auto_glow = false
	
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

	# Spring Motion
	spring_actual_height = movement_data.MAX_SPRING_HEIGHT * TILE_SIZE
	spring_velocity = ((-2.0 * spring_actual_height) / movement_data.SPRING_RISE_TIME)
	spring_gravity = (-2.0 * spring_actual_height) / (movement_data.SPRING_RISE_TIME * movement_data.SPRING_RISE_TIME)
	#spring_gravity = (-2.0 * spring_actual_height) / (movement_data.SPRING_FALL_TIME * movement_data.JUMP_FALL_TIME)

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
	
	
		
func give_boost(boost_speed: float) -> void:
	
	velocity.x += boost_speed * horizontal_axis 
	var facing = (-1 if animation.flip_h else 1)
		
		
	
	#velocity += boost  * horizontal_axis

## DEATH RELATED METHODS!
# Whatever we need to do when the player dies can be called here
func kill():
	
	trail.clear_points()
	
	# DEATH EXPLOSION
	Input.start_joy_vibration(1, 0.1, 0.2, 0.2)
	var new_cloud = DEATH_DUST.instantiate()
	new_cloud.set_name("death_dust_temp")
	deathDust.add_child(new_cloud)
	var death_animation = new_cloud.get_node("AnimationPlayer")
	death_animation.play("Start")
	
	squish_node.squish(Vector2(0.5, 0.5))
	
	animation.visible = false
	glow_aura.emitting = false
	wall_slide_dust.emitting = false
	mega_speed_particles.emitting = false
	
	
	dying = true
	
	$Particles/GlowAura.emitting = false
	
	
	glow_manager.reset_glow()
	glow_manager.GLOW_ENABLED = false
	
	await get_tree().create_timer(1.5).timeout
	global_position = starting_position
	
	# LIFE EXPLOSION
	var respawn_cloud = RESPAWN_DUST.instantiate()
	respawn_cloud.set_name("Respawn_dust_temp")
	deathDust.add_child(respawn_cloud)
	var respawn_animation = respawn_cloud.get_node("AnimationPlayer")
	respawn_animation.play("Start")
	
	await get_tree().create_timer(0.7).timeout
	glow_manager.GLOW_ENABLED = true
	
	_stats.DEATHS += 1
	global_position = starting_position
	velocity = Vector2.ZERO
	
	squish_node.squish(death_squash)
	animation.visible = true
	dying = false
	

func _on_hazard_detector_area_entered(area):
	kill()

func _on_hazard_detector_body_entered(body):
	kill()


func _on_checkpoint_detector_area_entered(area):
	starting_position = global_position



	
var temp_gravity_active: bool = false
var temp_gravtity: float = 0.0

# Set a temporary gravity for launches
func set_temp_gravity(grav: float):
	
	temp_gravity_active = true
	temp_gravtity = grav
	

func spring_body_entered(body):
	set_temp_gravity(spring_gravity)
	velocity.y = spring_velocity
	squish_node.squish(Vector2(0.5, 1.5))


func spring_body_exited(body):
	in_spring = false
	if velocity.y == 0:
		spring_gravity_active = false
