extends PlayerState

const WAVE_PARTICLE: PackedScene = preload("res://Scenes/Player/particles/waves.tscn")

@export_subgroup("DEPENDENT STATES")
@export var WALL_STATE: PlayerState = null
#@export var GROUNDED_STATE: PlayerState = null
@export var AERIAL_STATE: PlayerState = null


# Water Properties
@export_category("Water Properties")
@export var WATER_ENTRY_COST: float = 0.3
@export var WATER_MODULATION: Color
@export var WATER_SPEED_MULTI: float = 0.7
@export var WATER_ACCEL_MULTI: float = 0.8
@export var WATER_JUMP_MULTI: float = 0.8
@export var WATER_DIVE_MULTI: float = -0.7


@export var WATER_GRAV_MULTI: float = 0.15
@export var MAX_FALL_MULTI: float = -0.3

# Splash Spawner
@onready var splash_spawner = $"../../Particles/LandingDustSpawner"

# WallJump Checkers
@onready var right_wj_grace = $"../../Raycasts/Right_WJ_Grace"
@onready var left_wj_grace = $"../../Raycasts/Left_WJ_Grace"

# Jump Corner Correctors
@onready var top_left = $"../../Raycasts/VerticalSmoothing/TopLeft"
@onready var top_right = $"../../Raycasts/VerticalSmoothing/TopRight"

# Check if room for standing up
@onready var stand_room_left = $"../../Raycasts/Colliders/Stand_Room_Left"
@onready var stand_room_right = $"../../Raycasts/Colliders/Stand_Room_Right"

# Effects
@onready var jump_dust = $"../../Particles/JumpDustSpawner"
@onready var jumping_sfx = $"../../Audio/JumpingSFX"
@onready var wet = $"../../Particles/Wet"
@onready var wave_spawner = $"../../Particles/WaveSpawner"

# Timer
@onready var dive_cool_down = $"../../Timers/DiveCoolDown"


# SFX
@onready var light_splash_sfx = $"../../Audio/LightSplashSFX"
@onready var swimming_sfx = $"../../Audio/SwimmingSFX"
@onready var out_of_water_sfx = $"../../Audio/OutOfWaterSFX"


var is_wet = false

# Measuring the players fall speed for squish-matics
var min_fall_speed = 0.0


# Count of how much time has passed
var ticks: float = 0

# Keep track of if we have short hopped.
var shopped: bool = false

# Set if we are falling after a slide
var slide_fall: bool = false

# Called on state entrance, setup
func enter() -> void:
	
	wet.emitting = false

	if OS.is_debug_build():
		_logger.info("Water State")

	
	if parent.velocity.y > 150:
		parent.velocity.y *= WATER_ENTRY_COST
	
	if parent.velocity.x > parent.air_speed:
		parent.velocity.x *= WATER_ENTRY_COST

	# Make Them BLUE!!!
	parent.animation.set_glow(WATER_MODULATION, 1.0)

	# TODO: Water distortion shader

	# Reset our flags/counters
	shopped = false
	ticks = 0
	min_fall_speed = 0.0
	parent.aerial = true
	parent.fastFalling = false
	parent.fastFell = true

	# Enabling the appropriate Raycasts
	right_wj_grace.enabled = true
	left_wj_grace.enabled = true

	# Corner correcting raycast
	top_right.enabled = true
	top_left.enabled = true
	
	parent.set_standing_collider()

	#dive_cool_down.stop()

	slide_fall = parent.current_animation == parent.ANI_STATES.CRAWL

	# Put us in the falling animation if we are not crouch jumping, jumping, or if we're launched
	if (not slide_fall) or (not parent.crouchJumping and parent.boostJumping) or parent.launched:
		parent.current_animation = parent.ANI_STATES.PADDLE
		parent.restart_animation = true
		
	
	# Splash :3
	var new_cloud = parent.SPLASH.instantiate()
	new_cloud.set_name("splash_temp")
	splash_spawner.add_child(new_cloud)
	var animation = new_cloud.get_node("AnimationPlayer")
	animation.play("free")

	# SFX
	light_splash_sfx.play()
	swimming_sfx.play()

	# Enable Water Audio Filers
	_audio.enable_underwater_fx()
	


# Called before exiting the state, cleanup
func exit() -> void:

	

	# Disable appropriate raycasts
	right_wj_grace.enabled = false
	left_wj_grace.enabled = false

	# Corner correcting raycast (just making sure they off)
	top_right.enabled = false
	top_left.enabled = false


	# If we're fast falling set the speed scale back and reset the flags
	if (parent.fastFalling):

		parent.fastFalling = false
		parent.animation.speed_scale = 1.0

	# Splash :3
	var new_cloud = parent.SPLASH.instantiate()
	new_cloud.set_name("splash_temp")
	splash_spawner.add_child(new_cloud)
	var animation = new_cloud.get_node("AnimationPlayer")
	animation.play("free")

	# SFX
	if get_tree():
		out_of_water_sfx.play()
		swimming_sfx.stop()

	# Set the modulation to the default
	parent.animation.set_glow(parent.movement_data.GLOW, 2)

	# disable Water Audio Filters
	_audio.disable_underwater_fx()
	
	wet.emitting = true
	
	if get_tree():
		await get_tree().create_timer(1.3).timeout
		
	wet.emitting = false
	
	


# Processing input in this state, returns nil or new state
func process_input(_event: InputEvent) -> PlayerState:

	# If Fast Falling Input
	#if Input.is_action_just_pressed("Dive"):
		#water_dive()

	return null

# Processing Physics in this state, returns nil or new state
func process_physics(delta: float) -> PlayerState:

	apply_gravity(delta)

	# Grace Jumps
	
	#handle_grace_walljump()
	handle_water_jump(delta)

	# For Short Hops
	handle_sHop(delta)

	# Horizontal Motion
	handle_acceleration(delta, parent.horizontal_axis)
	apply_airResistance(delta, parent.horizontal_axis)

	# Increment the Time count
	ticks += delta

	# Check if we've found a new min fall speed
	min_fall_speed = min(min_fall_speed, parent.velocity.y)

	# Water State Change Handled by the Water Detection
	return null





func process_frame(_delta):

	swimming_sfx.play(swimming_sfx.get_playback_position())

	# Direction Facing, don't update if we're walljumping up
	if not (parent.wallJumping and parent.current_wj == parent.WALLJUMPS.UPWARD):
		if parent.velocity.x < 0 and not parent.animation.flip_h:
			parent.animation.flip_h = true
			parent.squish_node.squish(parent.turn_around_squash)

		elif parent.velocity.x > 0 and parent.animation.flip_h:
			parent.animation.flip_h = false
			parent.squish_node.squish(parent.turn_around_squash)

## Called when an animation ends. How we handle transitioning to different animations
func animation_end() -> PlayerState:

	# If Jump Anim ends go to Falling
	if (parent.current_animation == parent.ANI_STATES.JUMP):
		parent.current_animation = parent.ANI_STATES.FALLING

	# If falling ends pause the animation
	if parent.current_animation == parent.ANI_STATES.PADDLE:
		parent.current_animation = parent.ANI_STATES.FALLING
		#parent.animation.pause()
		
	if parent.current_animation == parent.ANI_STATES.FALLING:
		parent.restart_animation = true

	return null

func handle_water_jump(_delta):

	# If we are able to do a coyote jump
	if not parent.launched and dive_cool_down.is_stopped():

		# If the player has buffered a jump
		if parent.attempt_jump():

			# Update Animation State if we aren't holding crawl still
			if (parent.current_animation != parent.ANI_STATES.CRAWL):
				parent.current_animation = parent.ANI_STATES.FALLING

			water_jump()


#perform coyote jump
func water_jump():

	# Set Flags
	parent.jumping = true
	
	
	var jump_force: float = parent.jump_velocity * WATER_JUMP_MULTI
	
	# Calculate the direction vector based on input
	var input_direction: Vector2 = Vector2(-parent.horizontal_axis, parent.vertical_axis)

	if input_direction == Vector2.ZERO:
		input_direction = Vector2(0, 1)
	elif input_direction.y == 0:
		input_direction.y = 0.15 
		

	#if parent.vertical_axis >= 1:
		#parent.velocity.y = 0

	# Normalize the direction vector if it has any magnitude to avoid zero-vector issues
	if input_direction != Vector2.ZERO:
		input_direction = input_direction.normalized()

	# Scale the direction by the jump velocity and multiplier
	var jump_velocity_vector: Vector2 = input_direction * jump_force

	print(input_direction)

	# Apply the jump velocity to the parent's velocity
	if sign(parent.velocity.x) != sign(jump_velocity_vector.x):
		parent.velocity.x += jump_velocity_vector.x
	else:
		parent.velocity.x = jump_velocity_vector.x
	
	
	if jump_velocity_vector.y != 0:
		parent.velocity.y = jump_velocity_vector.y

	dive_cool_down.start()

	# Add a Horizontal Jump Boost to our players X velocity
	#parent.velocity.x += parent.movement_data.JUMP_HORIZ_BOOST * parent.horizontal_axis

	# Jump Velocity
	#parent.velocity.y = parent.jump_velocity * WATER_JUMP_MULTI

	make_wave(input_direction)
	
	# TODO: Water Jump :3
	# Jump SFX
	jumping_sfx.play(0)
	
	
	parent.squish_node.squish(Vector2(0.8, 1.2))
	
	# Animation
	parent.current_animation = parent.ANI_STATES.PADDLE
	parent.restart_animation = true

func water_dive():
	
	# Set Flags
	parent.jumping = true

	# Add a Horizontal Jump Boost to our players X velocity
	parent.velocity.x += parent.movement_data.JUMP_HORIZ_BOOST * parent.horizontal_axis

	# Jump Velocity
	parent.velocity.y = parent.jump_velocity * WATER_DIVE_MULTI

	
	# TODO: Water Jump :3
	# Jump SFX
	jumping_sfx.play(0)
	
	
	parent.squish_node.squish(Vector2(0.8, 1.2))
	
	# Animation
	parent.current_animation = parent.ANI_STATES.FALLING
	
	parent.restart_animation = true
	

func handle_grace_walljump() -> void:

	# If we aren't being launched and aren't crouch jumping
	if not parent.launched:

		# Remove the normal wall jumps, only up or down here
		var wall_jump_manip: float = parent.vertical_axis
		if wall_jump_manip == 0:
			wall_jump_manip = 1.0

		# Check the shapecasts and call the walljump if we're in it
		if right_wj_grace.is_colliding() and round(right_wj_grace.get_collision_normal(0).x) == right_wj_grace.get_collision_normal(0).x :
			WALL_STATE.handle_walljump(wall_jump_manip, -1)
		elif left_wj_grace.is_colliding() and round(left_wj_grace.get_collision_normal(0).x) == left_wj_grace.get_collision_normal(0).x:
			WALL_STATE.handle_walljump(wall_jump_manip, 1)



# Whenever the player releases Jump the velocity is set to ff_velocity.
# This is intended to be less than jump velocity. So that they can kinda get closer to their descent faster
func handle_sHop(_delta):

	# If we were launched disable shopp
	if parent.launched:
		shopped = false

	# Otherwise if we let go of jump, decrease their velocity
	elif Input.is_action_just_released("Jump"):

		# If we aren't already below ff_velocity
		if parent.velocity.y < parent.ff_velocity:

			shopped = true

			# Begin descent at this velocity
			parent.velocity.y = parent.ff_velocity



func apply_gravity(delta) -> void:
	
	var max_fall_speed: float = parent.movement_data.MAX_FALL_SPEED * MAX_FALL_MULTI

	var base_gravity: float = AERIAL_STATE.get_gravity()
	var water_grav: float = base_gravity * WATER_GRAV_MULTI
	
	parent.velocity.y = move_toward(parent.velocity.y, max_fall_speed, -water_grav * delta)


## Addes Acceleration when the player holds a direction
func handle_acceleration(delta, direction) -> void:

	# If we're moving in a direction
	if direction:

		var waterSpeed: float
		var waterAccel: float

		# Slowing ourselves down in the air
		if (abs(parent.velocity.x) > parent.air_speed and sign(parent.velocity.x) == sign(direction)):
			waterAccel = parent.movement_data.AIR_SPEED_RECUTION * 1.0 		

		# Speed ourselves up
		else:
			waterAccel = AERIAL_STATE.get_airdrift(direction)

		waterAccel *= WATER_ACCEL_MULTI
		waterSpeed = parent.air_speed * WATER_SPEED_MULTI

		parent.velocity.x  = move_toward(parent.velocity.x, waterSpeed*direction, waterAccel * delta)

	#cj_clamp()


# Clamp the airspeed if the player is crouch jumping after a specific time
func cj_clamp():

	# The time window for releasing the down button
	var crouch_release_window: float = 0.0/60.0

	if parent.crouchJumping:

		# The time window for releasing the down button
		crouch_release_window = 1.0/60.0

		# So they have that much time to release down before velocity is capped
		# I have this because I don't like the idea of players flying around in crouch
		# And also I found that the motion of releasing crouch felt inline with
		if ticks >= crouch_release_window:

			# Hard clamp the velocity if they don't release 'down' in time
			parent.velocity.x = clamp(parent.velocity.x, -abs(parent.air_speed), parent.air_speed)


# How quickly we stop the playing moving if they drop the stick
func apply_airResistance(delta, direction):

	# Ok this makes the game really slippery when changing direction
	if direction == 0:
		parent.velocity.x = move_toward(parent.velocity.x, 0, parent.air_frict * delta * 0.5)


func make_wave(dir: Vector2) -> void:
	var burst_particle: BurstParticle = WAVE_PARTICLE.instantiate()
	burst_particle.direction = dir.normalized()
	wave_spawner.add_child(burst_particle)

# Checks the above raycasts
func have_stand_room():
	return not (stand_room_left.is_colliding() or stand_room_right.is_colliding())
