extends PlayerState

@export_subgroup("TRANSITIONAL STATES")
@export var WALL_STATE: PlayerState = null
@export var GROUNDED_STATE: PlayerState = null
@export var SLIDING_STATE: PlayerState = null

# Timers
@export_subgroup("Input Assistance Timers")
@export var coyote_time: Timer
@export var jump_buffer: Timer

@onready var jump_dust = $"../../Particles/JumpDustSpawner"

# WallJump Checkers
@onready var right_wj_grace = $"../../Raycasts/Right_WJ_Grace"
@onready var left_wj_grace = $"../../Raycasts/Left_WJ_Grace"

# Jump Corner Correctors
@onready var top_left = $"../../Raycasts/VerticalSmoothing/TopLeft"
@onready var top_right = $"../../Raycasts/VerticalSmoothing/TopRight"

# Check if room for standing up
@onready var stand_room_left = $"../../Raycasts/Colliders/Stand_Room_Left"
@onready var stand_room_right = $"../../Raycasts/Colliders/Stand_Room_Right"

# Speed FX
@onready var speed_particles = $"../../Particles/MegaSpeedParticles"

# Jump SFX
@onready var jumping_sfx = $"../../Audio/JumpingSFX"

# For Coyote CJ
@onready var crouch_jump_window = $"../../Timers/CrouchJumpWindow"

var min_fall_speed = 0.0
# Timer to wait before slowing down the player
#@onready var crouch_jump_window = $"../../Timers/CrouchJumpReleaseWindow"

var ticks: float = 0

var stored_velocity_x: float

var shopped: bool = false


# Called on state entrance, setup
func enter() -> void:
	
	print("Aerial State")
	
	right_wj_grace.enabled = true
	left_wj_grace.enabled = true
	
	# Corner correcting raycast
	top_right.enabled = true
	top_left.enabled = true
	
	parent.canCrouchJump = true
	
	shopped = false
	
	
	if (parent.current_animation != parent.ANI_STATES.JUMP and not parent.crouchJumping):
		parent.current_animation = parent.ANI_STATES.FALLING
	
	ticks = 0
	
	min_fall_speed = 0.0
	

# Called before exiting the state, cleanup
func exit() -> void:
	
	right_wj_grace.enabled = false
	left_wj_grace.enabled = false
	
	# Corner correcting raycast (just making sure they off)
	top_right.enabled = false
	top_left.enabled = false
	
	speed_particles.emitting = false
	
	
	
	if (parent.fastFalling):
		
		parent.fastFalling = false
		parent.animation.speed_scale = 1.0
	

# Processing input in this state, returns nil or new state
func process_input(_event: InputEvent) -> PlayerState:
	
	if Input.is_action_just_pressed("Down"):
		parent.fastFalling = true
		parent.animation.speed_scale = 2.0
		if parent.temp_gravity_active:
			parent.temp_gravity_active = false
			parent.velocity.y = max(parent.jump_velocity * 0.5, parent.velocity.y)
		
	if parent.crouchJumping and not Input.is_action_pressed("Down") and have_stand_room():
	#Input.is_action_released("Down") and have_stand_room():
		parent.crouchJumping = false
		parent.current_animation = parent.ANI_STATES.FALLING
		#parent.squish_node.scale = parent.stand_up_squash
		parent.set_standing_collider()
		
	
	
	return null

# Processing Physics in this state, returns nil or new state
func process_physics(delta: float) -> PlayerState:
	
	
	apply_gravity(delta)
	
	# Short hops
	handle_coyote(delta)
	handle_sHop(delta)
	
	# Grace Wall Jumps
	if not parent.temp_gravity_active:
		if right_wj_grace.is_colliding() and round(right_wj_grace.get_collision_normal(0).x) == right_wj_grace.get_collision_normal(0).x :
			WALL_STATE.handle_walljump(delta, parent.vertical_axis, -1)
		elif left_wj_grace.is_colliding() and round(left_wj_grace.get_collision_normal(0).x) == left_wj_grace.get_collision_normal(0).x:
			WALL_STATE.handle_walljump(delta, parent.vertical_axis, 1)
	
	
	handle_acceleration(delta, parent.horizontal_axis)
	apply_airResistance(delta, parent.horizontal_axis)
	
	ticks += delta
	
	min_fall_speed = min(min_fall_speed, parent.velocity.y)
	
	# Make Sure we're still grounded after this
	if parent.is_on_floor():
		
		parent.landing_speed = min_fall_speed
		Input.start_joy_vibration(1, 0.1, 0.08, 0.175)
		
		parent.boostJumping = false
		parent.launched = false
		
		
		if Input.is_action_pressed("Down") or not have_stand_room():
			
			# IF the player stays crouching the whole time they can't chain it again
			# The point is to discourage just abusing the "crouched" variant other than
			# For slight adjustments/etc.
			if (parent.crouchJumping):
				parent.canCrouchJump = false
			
			return SLIDING_STATE
		else:
			return GROUNDED_STATE
	elif parent.is_on_wall_only():
		return WALL_STATE
	
	return null

func process_frame(delta):
	
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
	
	if abs(parent.velocity.x) > parent.air_speed + parent.movement_data.JUMP_HORIZ_BOOST or parent.temp_gravity_active:
		speed_particles.emitting = true
		speed_particles.direction.x = 1 if (parent.animation.flip_h) else -1
	else:
		speed_particles.emitting = false
	pass

func animation_end() -> PlayerState:

	if (parent.current_animation == parent.ANI_STATES.JUMP):
		parent.current_animation = parent.ANI_STATES.FALLING
	
	if parent.current_animation == parent.ANI_STATES.FALLING:
		parent.animation.pause()
	
	return null
	
func handle_coyote(_delta):
	if coyote_time.time_left > 0.0 and not parent.temp_gravity_active:
		if parent.attempt_jump():
			
			
			
		
			
			# Check Conditions for boost jumping
			if not (parent.current_animation == parent.ANI_STATES.CRAWL and SLIDING_STATE.boost_jump()):
				parent.velocity.x += parent.movement_data.JUMP_HORIZ_BOOST * parent.horizontal_axis
				
				parent.velocity.y = parent.jump_velocity
				
				# Play Jump Cloud
				var new_cloud = parent.JUMP_DUST.instantiate()
				new_cloud.set_name("jump_dust_temp")
				jump_dust.add_child(new_cloud)
				var animation = new_cloud.get_node("AnimationPlayer")
				animation.play("free")
				
				jumping_sfx.play(0)
			
			else:
				ticks = 0
			
			
				
			if (parent.current_animation != parent.ANI_STATES.CRAWL):
				parent.current_animation = parent.ANI_STATES.FALLING
	
func handle_sHop(_delta):
	
	if parent.temp_gravity_active:
		shopped = false
		return
	
	if Input.is_action_just_released("Jump"):
		if parent.velocity.y < parent.ff_velocity:
			
			shopped = true
			parent.velocity.y = parent.ff_velocity
				
func get_gravity() -> float:

	# Default gravity is fall gravity
	var gravity_to_apply = parent.fall_gravity
	
	# Disabling Wall Jumping
	if parent.wallJumping and parent.velocity.y > 0:
		# Player has started falling, reset wall jump state
		parent.wallJumping = false
		parent.current_wj = parent.WALLJUMPS.NEUTRAL
	
	# If we're wall jumping
	elif parent.wallJumping:
		# Apply the correct wall jump gravity
		match parent.current_wj:
			parent.WALLJUMPS.NEUTRAL:
				gravity_to_apply = parent.walljump_gravity
			parent.WALLJUMPS.UPWARD:
				gravity_to_apply = parent.up_walljump_gravity
	
	# If we're rising
	elif parent.velocity.y <= 0 and not shopped:
		# Apply rising gravity
		gravity_to_apply = parent.jump_gravity
	
	# If we're fast falling
	elif parent.fastFalling:
		# Apply fast falling gravity
		gravity_to_apply = parent.ff_gravity
		
	if parent.temp_gravity_active:
		gravity_to_apply = parent.temp_gravtity
		print(parent.velocity.y)
		print("Using Temp Grav!")
		
		
	# Reset temporary gravity once the player starts falling
	if parent.velocity.y > 0 :
		
		# Resetting certain flags :3
		if parent.temp_gravity_active:
			parent.temp_gravity_active = false
			parent.launched = false # This will occasionally be extranous, but generally these are connected
		if parent.jumping:
			parent.jumping = false
			
			
	# Add a bit of float
	if abs(parent.velocity.y) < 30:
		gravity_to_apply *= 0.5	
		
	return gravity_to_apply

func apply_gravity(delta):
	
	parent.velocity.y -= get_gravity() * delta
	parent.velocity.y = min(parent.velocity.y, parent.movement_data.MAX_FALL_SPEED)

func handle_acceleration(delta, direction):
	
	var airDrift = 0
	var airReduction = parent.movement_data.AIR_SPEED_RECUTION
	
	# If air drift has been disabled then set it to 0
	if parent.airDriftDisabled:
		airDrift = 0
	
	# If player is jumping while crouching
	elif parent.crouchJumping:
		
		var crouch_release_window = 30/60 # So this should be roughly one frame
		
		# So they have that much time to release down before velocity is capped
		# I have this because I don't like the idea of players flying around in crouch
		# And also I found that the motion of releasing crouch felt inline with 
		if ticks > crouch_release_window:
			parent.velocity.x = clamp(parent.velocity.x, -abs(parent.air_speed), parent.air_speed)
			
		# If we're in a tunnel we increase accel
		if not have_stand_room():
			airDrift = parent.tunnel_jump_accel
		else:
			airDrift = parent.air_accel
			
	# If we are wall jumping up and holding into a wall we give a boost in air accel in order to help
	# with climbing / make it possible
	elif parent.wallJumping and parent.current_wj == parent.WALLJUMPS.UPWARD and sign(direction) != parent.current_wj_dir:
		
		# Give us the drift we need to go back to wall
		airDrift = parent.air_accel * parent.movement_data.UP_AIR_DRIFT_MULTI
		
		# Sneakily remove analog inputs to help the gampad players
		# with this weird input
		direction = round(direction)
	
	# Otherwise use the default airDrift
	else:
		airDrift = parent.air_accel
	
	# If we are in wall jump then we have no air drift, this restores this when we start falling
	if parent.airDriftDisabled and parent.velocity.y > 0:
			parent.airDriftDisabled = false
	
	if direction:
		# AIR ACCEL
		# Slow ourselves down in the air
		if (abs(parent.velocity.x) > parent.air_speed and sign(parent.velocity.x) == sign(direction)):
			parent.velocity.x  = move_toward(parent.velocity.x, parent.air_speed*direction, airReduction * delta)
		
		# Speed ourselves up
		else:
			parent.velocity.x  = move_toward(parent.velocity.x, parent.air_speed*direction, airDrift * delta)
	

func apply_airResistance(delta, direction):
	
	# Ok this makes the game really slippery when changing direction
	if direction == 0:
		parent.velocity.x = move_toward(parent.velocity.x, 0, parent.air_frict * delta)
	

func have_stand_room():
	return not (stand_room_left.is_colliding() or stand_room_right.is_colliding())
			


