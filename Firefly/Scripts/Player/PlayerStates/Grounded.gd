extends PlayerState

@export_subgroup("TRANSITIONAL STATES")
@export var AERIAL_STATE: PlayerState = null
@export var SLIDING_STATE: PlayerState = null

# And check the jump buffer on landing
@export_subgroup("Input Assists")
@export var jump_buffer: Timer
@export var coyote_time: Timer

# This one is used for things like "if the player jumps right before landing on a spring or rope
# Have them know the player just jumped if i wanna give a buffer for that
@export var post_jump_buffer: Timer

# Particle Effects
@onready var dash_dust = $"../../Particles/DashDust"
@onready var jump_dust = $"../../Particles/JumpDustSpawner"
@onready var landing_dust = $"../../Particles/LandingDustSpawner"

# Sound Effects
@onready var landing_sfx = $"../../Audio/LandingSFX"
@onready var jumping_sfx = $"../../Audio/JumpingSFX"
@onready var run_sfx = $"../../Audio/RunSFX"



# Called on state entrance, setup
func enter() -> void:

	if OS.is_debug_build():
		_logger.info("Grounded State")

	# Reset Flags
	parent.crouchJumping = false
	parent.wallJumping = false
	parent.has_glided = false
	parent.modulate = "#FFFFFF"
	parent.launched = false
	
	parent.fastFell = parent.fastFalling
	parent.fastFalling = false

	# Setup the proper colliders for this state :3
	parent.set_standing_collider()

	# Also disable temp gravity when landing just incase we land without falling lol
	if parent.temp_gravity_active and parent.velocity.y >= 0:
		parent.temp_gravity_active = false


	if sign(parent.horizontal_axis ) != 0 and sign(parent.velocity.x) != sign(parent.horizontal_axis):
		parent.velocity.x *= 0.3 

	# If we're landing
	if parent.aerial:

		# Reset the flag
		parent.aerial = false

		# SFX
		landing_sfx.play(0)
		
		

		# Squish
		if jump_buffer.time_left == 0 and not parent.launched:
			
			var squish_dur = snappedf(lerpf(0.5, 0.8, abs(parent.prev_velocity_y) / parent.movement_data.MAX_FALL_SPEED), 0.01)
			
			parent.squish_node.squish(calc_landing_squish(), squish_dur)

		# Check if we running :3
		if abs(parent.velocity.x) >= parent.run_threshold:

			# Then if we are set our animation to running
			parent.current_animation = parent.ANI_STATES.RUNNING
			dash_dust.emitting = true

			# Also play the run sfx
			run_sfx.play()

		# Otherwise just player the landing animation
		else:
			parent.current_animation = parent.ANI_STATES.LANDING

		# Give dust on landing
		var new_cloud = parent.LANDING_DUST.instantiate()
		new_cloud.set_name("landing_dust_temp_grounded")
		landing_dust.add_child(new_cloud)
		var animation = new_cloud.get_node("AnimationPlayer")
		animation.play("free")


# Called before exiting the state, cleanup
func exit() -> void:

	# Reset Effects
	run_sfx.stop()
	dash_dust.emitting = false

# Processing input in this state, returns nil or new state
func process_input(_event: InputEvent) -> PlayerState:

	# Crawling Shit
	# When we press down we crouch
	if Input.is_action_pressed("Down") and parent.current_animation != parent.ANI_STATES.CRAWL:
		return SLIDING_STATE

	return null

func process_frame(_delta):

	# Do all our Visual Updates
	update_facing(parent.velocity.x)
	update_run_effects(parent.horizontal_axis)

# Processing Physics in this state, returns nil or new state
func process_physics(delta: float) -> PlayerState:

	# Check for jumping
	jump_logic(delta)

	# Apply Acceleration and Friction
	handle_acceleration(delta, parent.horizontal_axis)
	apply_friction(delta, parent.horizontal_axis)

	# Return Either Null or our new state
	return state_status(parent.horizontal_axis)

## Checks flags to determine if we need a state change
func state_status(direction: float) -> PlayerState:

   # If we're not longer grounded
	if not parent.is_on_floor():

	   # If we are just falling start coyote timer
		if not parent.jumping and not parent.launched:
			coyote_time.start()

		return AERIAL_STATE

	# If for whatever reason we end up not having room above us then force the
	# Player into crouch, might be used with Auto entering tunnel
	# Also if we aren't moving on a slope that's too steep
	if not AERIAL_STATE.have_stand_room() or (not direction and on_steep_slope()):
		return SLIDING_STATE

	return null



## Called when the animation ends
func animation_end() -> PlayerState:

	# If we've stopped landing then we go to idle animations
	if parent.current_animation == parent.ANI_STATES.LANDING:
		parent.current_animation = parent.ANI_STATES.IDLE


	# If we've stopped getting up then we go to our idle
	if parent.current_animation == parent.ANI_STATES.STANDING_UP:
		parent.current_animation = parent.ANI_STATES.IDLE

	# Sometimes we exit with slide end, in this case we goto idle :3
	if parent.current_animation == parent.ANI_STATES.SLIDE_END:
		parent.current_animation = parent.ANI_STATES.IDLE

	return null


# Updates the Sprite's facing direction
func update_facing(direction: float) -> void:

	# Change direction
	if direction > 0 and parent.animation.flip_h:
		parent.animation.flip_h = false
		parent.squish_node.squish(parent.turn_around_squash)

	elif direction < 0 and not parent.animation.flip_h:
		parent.animation.flip_h = true
		parent.squish_node.squish(parent.turn_around_squash)

func update_run_effects(direction: float) -> void:
	# If set to running/walking from grounded state
	if direction:
		if parent.current_animation == parent.ANI_STATES.IDLE or parent.current_animation == parent.ANI_STATES.RUNNING or parent.current_animation == parent.ANI_STATES.WALKING or parent.current_animation == parent.ANI_STATES.STANDING_UP:


			# Making this a variable so its not computed twice (theres a good change the interpreter would've already done this :3)
			var at_run_threshold: bool = abs(parent.velocity.x) >= parent.run_threshold

			# If we're running and not already in running
			if at_run_threshold and parent.current_animation != parent.ANI_STATES.RUNNING:

				# Set animation and sfx
				parent.current_animation = parent.ANI_STATES.RUNNING
				run_sfx.play()

				# Start our Dust!
				dash_dust.emitting = true
				
				parent.animation.speed_scale = 1.0

			elif not at_run_threshold:
				parent.current_animation = parent.ANI_STATES.WALKING
				parent.animation.speed_scale = 1.0
				
			elif parent.current_animation == parent.ANI_STATES.RUNNING and parent.velocity.x > parent.speed:
				var weight: float = parent.velocity.x / (parent.speed * 3)
				parent.animation.speed_scale = lerpf(1.0, 2 , weight)
			else:
				parent.animation.speed_scale = 1.0  

	# Set to idle from walking
	if not direction:
		if (parent.current_animation == parent.ANI_STATES.RUNNING or parent.current_animation == parent.ANI_STATES.WALKING) :
			parent.current_animation = parent.ANI_STATES.IDLE
			run_sfx.stop()
			parent.animation.speed_scale = 1.0

	# If we're not walking go to runnings
	if parent.current_animation != parent.ANI_STATES.RUNNING:
		dash_dust.emitting = false

# Our logic for making the player jumping
func jump_logic(_delta):

	# If a jump has been buffered, and we aren't being launched by something else
	if not parent.launched and parent.attempt_jump():

		grounded_jump()



## Make the player jump
func grounded_jump():

	# Set our flags
	parent.jumping = true


	# Actual Jump Forces
	parent.velocity.y = parent.jump_velocity
	parent.velocity.x += parent.movement_data.JUMP_HORIZ_BOOST * parent.horizontal_axis

	# Dust Effect
	var new_cloud = parent.JUMP_DUST.instantiate()
	new_cloud.set_name("jump_dust_temp")
	jump_dust.add_child(new_cloud)
	var animation = new_cloud.get_node("AnimationPlayer")
	animation.play("free")

	# Jump SFX
	#var rng = RandomNumberGenerator.new()

	#jumping_sfx.pitch_scale = rng.randf_range(0.8,1.0)
	jumping_sfx.play(0)

	# Squishy
	parent.squish_node.squish(parent.jump_squash)

	# Update Our Animation
	parent.current_animation = parent.ANI_STATES.FALLING

	# Start our post jump timer
	post_jump_buffer.start()

# Accelerate the player based on direction
func handle_acceleration(delta, direction):

	# If we are accelerating
	if direction:

		# Get Acceleration and Speed
		var accel: float = get_accel(direction)
		var speed: float = parent.speed

		# Modifiers for speed and acceleration
		var speed_mod: float = 1.0
		var accel_mod: float = 1.0

		# Get the slope angle
		var slope_angle = rad_to_deg(parent.get_floor_angle(Vector2.UP))

		# At 50 degrees start slowing down acceleration based on the steepness
		if slope_angle > 50 and slope_angle < 90:

			# If we are going uphill
			if sign(parent.get_floor_normal().x) != sign(direction):

				# The closer we are to 90 degrees the less speed and acceleration decrease
				speed_mod = lerp(1.0, 0.5, min(slope_angle, 90) / 90)
				accel_mod = lerp(1.0, 0.5, min(slope_angle, 90) / 90)

			# If we are going downhill
			else:
				# The closer we are to 90 degrees the more speed and acceleration increase
				speed_mod = lerp(1.0, 1.5, min(slope_angle, 90) / 90)
				accel_mod = lerp(1.0, 1.5, min(slope_angle, 90) / 90)

		# Apply Slope Modifiers
		speed *= speed_mod
		accel *= accel_mod

		# Update Velocity
		parent.velocity.x = move_toward(parent.velocity.x, speed * direction, accel * delta)

func get_accel(direction: float):

	# If direction is different than velocity (turning around), modify acceleration
	if parent.velocity.x and sign(direction) != sign(parent.velocity.x):

		return parent.accel * 4

	# If we're coninuing in the same direction
	else:

		# If the player is at max speed
		if (abs(parent.velocity.x) > parent.speed and sign(parent.velocity.x) == sign(direction)):

			return parent.movement_data.SPEED_REDUCTION

		# Just Using Normal Acceleration
		else:

			return parent.accel


# Stop the character when they let go of the button
func apply_friction(delta, direction):

	parent.turningAround = false

	# Ok this makes the game really slippery when changing direction
	if not direction:

		   # If we are on the ground
			parent.velocity.x = move_toward(parent.velocity.x, 0, parent.friction * delta)



## Returns if we are on a slope that is too steep to walk on
func on_steep_slope() -> bool:
	var slope_angle = rad_to_deg(parent.get_floor_angle(Vector2.UP))
	return slope_angle >= 60


## Funny Method for calculating the landing squish using lerps
func calc_landing_squish() -> Vector2:

	var squish_blend = abs(parent.prev_velocity_y) / parent.movement_data.MAX_FALL_SPEED
	var squish_factor = snappedf(lerpf(0.0, 0.5, squish_blend), 0.01)
	return Vector2(1.0 + squish_factor, 1.0 - squish_factor)
