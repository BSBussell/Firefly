
extends PlayerState

@export_subgroup("TRANSITIONAL STATES")
@export var GROUNDED_STATE: PlayerState = null
@export var AERIAL_STATE: PlayerState = null

# And check the jump buffer on landing
@export_subgroup("Input Assists")
@export var jump_buffer: Timer
@export var post_jump_buffer: Timer
@export var coyote_time: Timer

# Particle Effects
@onready var landing_dust = $"../../Particles/LandingDustSpawner"
@onready var slide_dust = $"../../Particles/SlideDust"
@onready var speed_particles = $"../../Particles/MegaSpeedParticles"

# Sound Effects
@onready var sliding_sfx = $"../../Audio/SlidingSFX"
@onready var landing_sfx = $"../../Audio/LandingSFX"
@onready var crouch_jumping_sfx = $"../../Audio/CrouchJumpingSFX"

# The window for preforming a boost jump
@onready var crouch_jump_window = $"../../Timers/CrouchJumpWindow"

# Flags
var slidingDown = false		# If we at any point have gone down a hill
var jumpExit = false		# If we are exiting this state by a jump

# The threshold
var slide_threshold = 100

# Called on state entrance, setup
func enter() -> void:

	if OS.is_debug_build():
		print("Sliding State")

	# Reset the sliding flags
	slidingDown = false
	jumpExit = false

	# Change to the sliding collider
	parent.set_crouch_collider()

	# If we're coming from the air, we
	if parent.aerial:
		

		parent.aerial = false

		# Dust Cloud
		var new_cloud = parent.LANDING_DUST.instantiate()
		new_cloud.set_name("landing_dust_temp_sliding")
		landing_dust.add_child(new_cloud)
		var animation = new_cloud.get_node("AnimationPlayer")
		animation.play("free")

		# Sound Effect
		landing_sfx.play(0)

		# Squish if we aren't about to jump
		if jump_buffer.time_left == 0:
			parent.squish_node.squish(GROUNDED_STATE.calc_landing_squish())
			
		parent.boostJumping = false
		parent.crouchJumping = false

		# Put us in the landing animation
		parent.current_animation = parent.ANI_STATES.LANDING

	else:

		# Set our current animation state
		parent.current_animation = parent.ANI_STATES.CROUCH

		# Otherwise just do the normal crouch squash
		parent.squish_node.squish(parent.crouch_squash)

	# This might be silly b/c i can't control it lol
	parent.floor_constant_speed = false

	# If we're moving :3
	if abs(parent.velocity.x) > 0:
		slide_dust.emitting = true
		slide_dust.direction.x *= 1 if (parent.velocity.x > 0) else -1
		sliding_sfx.play(0)

	# If we're at sliding speed
	if at_slide_thres(): #and AERIAL_STATE.have_stand_room():

		parent.current_animation = parent.ANI_STATES.SLIDE_PREP


	# Start our timer
	crouch_jump_window.start()

# Called before exiting the state, cleanup
func exit() -> void:

	# Stop any slide-specific fx
	sliding_sfx.stop()
	slide_dust.emitting = false

	# Go back to using a constant speed
	parent.floor_constant_speed = true

# Processing input in this state, returns nil or new state
func process_input(_event: InputEvent) -> PlayerState:

	# Can't get this working here, cause what we're looking for is the release of "down"
	return null

# Processing Frames in this state, returns nil or new state
func process_frame(_delta: float) -> PlayerState:

	print("Do we ever draw?")
	update_facing(parent.velocity.x)
	print("Do we finish facing?")
	update_effects()
	print("IS it the effects that crash us?")
	update_slide_animation()

	print("Do we escape draw?")
	return null
	
## Updates which direction the player is facing based on direction
func update_facing(direction: float) -> void:

	# Change direction
	if direction > 0 and parent.animation.flip_h:
		parent.animation.flip_h = false

		# don't interfere with cj squish :3
		if not parent.crouchJumping:
			parent.squish_node.squish(parent.turn_around_squash)

	elif direction < 0 and not parent.animation.flip_h:
		parent.animation.flip_h = true

		# don't interfere with cj squish :3
		if not parent.crouchJumping:
			parent.squish_node.squish(parent.turn_around_squash)

## Updates the visual effects and audio
func update_effects() -> void:

	# "Speed Particles"
	if abs(parent.velocity.x) > parent.speed:
		speed_particles.emitting = true
		speed_particles.direction.x = 1 if (parent.animation.flip_h) else -1
	else:
		speed_particles.emitting = false


	# Stop fx when we stop moving
	if abs(parent.velocity.x) <= 50:

		# Stop the sound
		sliding_sfx.stop()

		# Turn off dust when we stop
		slide_dust.emitting = false

	elif not slide_dust.emitting:
		# Sliding sfx
		sliding_sfx.play(sliding_sfx.get_playback_position())

		# Slide Particle Effects
		slide_dust.emitting = true

		# Update Particle Direction (im so dumb)
		slide_dust.direction.x = 1 if (parent.animation.flip_h) else -1

## Updates our sliding animation
func update_slide_animation() -> void:

	# If we meet the threshold, and aren't already sliding, start sliding
	if at_slide_thres() and not in_slide_animation() and AERIAL_STATE.have_stand_room():
		parent.current_animation = parent.ANI_STATES.SLIDE_PREP

	# If we fall out of threshold while sliding, update
	if in_slide_animation() and not at_slide_thres():
		parent.current_animation = parent.ANI_STATES.SLIDE_END


# Processing Physics in this state, returns nil or new state
func process_physics(delta: float) -> PlayerState:

	
	print("Slide Bug do we process physics")

	# When sliding, the only actions are jumping and friction
	jump_logic(delta)
	apply_friction(delta, parent.horizontal_axis)

	print("Do we make it to the bottom?")

	return state_status()


func state_status() -> PlayerState:

	# If we have entered the air
	if not parent.is_on_floor():

		# Set us to be in the crawling animation
		parent.current_animation = parent.ANI_STATES.CRAWL

		# Check if we're just falling or if we've been launched / jumping
		if not parent.crouchJumping and not parent.launched and not parent.boostJumping:

			# Start Coyote Timer
			coyote_time.start()

			# Falling Squish
			parent.squish_node.squish(parent.stand_up_squash)

		return AERIAL_STATE

	# If we let go of down and are able to stand up
	if not Input.is_action_pressed("Down") and AERIAL_STATE.have_stand_room() and not on_steep_ground():

		# If we're sliding stop sliding
		if in_slide_animation():
			parent.current_animation = parent.ANI_STATES.SLIDE_END

		# If we aren't just start standing up
		else:
			parent.current_animation = parent.ANI_STATES.STANDING_UP

		return GROUNDED_STATE

	return null



func animation_end() -> PlayerState:

	# If we are landing go to crouch
	if parent.current_animation == parent.ANI_STATES.LANDING:
		parent.squish_node.squish(parent.crouch_squash)
		parent.current_animation = parent.ANI_STATES.CROUCH

	# If we are crouching go to crawl
	if parent.current_animation == parent.ANI_STATES.CROUCH:
		parent.current_animation = parent.ANI_STATES.CRAWL

	# If prep has finished
	if parent.current_animation == parent.ANI_STATES.SLIDE_PREP:

		# Again double check speed
		if at_slide_thres():
			parent.current_animation = parent.ANI_STATES.SLIDE_LOOP

		# If we aren't at the right speed just go to the end of the sliding
		else:
			parent.current_animation = parent.ANI_STATES.SLIDE_END


	# If we're stopped sliding set the animation
	if parent.current_animation == parent.ANI_STATES.SLIDE_END:
		parent.current_animation = parent.ANI_STATES.CROUCH

	return null



func apply_friction(delta, _direction):

	parent.turningAround = false

	# if we're on level ground
	if parent.get_floor_normal() == Vector2.UP:

		# Apply Friction as usual
		var friction = parent.slide_friction

		# Begin slowing down the player
		parent.velocity.x = move_toward(parent.velocity.x, 0, friction * delta)

	# Sliding Downhill
	else:

		# Get the hill direction
		var dir = sign(parent.get_floor_normal().x)
		parent.animation.flip_h = dir <= 0 # Flip the sprite based on slide dir

		# Calculate speed based on hill direction
		var speed = dir * parent.hill_speed
		var accel = parent.hill_accel

		# This is not reset in order to be kind about boost jumps
		slidingDown = true

		# Push player down the hill
		parent.velocity.x = move_toward(parent.velocity.x, speed, accel*delta)


## Handles how we jump
func jump_logic(_delta):

	# If we aren't being launched, we check the jump buffer
	if not parent.launched and parent.attempt_jump():

		jumpExit = true

		# See if we can / then preform a boost jump
		if can_boost_jump():
			boost_jump()
		else:
			crouch_jump()







## Preforms a Crouch Jump
func crouch_jump() -> void:

	## Set our flag
	parent.crouchJumping = true

	## Jump Physics
	# Jump Force
	parent.velocity.y = (parent.jump_velocity * 0.8)

	## Our Effects
	# Normal Jump Dust
	var new_cloud = parent.JUMP_DUST.instantiate()
	new_cloud.set_name("jump_dust_temp")
	GROUNDED_STATE.jump_dust.add_child(new_cloud)
	var animation = new_cloud.get_node("AnimationPlayer")
	animation.play("free")

	# Normal Jump SFX
	GROUNDED_STATE.jumping_sfx.play(0)

	# Squish the Flyph :3
	parent.squish_node.squish(parent.jump_squash)

	# Start our timer
	post_jump_buffer.start()


# Preforms Boost Jump
func boost_jump() -> void:


	## Flags
	# Set crouch jump to true if we aren't jumping off a hill
	if not slidingDown:
		parent.crouchJumping = true

	# Set boostJumping Flag
	parent.boostJumping = true

	## Jump Physics
	# Jump Force
	parent.velocity.y = parent.jump_velocity * parent.movement_data.BOOST_JUMP_HEIGHT_MULTI

	# If velocity is moving in the same direction as our direction
	# Add onto speed
	if parent.velocity.x * parent.horizontal_axis > 0:

		parent.velocity.x += parent.movement_data.BOOST_JUMP_HBOOST * parent.horizontal_axis

	# Otherwise instant reset :3
	else:

		# Flip velocity (or zero it)
		parent.velocity.x *= -parent.movement_data.BJ_REVERSE_MULTIPLIER
		# Then add to it
		parent.velocity.x += parent.movement_data.BOOST_JUMP_HBOOST * parent.horizontal_axis


	## FX
	# Spawn Dust effects
	var new_cloud = parent.CROUCH_JUMP_DUST.instantiate()
	new_cloud.direction.x *= sign(parent.horizontal_axis)
	new_cloud.gravity.x *= sign(parent.horizontal_axis)
	new_cloud.set_name("crouch_jump_dust_temp")
	GROUNDED_STATE.jump_dust.add_child(new_cloud)
	var animation = new_cloud.get_node("AnimationPlayer")
	animation.play("free")

	# Play crouch jump sfx
	crouch_jumping_sfx.play(0)

	# Squash the sprite
	parent.squish_node.squish(parent.lJump_squash)

	## Timer Start
	post_jump_buffer.start()

## Gadjets below VVV


## Returns if we can boost jump
func can_boost_jump() -> bool:

	# Ok so first we make sure the we've jumped within the window.
	# Then make sure the player is moving faster than some multiple of their default speed

	return (crouch_jump_window.time_left == 0 ) and abs(parent.velocity.x) > abs(parent.speed) * parent.movement_data.BOOST_JUMP_THRES

## Returns if speed is fast enough for sliding
func at_slide_thres() -> bool:
	return abs(parent.velocity.x) > slide_threshold

## Returns if we're in a slide animation, taking advantage of enums lol
func in_slide_animation() -> bool:
	return parent.current_animation >= parent.ANI_STATES.SLIDE_PREP and parent.current_animation <= parent.ANI_STATES.SLIDE_END

## Returns if we are standing on ground deemed "too steep" for walking
func on_steep_ground() -> bool:

	var slope_angle = rad_to_deg(parent.get_floor_angle(Vector2.UP))
	if slope_angle >= 60:
		return true
	return false
