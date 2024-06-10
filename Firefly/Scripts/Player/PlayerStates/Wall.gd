extends PlayerState

@export_subgroup("TRANSITIONAL STATES")
@export var GROUNDED_STATE: PlayerState = null
@onready var AERIAL_STATE: PlayerState = $"../Aerial"
@export var SLIDING_STATE: PlayerState = null

# And check the jump buffer on landing
@export_subgroup("Input Assists")
@export var jump_buffer: Timer
@export var post_jump_buffer: Timer

@onready var wall_jump_sfx = $"../../Audio/WallJumpSFX"

@onready var wj_dust_spawner = $"../../Particles/WJDustSpawner"

@onready var sliding_sfx = $"../../Audio/WallSlideSFX"
@onready var wall_slide_dust = $"../../Particles/WallSlideDust"


var cache_airdrift
var pre_wall_vel: float = 0.0

# Called on state entrance, setup
func enter() -> void:
	
	if OS.is_debug_build():
		_logger.info("Flyph - Wall State")

	parent.animation.flip_h = 1 if parent.get_wall_normal().x > 0 else 0

	# Store the velocity we had before we hit the wall
	pre_wall_vel = parent.prev_velocity_x
	
	#if not parent.jumping:
	parent.current_animation = parent.ANI_STATES.WALL_HUG
	
	# TODO: Make this work, prev velocity is zero'd for some reason
	# I want flyph to be squashed like a bug if they slam into this wall
	var squash_value: float
	var squash_dur: float
	
	squash_dur = snappedf(lerpf(0.65, 1.1, abs(parent.prev_velocity_x) / (parent.air_speed * 5)), 0.01)
	squash_value = snappedf(lerpf(0.3, 0.75, abs(parent.prev_velocity_x) / (parent.air_speed * 5)), 0.01)
	parent.squish_node.squish(Vector2(1.0 - squash_value, 1.0 + squash_value), squash_dur)
	
	# Spawn some wall hug dust
	_logger.info("Flyph - Wall Escaped Enter")


# Called before exiting the state, cleanup
func exit() -> void:
	
	# Turn Off the Dust
	wall_slide_dust.emitting = false

	pre_wall_vel = 0.0
	
	sliding_sfx.stop()

# Processing input in this state, returns nil or new state
func process_input(_event: InputEvent) -> PlayerState:
	
	_logger.info("Flyph - Wall Processing Input")
	if Input.is_action_just_pressed("Down"):
		parent.fastFalling = true
		parent.animation.speed_scale = 2.0

	_logger.info("Flyph - Wall Done Processing Input")
	return null

# Processing Frames in this state, returns nil or new state
func process_frame(_delta: float) -> PlayerState:
	return null

# Processing Physics in this state, returns nil or new state
func process_physics(delta: float) -> PlayerState:
	
	_logger.info("Flyph::Wall - Processing Physics")
	apply_gravity(delta, parent.horizontal_axis)
	handle_walljump(parent.vertical_axis)
	AERIAL_STATE.handle_sHop(delta)
	
	handle_acceleration(delta, parent.horizontal_axis)
	apply_airResistance(delta, parent.horizontal_axis)
	
	_logger.info("Flyph::Wall - Finishing Processing Physics")
	return state_status()
	
# What state are we returning.
func state_status() -> PlayerState:
	if parent.is_on_floor():
		# Force into crouch if theres no room
		if AERIAL_STATE.have_stand_room():
			return SLIDING_STATE
		
		# Otherwise go to standing/grounded state
		else:
			return GROUNDED_STATE
			
	# If we're just in the air
	elif not parent.is_on_wall():
		return AERIAL_STATE
	
	return null

func animation_end() -> PlayerState:
	
	if (parent.current_animation == parent.ANI_STATES.JUMP):
		parent.current_animation = parent.ANI_STATES.FALLING
	
	if parent.current_animation == parent.ANI_STATES.FALLING:
		parent.animation.pause()
		
	if parent.current_animation == parent.ANI_STATES.WALL_HUG:
		parent.current_animation = parent.ANI_STATES.WALL_SLIDE

	return null


func apply_gravity(delta, _direction):
	
	var silly_grav = AERIAL_STATE.get_gravity()

	# If holding into wall and falling, slow our fall
	if parent.velocity.y > 0 and Input.is_action_pressed(get_which_wall_collided()) and not parent.temp_gravity_active:  # Ensure we're moving downwards
		

		# Play the sound effect
		sliding_sfx.play(sliding_sfx.get_playback_position())
		
		# Start the DUST
		wall_slide_dust.direction.x = -2 if (parent.get_wall_normal().x > 0) else 2
		wall_slide_dust.emitting = true
		
		# Hit them with the velocity
		parent.velocity.y -= silly_grav * delta * (1/parent.movement_data.WALL_FRICTION_MULTIPLIER)  # Reduce the gravity's effect to slow down descent
	
	# otherwise just fall normally
	else:

		parent.velocity.y -= silly_grav * delta
		
		# Stop the effects
		sliding_sfx.stop()
		wall_slide_dust.emitting = false
		
	
	# Cap fall speed
	parent.velocity.y = min(parent.velocity.y, parent.movement_data.MAX_FALL_SPEED)


# Accelerate the player away from the wall
func handle_acceleration(delta, direction):
	
	# This is simpler than in aerial state because we just don't have as much going on here
	if direction:
		# Wall Accel
		parent.velocity.x  = move_toward(parent.velocity.x, parent.air_speed * direction, parent.air_accel * delta)
		
# Ngl idek what this would do but might as well right?
func apply_airResistance(delta, direction):
	
	# Ok this makes the game really slippery when changing direction
	if direction == 0:
		parent.velocity.x = move_toward(parent.velocity.x, 0, parent.air_frict*delta)

# Performs a wall jump if we can
# Takes delta and the direction of the wall.
# If not given we asasume we're on a wall and try to get the wall normal
func handle_walljump(vc_direction, dir = 0):	
	
	# Attempt jump pretty much just checks if a jump has been buffered and removes that from the buffer if it has
	if not parent.disable_walljump and parent.attempt_jump():
	
		# Which direction is away from the wall
		var jump_dir: float = dir

		# If dir is the default value, we need to get the wall normal
		if jump_dir == 0:
			jump_dir = parent.get_wall_normal().x
			
			
		# Ok so if you are up on a walljump it'll launch you up
		if vc_direction > 0:
			
			set_walljump_flags(jump_dir)
			walljump_fx(jump_dir)
			
			upward_walljump(jump_dir)
			post_jump_buffer.start() 
			
		# Secret Downward WallJump :3
		elif vc_direction < 0 and not parent.crouchJumping:
			
			set_walljump_flags(jump_dir)
			walljump_fx(jump_dir)
			
			downward_walljump(jump_dir)
			post_jump_buffer.start() 
			
		# Otherwise do a wall jump
		# Some caveats, if we are launched, then we have to be holding into the wall
		elif not parent.launched or (parent.launched and (sign(parent.horizontal_axis) == -jump_dir)):

			set_walljump_flags(jump_dir)
			walljump_fx(jump_dir)

			away_walljump(jump_dir)
			post_jump_buffer.start() 

func set_walljump_flags(jump_dir: float) -> void:
	# Set Global Flags
	parent.wallJumping = true
	parent.current_wj_dir = jump_dir
	
	# Have Walljumps interrupt temp gravity(this won't interrupt launches)
	if parent.temp_gravity_active:	
		parent.temp_gravity_active = false
		
	

func walljump_fx(jump_dir: float) -> void:
	# SFX
	wall_jump_sfx.play(0)
	var pitch = 0.2 * jump_dir
	wall_jump_sfx.pitch_scale = 1 + pitch 
	
	# Set Wall Jump Animation
	parent.current_animation = parent.ANI_STATES.WALL_JUMP
	
	# Vibration
	# TODO: Create a vibration manager and use those functions
	Input.start_joy_vibration(1, 0.1, 0.1, 0.175)
	
	# Spawn Wall Jump Dust
	var new_cloud = parent.WJ_DUST.instantiate()
	new_cloud.set_name("WJ_dust_temp")
	wj_dust_spawner.add_child(new_cloud)
	new_cloud.direction.x *= jump_dir
	var animation = new_cloud.get_node("AnimationPlayer")
	animation.play("free")
	
	# Sprite squashing
	parent.squish_node.squish(parent.wJump_squash)
	
	if (parent.current_animation != parent.ANI_STATES.CRAWL):
			parent.current_animation = parent.ANI_STATES.FALLING
			parent.restart_animation = true

func upward_walljump(jump_dir: float) -> void:

	# Which Walljump are we doing?
	var type: int = parent.WALLJUMPS.UPWARD

	# Can we drift?
	var drift: bool = parent.movement_data.UP_DISABLE_DRIFT

	# Launch Velocity
	var velocity: Vector2 = Vector2(parent.up_walljump_velocity_x, parent.up_walljump_velocity_y)
	
	# How much horizontal velocity do we keep?
	var velocity_multi: float = parent.movement_data.UP_VELOCITY_MULTI
	
	# Which direction are we facing?
	var facing: bool = (jump_dir >= parent.horizontal_axis)

	general_walljump(type, drift, velocity, velocity_multi, jump_dir, facing)
	
	parent.lock_h_dir(-jump_dir, 0.2, true)
	
	


func downward_walljump(jump_dir: float) -> void:

	# Which Walljump are we doing?
	var type: int = parent.WALLJUMPS.DOWNWARD

	# Can we drift?
	var drift: bool = parent.movement_data.DOWN_DISABLE_DRIFT

	# Launch Velocity
	var velocity: Vector2 = Vector2(parent.down_walljump_velocity_x, parent.down_walljump_velocity_y)

	# How much horizontal velocity do we keep?
	var velocity_multi: float = parent.movement_data.DOWN_VELOCITY_MULTI

	# Which direction are we facing?
	var facing: bool = (jump_dir < 0)

	general_walljump(type, drift, velocity, velocity_multi, jump_dir, facing)
	
	parent.lock_h_dir(jump_dir, 0.2, true)

	
	


# Perform Away Walljump
func away_walljump(jump_dir: float) -> void:

	
	# Which Walljump are we doing?
	var type: int = parent.WALLJUMPS.NEUTRAL

	# Can we drift?
	var drift: bool = parent.movement_data.DISABLE_DRIFT

	# Launch Velocity
	var velocity: Vector2 = Vector2(parent.walljump_velocity_x, parent.walljump_velocity_y)

	# How much horizontal velocity do we keep?
	var velocity_multi: float = parent.movement_data.WJ_VELOCITY_MULTI

	# Which direction are we facing?
	var facing: bool = (jump_dir < 0)

	general_walljump(type, drift, velocity, velocity_multi, jump_dir, facing)
	
	parent.lock_h_dir(jump_dir, 0.2, true)
	

## General Wall Jump Function

# This function will perform a walljump based on the parameters given
func general_walljump(walljump_type: int, disable_drift: bool, jump_velocity: Vector2, velocity_multi: float, jump_dir: float, facing: bool) -> void:
	
	# Update Flags
	parent.airDriftDisabled = disable_drift
	
	# The editor "warns" that im casting an enum to an int, 
	# but when i make the parameter an enum it won't compile... 
	# so i'll take the warning :3
	parent.current_wj = walljump_type 
	
	
	# Preserve the velocity we had before the jump, with a multiplier (ususally 0)
	if pre_wall_vel != 0:
		parent.velocity.x = pre_wall_vel * -velocity_multi
	else:
		parent.velocity.x =  parent.prev_velocity_x * -velocity_multi 
	
	# Add walljump velocity
	parent.velocity.x += jump_velocity.x * jump_dir
	parent.velocity.y = jump_velocity.y	

	# Update Visuals
	parent.animation.flip_h = facing
	
		
	

func get_which_wall_collided():

	if parent.get_wall_normal().x > 0.5:
		return "Left"
	elif parent.get_wall_normal().x < -0.5:
		return "Right"
