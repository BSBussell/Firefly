extends PlayerState

@export_subgroup("DEPENDENT STATES")
@export var WALL_STATE: PlayerState = null
#@export var GROUNDED_STATE: PlayerState = null
@export var AERIAL_STATE: PlayerState = null


# Water Properties
@export_category("Water Properties")
@export var WATER_ENTRY_COST: float
@export var WATER_MODULATION: Color
@export var WATER_SPEED_MULTI: float
@export var WATER_ACCEL_MULTI: float
@export var WATER_JUMP_MULTI: float


@export var WATER_GRAV_MULTI: float
@export var MAX_FALL_MULTI: float

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
@onready var speed_particles = $"../../Particles/MegaSpeedParticles"
@onready var jump_dust = $"../../Particles/JumpDustSpawner"
@onready var jumping_sfx = $"../../Audio/JumpingSFX"
@onready var wet = $"../../Particles/Wet"


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
		print("Water State")

	
	if parent.velocity.y > 150:
		parent.velocity.y *= WATER_ENTRY_COST

	# Make Them BLUE!!!
	parent.animation.set_glow(WATER_MODULATION, 1.0)

	# TODO: Water distortion shader

	# Reset our flags/counters
	shopped = false
	ticks = 0
	min_fall_speed = 0.0
	parent.aerial = true

	# Enabling the appropriate Raycasts
	right_wj_grace.enabled = true
	left_wj_grace.enabled = true

	# Corner correcting raycast
	top_right.enabled = true
	top_left.enabled = true
	
	parent.set_standing_collider()

	

	slide_fall = parent.current_animation == parent.ANI_STATES.CRAWL

	if not slide_fall:
		print("Current Animation: ", parent.current_animation)

	# Put us in the falling animation if we are not crouch jumping, jumping, or if we're launched
	if (not slide_fall) or (not parent.crouchJumping and parent.boostJumping) or parent.launched:
		parent.current_animation = parent.ANI_STATES.FALLING
		parent.restart_animation = true
		
	
	# Splash :3
	var new_cloud = parent.SPLASH.instantiate()
	new_cloud.set_name("splash_temp")
	splash_spawner.add_child(new_cloud)
	var animation = new_cloud.get_node("AnimationPlayer")
	animation.play("free")

	# This is gonna be sick
	# Enable Water Audio Filers
	var bus_idx = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_effect_enabled(bus_idx, 1, true)
	AudioServer.set_bus_effect_enabled(bus_idx, 2, true)

	


# Called before exiting the state, cleanup
func exit() -> void:

	

	# Disable appropriate raycasts
	right_wj_grace.enabled = false
	left_wj_grace.enabled = false

	# Corner correcting raycast (just making sure they off)
	top_right.enabled = false
	top_left.enabled = false

	# And any potentially on particles
	speed_particles.emitting = false


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

	# Set the modulation to the default
	parent.animation.set_glow(parent.movement_data.GLOW, 2)

	# Enable Water Audio Filers
	var bus_idx = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_effect_enabled(bus_idx, 1, false)
	AudioServer.set_bus_effect_enabled(bus_idx, 2, false)

	wet.emitting = true
	await get_tree().create_timer(1.3).timeout
	wet.emitting = false
	
	


# Processing input in this state, returns nil or new state
func process_input(_event: InputEvent) -> PlayerState:

	# If Fast Falling Input
	if Input.is_action_just_pressed("Down"):
		parent.fastFalling = true
		parent.animation.speed_scale = 2.0
		if parent.temp_gravity_active:
			parent.temp_gravity_active = false
			parent.velocity.y = max(parent.jump_velocity * 0.5, parent.velocity.y)


	# If we are crouch jumping, let go of down, and have standing room.
	var in_crouch = parent.current_animation == parent.ANI_STATES.CRAWL
	if in_crouch and not Input.is_action_pressed("Down") and have_stand_room():

		parent.crouchJumping = false
		parent.current_animation = parent.ANI_STATES.FALLING

		parent.set_standing_collider()



	return null

# Processing Physics in this state, returns nil or new state
func process_physics(delta: float) -> PlayerState:

	apply_gravity(delta)

	# Grace Jumps
	
	handle_grace_walljump()
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

	# Fall squishing :3
	if parent.velocity.y > 0:
		var spriteBlend = min(parent.velocity.y / parent.movement_data.MAX_FALL_SPEED, 1)
		var squishVal = Vector2()
		squishVal.x = lerp(1.0, parent.falling_squash.x, spriteBlend)
		squishVal.y =  lerp(1.0, parent.falling_squash.y, spriteBlend)
		parent.squish_node.squish(squishVal)


	# Direction Facing, don't update if we're walljumping up
	if not (parent.wallJumping and parent.current_wj == parent.WALLJUMPS.UPWARD):
		if parent.velocity.x < 0 and not parent.animation.flip_h:
			parent.animation.flip_h = true
			parent.squish_node.squish(parent.turn_around_squash)

		elif parent.velocity.x > 0 and parent.animation.flip_h:
			parent.animation.flip_h = false
			parent.squish_node.squish(parent.turn_around_squash)

	# Speed Particle Emission
	if abs(parent.velocity.x) > parent.air_speed + parent.movement_data.JUMP_HORIZ_BOOST or parent.temp_gravity_active:
		speed_particles.emitting = true
		speed_particles.direction.x = 1 if (parent.animation.flip_h) else -1
	else:
		speed_particles.emitting = false

	pass

## Called when an animation ends. How we handle transitioning to different animations
func animation_end() -> PlayerState:

	# If Jump Anim ends go to Falling
	if (parent.current_animation == parent.ANI_STATES.JUMP):
		parent.current_animation = parent.ANI_STATES.FALLING

	# If falling ends pause the animation
	if parent.current_animation == parent.ANI_STATES.FALLING:
		parent.restart_animation = true
		#parent.animation.pause()

	return null

func handle_water_jump(_delta):

	# If we are able to do a coyote jump
	if not parent.launched:

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

	# Add a Horizontal Jump Boost to our players X velocity
	parent.velocity.x += parent.movement_data.JUMP_HORIZ_BOOST * parent.horizontal_axis

	# Jump Velocity
	parent.velocity.y = parent.jump_velocity * WATER_JUMP_MULTI

	# Splash :3
	#var new_cloud = parent.SPLASH.instantiate()
	#new_cloud.set_name("splash_temp")
	#splash_spawner.add_child(new_cloud)
	#var animation = new_cloud.get_node("AnimationPlayer")
	#animation.play("free")

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

		print("Released")

		# If we aren't already below ff_velocity
		if parent.velocity.y < parent.ff_velocity:

			shopped = true

			# Begin descent at this velocity
			parent.velocity.y = parent.ff_velocity



# Pretty much set all jump bools to false when falling
func update_jump_flags() -> void:

	# Disabling Wall Jumping flags if we're falling
	if parent.velocity.y > 0:

		# Wall Jump Flags
		if parent.wallJumping:
			# Player has started falling, reset wall jump state
			parent.wallJumping = false
			parent.current_wj = parent.WALLJUMPS.NEUTRAL

		# temp grav
		if parent.temp_gravity_active:
			parent.temp_gravity_active = false
		
		# launched
		if parent.launched:	
			parent.launched = false

		# Jumping flag
		if parent.jumping:
			parent.jumping = false

# Gets the gravity to apply
func get_gravity() -> float:

	update_jump_flags()

	# Default gravity is fall gravity
	var gravity_to_apply = parent.fall_gravity

	var rising = parent.jumping or parent.boostJumping

	# If we're wall jumping
	if parent.wallJumping:
		# Apply the correct wall jump gravity
		match parent.current_wj:
			parent.WALLJUMPS.NEUTRAL:
				gravity_to_apply = parent.walljump_gravity
			parent.WALLJUMPS.UPWARD:
				gravity_to_apply = parent.up_walljump_gravity

	# If we're rising
	
	elif rising and not shopped:
		# Apply rising gravity
		gravity_to_apply = parent.jump_gravity

	# If we're fast falling
	elif parent.fastFalling:
		# Apply fast falling gravity
		gravity_to_apply = parent.ff_gravity

	# Temp Gravity Overrides All
	if parent.temp_gravity_active:
		gravity_to_apply = parent.temp_gravtity


	# Add a bit of float if we haven't shopped
	if abs(parent.velocity.y) < 40 and Input.is_action_pressed("Jump") and not parent.crouchJumping and not parent.boostJumping:
		gravity_to_apply *= 0.5

	return gravity_to_apply

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
			waterAccel = parent.movement_data.AIR_SPEED_RECUTION

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
		parent.velocity.x = move_toward(parent.velocity.x, 0, parent.air_frict * delta)


# Checks the above raycasts
func have_stand_room():
	return not (stand_room_left.is_colliding() or stand_room_right.is_colliding())
