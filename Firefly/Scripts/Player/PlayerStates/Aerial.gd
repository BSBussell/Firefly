extends PlayerState

@export_subgroup("TRANSITIONAL STATES")
@export var GLIDE_STATE: PlayerState = null
@export var WALL_STATE: PlayerState = null
@export var GROUNDED_STATE: PlayerState = null
@export var SLIDING_STATE: PlayerState = null

# Timers
@export_subgroup("Input Assistance Timers")
@export var coyote_time: Timer
@export var jump_buffer: Timer



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

	if OS.is_debug_build():
		_logger.info("Flyph - Aerial State")

	# Reset our flags/counters
	shopped = false
	ticks = 0
	min_fall_speed = 0.0
	parent.aerial = true
	
	parent.fastFell = false

	# Enabling the appropriate Raycasts
	right_wj_grace.enabled = true
	left_wj_grace.enabled = true

	# Corner correcting raycast
	top_right.enabled = true
	top_left.enabled = true


	slide_fall = parent.current_animation == parent.ANI_STATES.CRAWL


	# Put us in the falling animation if we are not crouch jumping, jumping, or if we're launched
	if (not slide_fall) or (not parent.crouchJumping and parent.boostJumping) or parent.launched:
		parent.current_animation = parent.ANI_STATES.FALLING

	


# Called before exiting the state, cleanup
func exit() -> void:

	# Disable appropriate raycasts
	right_wj_grace.enabled = false
	left_wj_grace.enabled = false

	# Corner correcting raycast (just making sure they off)
	top_right.enabled = false
	top_left.enabled = false

	# And any potentially on particles
	#speed_particles.emitting = false


	# If we're fast falling set the speed scale back and reset the flags
	if (parent.fastFalling):

		#parent.fastFalling = false
		parent.animation.speed_scale = 1.0

	_logger.info("Exiting Aerial State")


# Processing input in this state, returns nil or new state
func process_input(_event: InputEvent) -> PlayerState:

	_logger.info("Aerial State Input")

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


	# If we press jump again then we play the gliding state
	if Input.is_action_just_pressed("Jump") and can_glide():
		return GLIDE_STATE

	_logger.info("Aerial State Input End")

	return null

# We can glide if we cant coyote jump nemore or if we cant wall jump
func can_glide() -> bool:
	return coyote_time.time_left <= 0.0 and not (left_wj_grace.is_colliding() or right_wj_grace.is_colliding()) and not parent.launched and parent.   can_glide

# Processing Physics in this state, returns nil or new state
func process_physics(delta: float) -> PlayerState:

	_logger.info("Flyph - Aerial State Physics")

	apply_gravity(delta)

	# Grace Jumps
	handle_coyote(delta)
	handle_grace_walljump()

	# For Short Hops
	handle_sHop(delta)

	# Horizontal Motion
	handle_acceleration(delta, parent.horizontal_axis)
	apply_airResistance(delta, parent.horizontal_axis)

	# Increment the Time count
	ticks += delta

	# Check if we've found a new min fall speed
	min_fall_speed = min(min_fall_speed, parent.velocity.y)

	_logger.info("Flyph - Aerial State Physics End")

	# Get Potential exit state from state status
	return state_status()


func state_status():

	_logger.info("Flyph - Aerial State Checking for State Transition")

	# Make Sure we're still grounded after this
	if parent.is_on_floor() and parent.velocity.y >= 0  :

		# If we've gone from aerial to on the floor
		parent.landing_speed = min_fall_speed
		Input.start_joy_vibration(1, 0.1, 0.08, 0.175)

		# If we're falling (not mid launch) then swap to this
		# That way 
		if parent.velocity.y >= 0:
			parent.boostJumping = false
			parent.launched = false


		# If we're pressing down and have standing room go into a slide
		if Input.is_action_pressed("Down") or not have_stand_room():
			_logger.info("Aerial State -> Sliding State")
			return SLIDING_STATE

		# We just land otherwise
		else:
			_logger.info("Flyph Aerial State -> Grounded State")
			return GROUNDED_STATE

	# If we're on the wall
	elif parent.is_on_wall_only():

		_logger.info("Flyph Aerial State -> Wall State")
		return WALL_STATE

	# Contigency
	if parent.velocity.x == 0 and not have_stand_room():
		_logger.info("Contingency Aerial State -> Sliding State")
		return SLIDING_STATE

	_logger.info("Flyph Aerial State -> Null")
	return null


func process_frame(_delta):

	_logger.info("Aerial State Frame")

	# Fall squishing :3
	if parent.velocity.y > 0 and not parent.launched:
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
			

	_logger.info("Aerial State Frame End")

## Called when an animation ends. How we handle transitioning to different animations
func animation_end() -> PlayerState:

	# If Jump Anim ends go to Falling
	if (parent.current_animation == parent.ANI_STATES.JUMP):
		parent.current_animation = parent.ANI_STATES.FALLING

	# If falling ends pause the animation
	if parent.current_animation == parent.ANI_STATES.FALLING:
		parent.animation.pause()

	return null

func handle_coyote(_delta):

	# If we are able to do a coyote jump
	if coyote_time.time_left > 0.0 and not parent.launched or _config.get_setting("inf_jump"):

		

		# If the player has buffered a jump
		if parent.attempt_jump():
			
			shopped = false
			
			# If we have used inf jump make the run invalid, sorry
			if _config.get_setting("inf_jump"):
				_stats.INVALID_RUN = true

			# Update Animation State if we aren't holding crawl still
			if (parent.current_animation != parent.ANI_STATES.CRAWL):
				parent.current_animation = parent.ANI_STATES.FALLING


			# See if we're able to boost Jump
			if (SLIDING_STATE.can_boost_jump() and slide_fall):
				SLIDING_STATE.boost_jump()
				ticks = 0
				return

			coyote_jump()


#perform coyote jump
func coyote_jump():

	# Set Flags
	parent.jumping = true

	# Add a Horizontal Jump Boost to our players X velocity
	parent.velocity.x += parent.movement_data.JUMP_HORIZ_BOOST * parent.horizontal_axis

	# Jump Velocity
	parent.velocity.y = parent.jump_velocity

	# Play Jump Cloud
	var new_cloud = parent.JUMP_DUST.instantiate()
	new_cloud.set_name("jump_dust_temp")
	jump_dust.add_child(new_cloud)
	var animation = new_cloud.get_node("AnimationPlayer")
	animation.play("free")

	# Jump SFX
	jumping_sfx.play(0)

func handle_grace_walljump() -> void:

	# If we aren't being launched and aren't crouch jumping
	if not parent.launched and not parent.crouchJumping:

		# Check the shapecasts and call the walljump if we're in it
		if right_wj_grace.is_colliding() and round(right_wj_grace.get_collision_normal(0).x) == right_wj_grace.get_collision_normal(0).x :
			WALL_STATE.handle_walljump(parent.vertical_axis, -1)
		elif left_wj_grace.is_colliding() and round(left_wj_grace.get_collision_normal(0).x) == left_wj_grace.get_collision_normal(0).x:
			WALL_STATE.handle_walljump(parent.vertical_axis, 1)



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
	
	var max_fall_speed: float = parent.movement_data.MAX_FALL_SPEED
	
	if parent.fastFalling:
		max_fall_speed = parent.movement_data.MAX_FF_SPEED

	parent.velocity.y = move_toward(parent.velocity.y, max_fall_speed, -get_gravity() * delta)


## Addes Acceleration when the player holds a direction
func handle_acceleration(delta, direction) -> void:

	# If we're moving in a direction
	if direction:

		var airAccel: float


		# Slowing ourselves down in the air
		if (abs(parent.velocity.x) > parent.air_speed and sign(parent.velocity.x) == sign(direction)):
			airAccel = parent.movement_data.AIR_SPEED_RECUTION

		# Speed ourselves up
		else:
			airAccel = get_airdrift(direction)

		parent.velocity.x  = move_toward(parent.velocity.x, parent.air_speed*direction, airAccel * delta)

	cj_clamp()


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

# Returns the airdrift/airacceleration
func get_airdrift(direction: float) -> float:

	var airDrift = parent.air_accel


	# If air drift has been disabled then set it to 0
	if parent.airDriftDisabled:
		airDrift = 0

	# If we are wall jumping up and holding into a wall we give a boost in air accel in order to help
	# with climbing / make it possible
	elif parent.wallJumping and parent.current_wj == parent.WALLJUMPS.UPWARD and sign(direction) != parent.current_wj_dir:

		# Give us the drift we need to go back to wall
		airDrift *= parent.movement_data.UP_AIR_DRIFT_MULTI

		# Sneakily remove analog inputs to help the gampad players
		# with this 'weird' input (skill issue tbh)
		direction = round(direction)

	# If we are in wall jump then we have no air drift, this restores this when we start falling
	if parent.airDriftDisabled and parent.velocity.y > 0:
		parent.airDriftDisabled = false

	return airDrift


# How quickly we stop the playing moving if they drop the stick
func apply_airResistance(delta, direction):

	# Ok this makes the game really slippery when changing direction
	if direction == 0:
		parent.velocity.x = move_toward(parent.velocity.x, 0, parent.air_frict * delta)


# Checks the above raycasts
func have_stand_room():
	return not (stand_room_left.is_colliding() or stand_room_right.is_colliding())
