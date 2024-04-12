
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

@onready var crouch_jump_window = $"../../Timers/CrouchJumpWindow"

var entryVel: float

var slidingDown = false
var jumpExit = false

var usingHill = false

var slide_threshold = 50

# Called on state entrance, setup
func enter() -> void:
	
	print("Sliding State")
	
	slidingDown = false
	
	# Give dust on landing
	if (parent.current_animation == parent.ANI_STATES.FALLING):
		
		
		var new_cloud = parent.LANDING_DUST.instantiate()
		new_cloud.set_name("landing_dust_temp_sliding")
		landing_dust.add_child(new_cloud)
		var animation = new_cloud.get_node("AnimationPlayer")
		animation.play("free")
		
		landing_sfx.play(0)
	
		if jump_buffer.time_left == 0:
			parent.squish_node.squish(GROUNDED_STATE.calc_landing_squish())
	
		# Crouch Animation
		parent.current_animation = parent.ANI_STATES.LANDING

	else:
		parent.squish_node.squish(parent.crouch_squash)
	
	# This might be silly b/c i can't control it lol
	parent.floor_constant_speed = false
	
	# If we're sliding :3
	if abs(parent.velocity.x) > 0:
		slide_dust.emitting = true
		slide_dust.direction.x *= 1 if (parent.velocity.x > 0) else -1
		sliding_sfx.play(0)
		
		if at_slide_thres():
			print("Setting slide anim")	
			parent.current_animation = parent.ANI_STATES.SLIDE_PREP
	#else:
		#print("Setting crouch animation")
		#parent.current_animation = parent.ANI_STATES.CROUCH
		
	entryVel = parent.velocity.x
		
	jumpExit = false
	parent.set_crouch_collider()
	
	crouch_jump_window.start()
	
	pass

# Called before exiting the state, cleanup
func exit() -> void:
	
	sliding_sfx.stop()
	
	slide_dust.emitting = false
	
	
	
	# This might be silly b/c i can't control it lol
	parent.floor_constant_speed = true
	
	pass

# Processing input in this state, returns nil or new state
func process_input(_event: InputEvent) -> PlayerState:
	
	
	return null

# Processing Frames in this state, returns nil or new state
func process_frame(_delta: float) -> PlayerState:
	
	update_state(parent.horizontal_axis)
	
	return null

# Processing Physics in this state, returns nil or new state
func process_physics(delta: float) -> PlayerState:
	
	
		
	
	
	# Just need to be able to jump and apply friction tbh
	jump_logic(delta)
	apply_friction(delta, parent.horizontal_axis)
	
	
	
	# Make Sure we're still grounded after this
	if not parent.is_on_floor():
		# Reset Animation State in case of change
		parent.current_animation = parent.ANI_STATES.CRAWL
		
		# If we are falling instead of jumping or being launched
		if not jumpExit and not parent.launched:
			
			# Start Coyote Timer
			coyote_time.start()
			
			# Falling Squish
			parent.squish_node.squish(parent.stand_up_squash)
		
		return AERIAL_STATE
		
	# Stay there til we let go of down
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


func apply_friction(delta, direction):
	
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
		var sign = sign(parent.get_floor_normal().x)
		parent.animation.flip_h = sign <= 0 # Flip the sprite based on slide dir
		
		# Calculate speed based on hill direction
		var speed = sign * parent.hill_speed
		var accel = parent.hill_accel
		
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
		
		

# Updates animation states based on changes in physics
func update_state(direction):
	
	update_facing(direction)
	update_effects()
	update_slide()

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

func update_effects() -> void:
	
	# "Speed Particles"
	if abs(parent.velocity.x) > parent.speed:
		speed_particles.emitting = true
		speed_particles.direction.x = 1 if (parent.animation.flip_h) else -1
	else:
		speed_particles.emitting = false
	
	
	# Stop sfx when we stop moving
	if parent.velocity.x == 0:
		
		# Sound
		sliding_sfx.stop()
		
		# Dust
		slide_dust.emitting = false
		
	else:
		# Sliding sfx
		sliding_sfx.play(sliding_sfx.get_playback_position())
		
		# Slide Particle Effects
		slide_dust.emitting = true
		
		# Update Particle Direction (im so dumb)
		slide_dust.direction.x *= 1 if (parent.animation.flip_h) else -1

func update_slide():
	
	# If we meet the threshold, and aren't already sliding, start sliding
	if at_slide_thres() and not in_slide_animation():
		parent.current_animation = parent.ANI_STATES.SLIDE_PREP
	
	# If we fall out of threshold while sliding, update
	if in_slide_animation() and not at_slide_thres():
		parent.current_animation = parent.ANI_STATES.SLIDE_END
	


func at_slide_thres() -> bool:
	return abs(parent.velocity.x) > slide_threshold

func in_slide_animation() -> bool:
	return parent.current_animation >= parent.ANI_STATES.SLIDE_PREP and parent.current_animation <= parent.ANI_STATES.SLIDE_END

func on_steep_ground():
	
	var slope_angle = rad_to_deg(parent.get_floor_angle(Vector2.UP))
	if slope_angle >= 60:
		return true
	return false

func crouch_jump():
	# Jump Force
	parent.velocity.y = (parent.jump_velocity * 0.8)
	
	# Normal Jump Dust
	var new_cloud = parent.JUMP_DUST.instantiate()
	new_cloud.set_name("jump_dust_temp")
	GROUNDED_STATE.jump_dust.add_child(new_cloud)
	var animation = new_cloud.get_node("AnimationPlayer")
	animation.play("free")
	
	# Normal Jump SFX
	GROUNDED_STATE.jumping_sfx.play(0)
	parent.crouchJumping = true
	
	# Start our timer
	post_jump_buffer.start()

	# Squish the Flyph :3
	parent.squish_node.squish(parent.jump_squash)
	

# This is a big messy, but essentially boost jump returns true if we perform
# A boost jump and false if we don't
func boost_jump() -> bool:
	
	if not can_boost_jump():
		return false
		
	# Jump Force	
	parent.velocity.y = parent.jump_velocity * parent.movement_data.CROUCH_JUMP_HEIGHT_MULTI
	
	# If velocity is moving in the same direction as our direction
	# Add onto speed
	if parent.velocity.x * parent.horizontal_axis > 0:
		
		parent.velocity.x += parent.movement_data.CROUCH_JUMP_BOOST * parent.horizontal_axis
	
	# Otherwise instant reset :3
	else:
		
		# Flip velocity (or zero it)
		parent.velocity.x *= -parent.movement_data.CJ_REVERSE_MULTIPLIER
		# Then add to it
		parent.velocity.x += parent.movement_data.CROUCH_JUMP_BOOST * parent.horizontal_axis
		
		
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
	
	post_jump_buffer.start()
	
	# Set crouch jump to true if we aren't jumping off a hill
	if not slidingDown:
		parent.crouchJumping = true
		
	# Set boostJumping Flag
	parent.boostJumping = true
	
	
	return true
	
func can_boost_jump():
	
	return (crouch_jump_window.time_left == 0 ) and abs(parent.velocity.x) > abs(parent.speed) * parent.movement_data.CROUCH_JUMP_THRES
