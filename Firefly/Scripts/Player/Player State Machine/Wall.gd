extends PlayerState

@export_subgroup("TRANSITIONAL STATES")
@export var GROUNDED_STATE: PlayerState = null
@export var AERIAL_STATE: PlayerState = null
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

# Called on state entrance, setup
func enter() -> void:
	print("Wall State")
	
	pass

# Called before exiting the state, cleanup
func exit() -> void:
	
	wall_slide_dust.emitting = false
	pass

# Processing input in this state, returns nil or new state
func process_input(_event: InputEvent) -> PlayerState:
	if Input.is_action_just_pressed("Down"):
		parent.fastFalling = true
		parent.animation.speed_scale = 2.0
	return null

# Processing Frames in this state, returns nil or new state
func process_frame(_delta: float) -> PlayerState:
	return null

# Processing Physics in this state, returns nil or new state
func process_physics(delta: float) -> PlayerState:
	
	
	
	apply_gravity(delta, parent.horizontal_axis)
	handle_walljump(delta, parent.vertical_axis)
	AERIAL_STATE.handle_sHop(delta)
	
	handle_acceleration(delta, parent.horizontal_axis)
	apply_airResistance(delta, parent.horizontal_axis)
	
	#parent.move_and_slide()
	
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
	return null


func apply_gravity(delta, _direction):
	
	var silly_grav = AERIAL_STATE.get_gravity()

	# If holding into wall and falling, slow our fall
	if parent.velocity.y > 0 and Input.is_action_pressed(get_which_wall_collided()) and not parent.temp_gravity_active:  # Ensure we're moving downwards
		
		sliding_sfx.play(sliding_sfx.get_playback_position())
		
		wall_slide_dust.direction.x = -2 if (parent.get_wall_normal().x > 0) else 2
		wall_slide_dust.emitting = true
		
		# Hit them with the velocity
		parent.velocity.y -= silly_grav * delta * (1/parent.movement_data.WALL_FRICTION_MULTIPLIER)  # Reduce the gravity's effect to slow down descent
	
	# otherwise just fall normally
	else:
		parent.velocity.y -= silly_grav * delta
		sliding_sfx.stop()
		
	
	# Cap fall speed
	parent.velocity.y = min(parent.velocity.y, parent.movement_data.MAX_FALL_SPEED)

func handle_walljump(delta, vc_direction, dir = 0):	
	
	# Attempt jump pretty much just checks if a jump has been buffered and removes that from the buffer if it has
	if not parent.temp_gravity_active and parent.attempt_jump():
	
		post_jump_buffer.start() # Start post jump buffer
	
		# If the player is trying to do an upward wall jump and we're coming from the padding abort
		# Upward wall jumps get frustrating when the padding starts pushing the player away from the wall
		#if vc_direction > 0 and dir != 0:
			#return
	
		print("Walljumping")
	
		# Set Flag for gravity :3
		parent.wallJumping = true
		
		# Interrupt our launch custom gravity
		if parent.temp_gravity_active:	
			parent.temp_gravity_active = false
		
		
		
		#var wall_normal = parent.get_wall_normal()
		var jump_dir: float = dir
		if dir == 0:
			jump_dir = parent.get_wall_normal().x
			
		# SFX
		wall_jump_sfx.play(0)
		var pitch = 0.2 * jump_dir
		wall_jump_sfx.pitch_scale = 1 + pitch 
		
		Input.start_joy_vibration(1, 0.1, 0.1, 0.175)
		
		var new_cloud = parent.WJ_DUST.instantiate()
		new_cloud.set_name("WJ_dust_temp")
		wj_dust_spawner.add_child(new_cloud)
		new_cloud.direction.x *= jump_dir
		var animation = new_cloud.get_node("AnimationPlayer")
		animation.play("free")
		
		# Sprite squashing
		parent.squish_node.squish(parent.wJump_squash)
		
		# TODO: Walljump Animation or something
		if (parent.current_animation != parent.ANI_STATES.CRAWL):
			parent.current_animation = parent.ANI_STATES.FALLING
			parent.restart_animation = true
			
		
		parent.current_wj_dir = jump_dir
			
		# Ok so if you are up on a walljump it'll launch you up
		if vc_direction > 0:
			
			# Generally this will be 0 unless I want a wj that gives speed boosts
			var velocity_multi: float = parent.movement_data.UP_VELOCITY_MULTI
			
			# Flip the velocity first
			parent.velocity.x = parent.prev_velocity_x * - velocity_multi
			
			# Then add to it
			parent.velocity.x += parent.up_walljump_velocity_x * jump_dir
			parent.velocity.y = parent.up_walljump_velocity_y
			
			# Facing the fall we're jumping up 
			#if (parent.movement_data.UP_WALL_JUMP_VECTOR.x < 5):
			parent.animation.flip_h = (jump_dir >= parent.horizontal_axis)
			#else:
				#parent.animation.flip_h = (jump_dir <= parent.horizontal_axis)
			
			if parent.movement_data.UP_DISABLE_DRIFT:
				parent.airDriftDisabled = true
			else:
				parent.airDriftDisabled = false
			
			# Let any other potential states know we walljumpin
			parent.current_wj = parent.WALLJUMPS.UPWARD
			
		# Secret Downward WallJump :3
		elif vc_direction < 0 and not parent.crouchJumping:
			
			var velocity_multi: float = parent.movement_data.DOWN_VELOCITY_MULTI
			
			parent.velocity.x =  parent.prev_velocity_x * -velocity_multi
			parent.velocity.x += parent.down_walljump_velocity_x * jump_dir
			
			
			parent.velocity.y = parent.down_walljump_velocity_y
			
			# Face away from the wall we jumping off of
			parent.animation.flip_h = (jump_dir < 0)
			
			if parent.movement_data.DOWN_DISABLE_DRIFT:
				parent.airDriftDisabled = true
			else:
				parent.airDriftDisabled = false
		
		
			parent.horizontal_axis = jump_dir
			
			parent.current_wj = parent.WALLJUMPS.DOWNWARD
			
		# else itll launch you away
		else:
			var velocity_multi: float = parent.movement_data.WJ_VELOCITY_MULTI
			# Flip the velocity first
			parent.velocity.x =  parent.prev_velocity_x * -velocity_multi
			parent.velocity.x += parent.walljump_velocity_x * jump_dir

				
			parent.velocity.y = parent.walljump_velocity_y	
		
			# Face away from the wall we jumping off of
			parent.animation.flip_h = (jump_dir < 0)
			
			if parent.movement_data.DISABLE_DRIFT:
				parent.airDriftDisabled = true
			else:
				parent.airDriftDisabled = false
		
			parent.horizontal_axis = jump_dir
			
			parent.current_wj = parent.WALLJUMPS.NEUTRAL
	


func handle_acceleration(delta, direction):
	if direction:
		# Wall Accel
		parent.velocity.x  = move_toward(parent.velocity.x, parent.air_speed * direction, parent.air_accel * delta)
		

func apply_airResistance(delta, direction):
	
	# Ok this makes the game really slippery when changing direction
	if direction == 0:
		parent.velocity.x = move_toward(parent.velocity.x, 0, parent.air_frict*delta)
			
	

func get_which_wall_collided():

	if parent.get_wall_normal().x > 0.5:
		return "Left"
	elif parent.get_wall_normal().x < -0.5:
		return "Right"
