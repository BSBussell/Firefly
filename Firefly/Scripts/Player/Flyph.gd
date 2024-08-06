   
class_name Flyph
extends CharacterBody2D

## Exports
const TILE_SIZE: int = 16

const JUMP_DUST = preload("res://Scenes/Player/particles/jump_dust.tscn")
const LANDING_DUST = preload("res://Scenes/Player/particles/landing_dust.tscn")
const CROUCH_JUMP_DUST = preload("res://Scenes/Player/particles/crouchJumpDust.tscn")
const WJ_DUST = preload("res://Scenes/Player/particles/wallJumpDust.tscn")
const DEATH_DUST = preload("res://Scenes/Player/particles/DeathParticle.tscn")
const RESPAWN_DUST = preload("res://Scenes/Player/particles/RespawnParticle.tscn")
const SPLASH = preload("res://Scenes/Player/particles/splash_dust.tscn")
const GET_UP_LEDGE = preload("res://Scenes/Player/particles/get_up_ledge.tscn")
# ENUMS
# Animation States
enum ANI_STATES {

	IDLE,
	WALKING,
	RUNNING,

	JUMP,
	FALLING,
	LANDING,
	PADDLE,

	CROUCH,
	CRAWL,
	STANDING_UP,

	SLIDE_PREP,
	SLIDE_LOOP,
	SLIDE_END,
	
	WALL_HUG,
	WALL_SLIDE,
	WALL_JUMP

}

# Our types of wall jumps
enum WALLJUMPS {
	NEUTRAL,
	UPWARD,
	DOWNWARD
}

signal dead()


@export var is_actor: bool = false


## Editor Variables
@export_category("Movement Resource")
@export var movement_states: Array[PlayerMovementData]


@export_subgroup("States")
@export var GROUNDED_STATE: PlayerState
@export var AERIAL_STATE: PlayerState
@export var SLIDING_STATE: PlayerState
@export var WALL_STATE: PlayerState
@export var GLIDING_STATE: PlayerState
@export var WATERED_STATE: PlayerState
@export var WORMED_STATE: PlayerState

@export_subgroup("MISC")
@export var star: CPUParticles2D
@export var debug_info: Label
@export var meter: TextureProgressBar
@export var MusicPlayer: AudioStreamPlayer

@export_category("Visual Tweaks")
@export_subgroup("Squash Constants")
@export var jump_squash: Vector2 = Vector2(0.6, 1.4)
@export var lJump_squash: Vector2 = Vector2(0.6, 1.4)
@export var wJump_squash: Vector2 = Vector2(0.6, 1.4)
@export var falling_squash: Vector2 = Vector2(0.5, 1.5)
@export var landing_squash: Vector2 = Vector2( 1.5, 0.5)
@export var crouch_squash: Vector2 = Vector2(1.4,0.6)
@export var stand_up_squash: Vector2 = Vector2(1.4, 0.6)
@export var turn_around_squash: Vector2 = Vector2(0.6, 1.0)
@export var death_squash: Vector2 = Vector2(1.5, 0.5)

# Our State Machine
# This is where most of the players movement logic is stored
@onready var StateMachine: PlayerStateMachine = $StateMachine

# Glow Mechanic
@onready var glow_manager: Glow_Manager = $GlowManager


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
@onready var back_wing: Line2D = $Visuals/SquishCenter/WingBody/BackWing
@onready var front_wing: Line2D = $Visuals/SquishCenter/WingBody/FrontWing


# Particles
@onready var glow_aura = $Particles/GlowAura
@onready var promotion_fx = $Particles/PromotionFx
@onready var wall_slide_dust = $Particles/WallSlideDust
@onready var wet = $Particles/Wet
@onready var slide_dust = $Particles/SlideDust
@onready var dash_dust = $Particles/DashDust
@onready var mega_speed_particles = $Particles/MegaSpeedParticles

# Particle Spawners
@onready var jump_dust_spawner = $Particles/JumpDustSpawner
@onready var deathDust: Marker2D = $Particles/JumpDustSpawner
@onready var landing_dust_spawner = $Particles/LandingDustSpawner


# SFX
@onready var sliding_sfx = $Audio/SlidingSFX
@onready var wall_slide_sfx = $Audio/WallSlideSFX
@onready var run_sfx = $Audio/RunSFX


# Timers
#@onready var jump_buffer: Timer = $Timers/JumpBuffer
@onready var coyote_time: Timer = $Timers/CoyoteTime
@onready var momentum_time: Timer = $Timers/MomentumTime
@onready var post_jump_buffer = $Timers/PostJumpBuffer


# Vertical Corner Correction Raycasts
@onready var top_left: RayCast2D = $Raycasts/VerticalSmoothing/TopLeft
@onready var top_right: RayCast2D = $Raycasts/VerticalSmoothing/TopRight

# Horizontal Corner Correction Raycasts Right
@onready var bottom_right: RayCast2D = $Raycasts/HorizontalSmoothing/BottomRight
@onready var step_max_right: RayCast2D = $Raycasts/HorizontalSmoothing/StepMaxRight
@onready var right_accuracy: ShapeCast2D = $Raycasts/HorizontalSmoothing/RightAccuracy

# Horizontal Corner Correction Raycasts Left
@onready var bottom_left: RayCast2D = $Raycasts/HorizontalSmoothing/BottomLeft
@onready var step_max_left: RayCast2D = $Raycasts/HorizontalSmoothing/StepMaxLeft
@onready var left_accuracy: ShapeCast2D = $Raycasts/HorizontalSmoothing/LeftAccuracy

# Auto Enter Tunnel Raycasts
@onready var crouch_left: RayCast2D = $Raycasts/AutoTunnel/CrouchLeft
@onready var crouch_right: RayCast2D = $Raycasts/AutoTunnel/CrouchRight

# Speedometer / MISC Info
@onready var debug: Node2D = $Debug

# Respawn / Death Variables
@onready var starting_position = global_position

# Movement State Shit
var movement_data: PlayerMovementData
@onready var max_level: int = len(movement_states) - 1

## Movement Values
# Base Movement
var speed: float
var accel: float

# Stop distance
var stop_distance: float
var friction: float

var turn_distance: float
var turn_friction: float

# Adjust Slide Values
var slide_distance: float
var slide_friction: float

var hill_speed: float
var hill_accel: float

# Crouch Values
var longjump_velocity: float

# Air Speed
var air_speed: float
var air_accel: float
var air_stop_distance: float
var air_frict: float
var tunnel_jump_accel: float

# Projectile Motion / Jump Math
var jump_actual_height: float
var jump_velocity: float
var jump_gravity: float
var fall_gravity: float

# Wall Jump Unit Vector
var walljump_height: float
var walljump_distance: float

# Up Wall Jump Unit Vector
var up_walljump_height: float
var up_walljump_distance: float

# Down Wall Jump Unit Vector
var down_walljump_height: float
var down_walljump_distance: float

# Waal Jumps Gravity
var walljump_gravity: float
var up_walljump_gravity: float

# Wall Jump Velocities
var walljump_velocity_y: float
var walljump_velocity_x: float

# Up Wall Jump Velocities
var up_walljump_velocity_y: float
var up_walljump_velocity_x: float

# Down Wall Jump Velocities
var down_walljump_velocity_y: float
var down_walljump_velocity_x: float

# The velocity of our fast fall
var ff_velocity: float
var ff_gravity: float

# Animation Variable
var run_threshold: float


# Wall Jump States
var current_wj: WALLJUMPS = WALLJUMPS.NEUTRAL
var current_wj_dir: float = 0

# Various Player States Shared Across Bleh :3
var aerial: bool = false 				# Set every time the player leaves the ground, and reset every time they come back down
var fastFalling: bool = false			# Set when the player begins fast falling, reset on any state change
var airDriftDisabled: bool = false		# If air drift is disabled by an action this is set to true. Will be reset when falling
var turningAround: bool = false			# If the player is experiencing a change in direction
var has_glided: bool = false			# If the player has glided throughout their jump
var underWater: bool = false			# If the player is underwater
var fastFell: bool = false 				# If the player fastfell in the prev jump


# Jump Flags
var jumping: bool = false				# If the player is rising in a jump
var wallJumping: bool = false			# If the player is rising in a walljump
var crouchJumping: bool = false			# If the player is rising from a crouch jump
var boostJumping: bool = false			# If the player is boost jumping (active whole way through)
var launched: bool = false				# If the player is rising from being launched

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


# Persistent Data:
var can_glide: bool = false

# I'm Being really annoying about this btw
func _ready() -> void:

	if movement_states[0]:
		movement_data = movement_states[0]
	else:
		printerr("No Movement Data KYS")

	# I hate myself
	calculate_properties()

	# idk why this happens sometimes but on reset occasionally game gets confused
	set_standing_collider()

	glow_manager.startup()
	
	# Register the players save and load functions
	_persist.register_persistent_class("Flyph", Callable(self, "player_save"), Callable(self, "player_load"))

	# Initialize the State Machine pass us to it
	StateMachine.init(self)

func player_save() -> Dictionary:

	var save_data: Dictionary = {}

	save_data["glow_points"] = glow_manager.glow_points
	save_data["movement_level"] = glow_manager.movement_level
	save_data["glow_enabled"] = glow_manager.GLOW_ENABLED
	save_data["can_glide"] = can_glide
	

	return save_data

func player_load(save_data: Dictionary) -> void:

	add_glow(save_data["glow_points"])
	glow_manager.change_state(save_data["movement_level"])

	# Handle Glow enabling / disabling
	if save_data["glow_enabled"]:
		enable_glow()
	else:
		disable_glow()
	
	if save_data.has("can_glide"):	
		can_glide = save_data["can_glide"]
	else:
		can_glide = false

	


func _unhandled_input(event: InputEvent) -> void:

	# Log if a jump is pressed
	if Input.is_action_just_pressed("Jump") and not is_actor:
		jump_buffer = base_jump_buffer

	
		

	# For quickly chaning states
	if OS.is_debug_build():
		if Input.is_action_just_pressed("debug_up"):
			glow_manager.promote()
		if Input.is_action_just_pressed("debug_down") and glow_manager.movement_level > 0:
			glow_manager.demote()
		if Input.is_action_just_pressed("reset"):
			calculate_properties()

	# Pass The Input to the State Machine
	if not dying and not is_actor:
		StateMachine.process_input(event)



var base_jump_buffer: float = 0.125
var jump_buffer: float = -1

## Attempt to consume a jump buffer
# This will be called by the state machine when it wants to consume a jump buffer
# Returns True if the jump buffer was consumed
func attempt_jump(leniancy: float = 0.0) -> bool:
	
	if jump_buffer > -leniancy:
		consume_jump()
		return true
	return false

func update_buffer_timer(delta: float):
	# Cut off at 1 second
	if jump_buffer > -1:
		jump_buffer -= delta

# Uses up anything potentially in the jump buffer
func consume_jump() -> void:
	
	jump_buffer = -1
	
## This is used by the spring routine
func attempt_post_jump() -> bool:
	
	if post_jump_buffer.time_left > 0.0:
		post_jump_buffer.stop()
		return true
	return false

func animated_jump() -> void:
	jump_buffer = base_jump_buffer

# This is handled here
func set_input_axis(delta: float) -> void:
	
	# Ok for some reason my joystick is giving like 0.9998 which when holding left, which apparently
	# is enough for my player to move considerably slower than like i want them to... so built in UCF???
	# If we aren't an actor take user input
	if not is_actor:
		horizontal_axis = snappedf( Input.get_axis("Left", "Right"), 0.5 )
		vertical_axis = snappedf(Input.get_axis("Down", "Up"), 0.1 ) # idek if im gonna use this one lol

	if horizontal_axis == 0.5:
		horizontal_axis = 1.0
	elif horizontal_axis == -0.5:
		horizontal_axis = -1.0


	# If we've just pressed an input then unlock the direction (so silly players
	# can regain control if they want to)
	if Input.is_action_just_pressed("Right") or Input.is_action_just_pressed("Left"):
			lock_dir = false
			lock_time = 0
	if soft_lock and (Input.is_action_pressed("Right") or Input.is_action_pressed("Left")):
			lock_dir = false
			lock_time = 0

	# Update Lock Timer
	if lock_time > 0:
		lock_time -= delta
	else:
		lock_dir = false

	# If we're still locked then assign the locked value to input
	if lock_dir:
		horizontal_axis = hold_dir

	if horizontal_axis:
		print(horizontal_axis)
	




# If we are locking dir
var lock_dir: bool = false
# If the lock is overwritten easily
var soft_lock: bool = false
var hold_dir: float = 0.0
var lock_time: float = 0.5
## Locks the horizontal axis to a value for a given amount of time
func lock_h_dir(dir: float, time: float, soft: bool = false):
	
	soft_lock = soft
	lock_dir = true
	hold_dir = dir
	lock_time = time

func _physics_process(delta: float) -> void:

	_logger.info("Flyph - Physics Process Started")
	set_input_axis(delta)
	update_buffer_timer(delta)

	# Stop the players 'world' on death :3
	if not dying:

		# Calls the physics proceess
		StateMachine.process_physics(delta)
		
		

		# "Assists" in movement
		movement_assist(delta)

		# Store the velocity for next frame
		prev_velocity_x = velocity.x
		prev_velocity_y = velocity.y

		_logger.info("Pre-Move and Sliding")
		
		# Apply Velocities if we're in a velocity based state
		if StateMachine.current_state != WORMED_STATE:
			move_and_slide()
		
		_logger.info("Post Move and Sliding")

	_logger.info("Flyph Physics Process End")


		

func _process(delta: float) -> void:

	_logger.info("Flyph _process()")

	# If restarting the animation
	if restart_animation:
		animation.set_frame_and_progress(0,0)

	# Only update animations if we've changed animations
	if prev_animation != current_animation or restart_animation:
		update_animations()
		restart_animation = false

	# Store the current animation to be next frames previous animation
	prev_animation = current_animation

	# Let each component do their visual stuff
	if not dying:
		StateMachine.process_frame(delta)

	_logger.info("Flyph _process() end")



# Update the current animation based on the current_Animatino variable
# Just lets us keep animation changes in one place/in the draw function
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

		# Slide Animations
		ANI_STATES.SLIDE_PREP:
			animation.play("slide_prep")
		ANI_STATES.SLIDE_LOOP:
			animation.play("slide_loop")
		ANI_STATES.SLIDE_END:
			animation.play("slide_end")

		# Air/Jump Animations
		ANI_STATES.JUMP:
			animation.play("jump")
		ANI_STATES.FALLING:
			animation.play("falling")
		ANI_STATES.LANDING:
			animation.play("landing")
			
		# Water Animations
		ANI_STATES.PADDLE:
			animation.play("paddle")
			
		# Wall Animations
		ANI_STATES.WALL_HUG:
			animation.play("wall_hug")
		ANI_STATES.WALL_SLIDE:
			animation.play("wall_slide")
		ANI_STATES.WALL_JUMP:
			animation.play("wall_jump")



# When an animation ends
func _on_animated_sprite_2d_animation_finished():

	_logger.info("Flyph Animation Event")

	# Pass to the state machine
	StateMachine.animation_end()

	_logger.info("Flyph Animation Event End")

## Alternate Collider
# This method was the best way I could get the collider size to change
# Without having any weird clipping issues or anything being weird
func set_crouch_collider():
	collider.position = crouching_collider.position
	collider.shape.size = crouching_collider.shape.size


func set_standing_collider():
	collider.position = standing_collider.position
	collider.shape.size = standing_collider.shape.size


#  Player Assist Methods
#######################################
#######################################

func movement_assist(delta):

	# Corner Smoothing on jump
	if jumping and not is_on_wall(): jump_corner_correction(delta)

	# Help the player get up small ledges, if we're moving or holding a direction
	if (abs(horizontal_axis) > 0 or abs(velocity.x) > 0): horizontal_corner_correction(delta)

	# Auto Enter Tunnel
	if is_on_wall() and not underWater: auto_enter_tunnel()

	_logger.info("Exit assists function")



const JUMP_CORRECTION_FACTOR = 0.9

# Corrects the player's jump when near a ceiling to smooth out collisions.
# The strength of the correction is proportional to the rising velocity.
func jump_corner_correction(delta):

	

	var strength = abs(velocity.y) * JUMP_CORRECTION_FACTOR

	# Check for collisions on the top left and top right
	var is_colliding_left = top_left.is_colliding()
	var is_colliding_right = top_right.is_colliding()

	# Determine the direction of the correction based on where the collision is
	var correction_direction = 0
	if is_colliding_left and not is_colliding_right:
		correction_direction = 1
	elif not is_colliding_left and is_colliding_right:
		correction_direction = -1

	# Apply the correction if there's no collision in the direction we're moving
	if correction_direction != 0 and not test_move(global_transform, Vector2(strength * delta * correction_direction, 0)):
		_logger.info("Attempting Vertical Corner Correction")
		position.x += strength * delta * correction_direction
		squish_node.squish(jump_squash)



# TODO: Clean this up
# What allows the player to "smoothly"(lol) step up from small gaps
func horizontal_corner_correction(delta):

	# Ignore this if player is standing on a slant, not touching that with a 10 foot pole
	if get_floor_normal().x != 0:
		return

	# Adjust the Raycast Length based on usecase (if grounded step we need longer)
	if not is_on_floor():
		set_corner_snapping_length(1)
		
		# Only do this on rising
		if velocity.y >= 0:
			return
			
		
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

			# Return if nothing was found
			if right_accuracy.get_collision_count() == 0:
				return
				
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
				spawn_getup_dust(true)
				

			# Calculate the desired new position
			var test_y = move_toward(position.y, position.y-offset, delta * correction_speed)

			# Calculate the motion vector
			var motion = Vector2(0, test_y - position.y)

			# Check if the motion would cause a collision
			if not test_move(global_transform, motion):

				_logger.info("Attempting Horizontal Corner Correction")

				# If no collision, update the position
				position.y = test_y
				squish_node.squish( Vector2(1.2, 0.8))
				
				


	elif bottom_left.is_colliding() and not step_max_left.is_colliding():

		# If we are moviging in that direction or pressing that dir
		if (velocity.x < 0 or horizontal_axis < 0)  and round(bottom_left.get_collision_normal().x) == bottom_left.get_collision_normal().x:

			# Scan using the shape cast
			left_accuracy.force_shapecast_update()

			# Return if nothing was found
			if left_accuracy.get_collision_count() == 0:
				return

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
				spawn_getup_dust(false)
				

			# Attempt to smoothly
			# Calculate the desired new position
			var test_y = move_toward(position.y, position.y-offset, delta * correction_speed)

			# Calculate the motion vector
			var motion = Vector2(0, test_y - position.y)

			# Check if the motion would cause a collision
			if not test_move(global_transform, motion):

				_logger.info("Attempting Horizontal Corner Correction")

				# If no collision, update the position
				position.y = test_y
				squish_node.squish( Vector2(1.2, 0.8))

# func horizontal_smooth():

# Auto enter hole
func auto_enter_tunnel():

	

	var left_open: bool = not crouch_left.is_colliding() and not bottom_left.is_colliding()
	var right_open: bool = not crouch_right.is_colliding() and not bottom_right.is_colliding()

	var wall_on_left: bool = get_wall_normal().x > 0
	var wall_on_right: bool = get_wall_normal().x < 0

	if left_open and wall_on_left:
		enter_tunnel()

	elif right_open and wall_on_right:
		enter_tunnel()
	

func enter_tunnel():

		_logger.info("Shoving Player into Tunnel")
		
		set_crouch_collider()
		
		# Push player forward
		velocity.x = prev_velocity_x
		
		# Squish the player
		squish_node.squish(crouch_squash)

		# Set the flag
		crouchJumping = true
		

# Gadgets

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



## Visual Things

func spawn_jump_dust():
	
	# Give dust on landing
	generic_spawn_particles(JUMP_DUST, jump_dust_spawner)
	
func spawn_landing_dust():
	
	generic_spawn_particles(LANDING_DUST, landing_dust_spawner)
	
func spawn_getup_dust(left: bool):
	
	var new_particle = GET_UP_LEDGE.instantiate()
	new_particle.set_name("temp_particles")
	
	if left:
		new_particle.get_node("Dust").get_node("LeftDust").visible = false
	else:
		new_particle.get_node("Dust").get_node("RightDust").visible = false

	jump_dust_spawner.add_child(new_particle)
	var particle_animation = new_particle.get_node("AnimationPlayer")
	particle_animation.play("free")

# Spawns the given preloaded particle at the given marker
func generic_spawn_particles(particles: PackedScene, spawner: Marker2D):
	
	var new_particle = particles.instantiate()
	new_particle.set_name("temp_particles")
	spawner.add_child(new_particle)
	var particle_animation = new_particle.get_node("AnimationPlayer")
	particle_animation.play("free")
	
	
	
##  Glow State Functions
#######################################
#######################################

func connect_meter(update_score: Callable):
	
	glow_manager.connect("glow_meter_changed", update_score)

func connect_upgrade(promotion_ui_fx: Callable):

	glow_manager.connect("glow_promote", promotion_ui_fx)

## Enables the glow mechanic
func enable_glow():

	glow_manager.GLOW_ENABLED = true

## Disables and resets the glow mechanic
func disable_glow():

	# Reset our level and bleh :3
	glow_manager.change_state(0)
	#glow_manager.reset_score()
	glow_manager.GLOW_ENABLED = false

## Adds points to the players glow score
func add_glow(amount: float) -> void:
	glow_manager.add_score(amount)

## Force the glow to update score
func force_glow_update() -> void:
	glow_manager.calc_score()

## Set the players glow score
func set_glow_score(amount: float) -> void:
	glow_manager.glow_points = amount

## Get the players current glow score
func get_glow_score() -> float:
	return glow_manager.glow_points

## Get the players current glow level
func get_glow_level():
	return glow_manager.movement_level

## Enable Automatically using glow as soon as obtained
func enable_auto_glow():
	glow_manager.auto_glow = true

## Force the player to manually use glow
func disable_auto_glow():
	glow_manager.auto_glow = false

# Recalculated all the players movement properties
# Necessary because the player parameters are described in ways that are easier to measure, and quantify
# but also require some math in order to convert these parameters to the actual forces and changes in velocity
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
#	jump_buffer.wait_time = movement_data.JUMP_BUFFER
	momentum_time.wait_time = movement_data.STRICTNESS

	# Visual
	trail.length = movement_data.TRAIL_LENGTH
	run_threshold = movement_data.RUN_THRESHOLD * TILE_SIZE

	front_wing.set_wing_length(movement_data.WING_LENGTH+1)
	back_wing.set_wing_length(movement_data.WING_LENGTH)
	

	# Visual: Setting Glow and such
	light.set_brightness(movement_data.BRIGHTNESS)
	
	# The glow is leftover from when I was experimenting with using fancier rendering systems, and decided
	# it hurt performance too much.
	#trail.set_glow(movement_data.GLOW)
	#animation.set_glow(movement_data.GLOW)



## Player Movement Manipulation
#######################################
#######################################
# Pushes the player in the direction of the boost
func give_boost(boost_speed: float) -> void:

	velocity.x += boost_speed * horizontal_axis


var temp_gravity_active: bool = false
var temp_gravtity: float = 0.0

# Set a temporary gravity for launches/whatever else wants them
func set_temp_gravity(grav: float):

	temp_gravity_active = true
	temp_gravtity = grav

## Launches the player with the given velocity, and a specified gravity
func launch(launch_velocity: Vector2, gravity: float = -1, squash: Vector2 = Vector2.ZERO):

	# Launch Force
	velocity = launch_velocity

	# Set our flags
	launched = true

	# Remove all extranous Jump Flags :3
	jumping = false
	crouchJumping = false
	boostJumping = false
	
	fastFalling = false
	fastFell = false
	
	# Enable gliding out of this
	has_glided = false

	# If a custom gravity is given, set it
	if gravity != -1:
		set_temp_gravity(gravity)

	# If a squash is given, squash the player
	if (squash != Vector2.ZERO):
		squish_node.squish(squash)
		
	# Restart whatever animation we're in
	# That way we either restart the air movements, or restart running
	restart_animation = true
		
	consume_jump()

	#velocity += boost  * horizontal_axis

## DEATH RELATED METHODS!
# Whatever we need to do when the player dies can be called here
func kill():

	# Prevent double calls mid death
	if dying: return

	# Reset the trail
	trail.clear_points()

	# DEATH EXPLOSION
	Input.start_joy_vibration(1, 0.1, 0.2, 0.2)
	var new_cloud = DEATH_DUST.instantiate()
	new_cloud.set_name("death_dust_temp")
	deathDust.add_child(new_cloud)
	var death_animation = new_cloud.get_node("AnimationPlayer")
	death_animation.play("Start")

	# Squish the player
	squish_node.squish(Vector2(0.5, 0.5))

	# Hide Sprite
	squish_node.visible = false
	
	# Turn off particles
	glow_aura.emitting = false
	promotion_fx.emitting = false
	wall_slide_dust.emitting = false
	
	slide_dust.emitting = false
	dash_dust.emitting = false
	mega_speed_particles.emitting = false

	# Disable SFX
	run_sfx.stop()
	sliding_sfx.stop()
	wall_slide_sfx.stop()
	
	dying = true
	
	if StateMachine.current_state == WORMED_STATE:
		StateMachine.change_state(AERIAL_STATE)

	$Physics/HazardDetector.set_collision_mask_value(5, false)

	# Restart and disable the glow mechanic
	glow_manager.reset_glow()
	glow_manager.GLOW_ENABLED = false

	# Wait 1.5 seconds
	await get_tree().create_timer(1.5).timeout

	# Move the player / camera to the starting position
	global_position = starting_position
	
	$Physics/HazardDetector.set_collision_mask_value(5, true)
	
	# Zero out the velocity
	velocity = Vector2.ZERO
	
	# Let any Listeners know we dead
	emit_signal("dead")

	# Respawn Animation
	var respawn_cloud = RESPAWN_DUST.instantiate()
	respawn_cloud.set_name("Respawn_dust_temp")
	deathDust.add_child(respawn_cloud)
	var respawn_animation = respawn_cloud.get_node("AnimationPlayer")
	respawn_animation.play("Start")

	# Wait 0.7 seconds
	await get_tree().create_timer(0.7).timeout
	
	# Renable the player
	glow_manager.GLOW_ENABLED = true

	# Make Flyph Visible, then immediately squash them
	squish_node.visible = true
	squish_node.squish(death_squash)

	# Update, the stats
	_stats.DEATHS += 1

	# Give control back to the player
	dying = false


## Connect given callable to be called on death
func connect_to_death(method: Callable):
	
	connect("dead", method)

# Ways of death:
func _on_hazard_detector_area_entered(_area):
	if not dying:
		kill()

func _on_hazard_detector_body_entered(_body):
	if not dying:
		kill()

# Sets the given points as the players respawn point
func set_respawn_point(point: Vector2):
	starting_position = point


## Debug Methods:


## Event Based State Changes

## Water Detection
func _on_water_detector_body_entered(body):
	
	# Prevent double entries.... its weird, this shouldn't
	# happen as long as im smart but sometimes,,,
	if not underWater:
		underWater = true
		StateMachine.change_state(WATERED_STATE)


var disable_walljump: bool = false
func _on_water_detector_body_exited(body):
	
	# Aerial Feels like the best bet
	
	#consume_jump()
	StateMachine.change_state(AERIAL_STATE)
	underWater = false
	
	# Wait 0.5 seconds before flipping the flag
	disable_walljump = true
	await get_tree().create_timer(0.25).timeout
	disable_walljump = false


## Rope Detection
var stuck_segment: SpitSegment = null
func enter_rope(segment: SpitSegment):
	
	_logger.info("Grabbing Rope")
	stuck_segment = segment
	segment.player_grabbed()
	StateMachine.change_state(WORMED_STATE)
	_logger.info("Grabbed Rope")



# When the player enters a rope
func _on_rope_detector_body_entered(body):
	
	_logger.info("Rope Detected")
	var segment = body as SpitSegment
	if segment and not stuck_segment and not dying:
		enter_rope(segment)
