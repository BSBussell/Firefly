extends PlayerState

@export_subgroup("TRANSITIONAL STATES")
@export var AERIAL_STATE: PlayerState = null
@export var SLIDING_STATE: PlayerState = null

# And check the jump buffer on landing
@export_subgroup("Input Assists")
@export var jump_buffer: Timer
@export var coyote_time: Timer
@onready var crouch_jump_window = $"../../Timers/CrouchJumpWindow"

# Particle Effects
@onready var dash_dust = $"../../Particles/DashDust"
@onready var jump_dust = $"../../Particles/JumpDustSpawner"
@onready var landing_dust = $"../../Particles/LandingDustSpawner"

# Sound Effects
@onready var landing_sfx = $"../../Audio/LandingSFX"
@onready var jumping_sfx = $"../../Audio/JumpingSFX"
@onready var run_sfx = $"../../Audio/RunSFX"


# Set to true when we are exiting via jumping
var jump_exit = false


# Called on state entrance, setup
func enter() -> void:
	print("Grounded State")
	
	#else:
	jump_exit = false
	
	parent.crouchJumping = false
	
	# Clamp Velocity because i hate fun rahh
	#clampf(parent.velocity.x, parent.speed * -1, parent.speed)
	
	# Setup the proper colliders for this state :3
	parent.set_standing_collider()
	
	
	if not parent.current_animation == parent.ANI_STATES.STANDING_UP:
		
		landing_sfx.play(0)
	
		# Land into a sprint!
		if abs(parent.velocity.x) >= parent.run_threshold:
			parent.current_animation = parent.ANI_STATES.RUNNING
			dash_dust.emitting = true
		else:
			parent.current_animation = parent.ANI_STATES.LANDING

		# Give dust on landing
		var new_cloud = parent.LANDING_DUST.instantiate()
		new_cloud.set_name("landing_dust_temp")
		landing_dust.add_child(new_cloud)
		var animation = new_cloud.get_node("AnimationPlayer")
		animation.play("free")
			
		parent.wallJumping = false

# Called before exiting the state, cleanup
func exit() -> void:
	# This is hard because we could either be falling or jumping in leaving this state
	# So lets be silly how we handle that
	if not jump_exit:
		coyote_time.start()
	
	run_sfx.stop()
	dash_dust.emitting = false
	
	pass

# Processing input in this state, returns nil or new state
func process_input(_event: InputEvent) -> PlayerState:
	
	# Crawling Shit
	# When we press down we crouch
	if Input.is_action_pressed("Down") and parent.current_animation != parent.ANI_STATES.CRAWL:
		parent.current_animation = parent.ANI_STATES.CROUCH
		return SLIDING_STATE
		
		
	
	return null


# Processing Physics in this state, returns nil or new state
func process_physics(delta: float) -> PlayerState:
	
	
	
	jump_logic(delta)
	
	handle_acceleration(delta, parent.horizontal_axis)
	apply_friction(delta, parent.horizontal_axis)
	
	update_state(parent.horizontal_axis)
	
	# Make Sure we're still grounded after this
	if not parent.is_on_floor():
		return AERIAL_STATE
	#parent.move_and_slide()
	
	
		
	return null
	
# Our logic for making the player jumping
func jump_logic(_delta):
	
	if Input.is_action_just_pressed("Jump") or jump_buffer.time_left > 0.0:
		
		
		var new_cloud = parent.JUMP_DUST.instantiate()
		new_cloud.set_name("jump_dust_temp")
		jump_dust.add_child(new_cloud)
		var animation = new_cloud.get_node("AnimationPlayer")
		animation.play("free")
		
		
		# Prevent silly interactions between jumping and wall jumping
		jump_buffer.stop()
		
		jumping_sfx.play(0)
		
		# TODO: One day explore the potential of a horizontal boost to the jump
		parent.velocity.y = parent.jump_velocity
		parent.velocity.x += parent.movement_data.JUMP_HORIZ_BOOST * parent.horizontal_axis
		
		
		jump_exit = true
		
		# If we're not currently crouching, then we initiate jumping
		if (parent.current_animation != parent.ANI_STATES.CRAWL):
			parent.current_animation = parent.ANI_STATES.FALLING
			
	

	
	
# Accelerate the player based on direction
func handle_acceleration(delta, direction):
	
	# Can't move forward when crouching or landing
	if direction:  
		if parent.current_animation != parent.ANI_STATES.CRAWL:
			# Thank you maddy/noel/whoever on the exOK team came up with this, this was genius
			if (abs(parent.velocity.x) > parent.speed and sign(parent.velocity.x) == sign(direction)):
				# Reducing Speed to the cap 
				parent.velocity.x = move_toward(parent.velocity.x, parent.speed*direction, parent.movement_data.SPEED_REDUCTION * delta)
			else:
				# Increasing speed
				parent.velocity.x = move_toward(parent.velocity.x, parent.speed*direction, parent.accel * delta)
	
# Stop the character when they let go of the button
func apply_friction(delta, direction):
	
	parent.turningAround = false
	
	
	# Ok this makes the game really slippery when changing direction
	if direction == 0:
			# Non crouch friction
			if parent.current_animation != parent.ANI_STATES.CRAWL:
				parent.velocity.x = move_toward(parent.velocity.x, 0, parent.friction * delta)
				
		
	# IF Turning around
	elif not (direction * parent.velocity.x > 0):
		parent.turningAround = true
		parent.velocity.x = move_toward(parent.velocity.x, 0, parent.turn_friction)
	
		
# Updates animation states based on changes in physics
func update_state(direction):
	
	# Change direction
	if direction > 0:
		parent.animation.flip_h = false
		
	elif direction < 0:
		parent.animation.flip_h = true
	
	# If set to running/walking from grounded state
	if direction:
		if parent.current_animation == parent.ANI_STATES.IDLE or parent.current_animation == parent.ANI_STATES.RUNNING or parent.current_animation == parent.ANI_STATES.WALKING or parent.current_animation == parent.ANI_STATES.STANDING_UP:
			
			
			if abs(parent.velocity.x) >= parent.run_threshold:
				
				parent.current_animation = parent.ANI_STATES.RUNNING
				run_sfx.play(run_sfx.get_playback_position())
				
				dash_dust.emitting = true
			else:
				parent.current_animation = parent.ANI_STATES.WALKING
			
	# Set to idle from walking
	if not direction:
		if (parent.current_animation == parent.ANI_STATES.RUNNING or parent.current_animation == parent.ANI_STATES.WALKING) :
			parent.current_animation = parent.ANI_STATES.IDLE
			run_sfx.stop()
		
	if parent.current_animation != parent.ANI_STATES.RUNNING:
		dash_dust.emitting = false
		

func animation_end() -> PlayerState:
	
	# If we've stopped landing then we go to idle animations
	if parent.current_animation == parent.ANI_STATES.LANDING:
		parent.current_animation = parent.ANI_STATES.IDLE
		
		
	# If we've stopped getting up then we go to our idle
	if parent.current_animation == parent.ANI_STATES.STANDING_UP:
		parent.current_animation = parent.ANI_STATES.IDLE
	
	return null
