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


# Jump SFX
@onready var jumping_sfx = $"../../Audio/JumpingSFX"

# Check if room for standing up
@onready var stand_room_left = $"../../Raycasts/Colliders/Stand_Room_Left"
@onready var stand_room_right = $"../../Raycasts/Colliders/Stand_Room_Right"



var shopped: bool = false


# Called on state entrance, setup
func enter() -> void:
	
	print("Aerial State")
	
	right_wj_grace.enabled = true
	left_wj_grace.enabled = true
	
	# Corner correcting raycast
	top_right.enabled = true
	top_left.enabled = true
	
	shopped = false
	
	if (parent.current_animation != parent.ANI_STATES.JUMP and not parent.crouchJumping):
		parent.current_animation = parent.ANI_STATES.FALLING
	pass

# Called before exiting the state, cleanup
func exit() -> void:
	
	right_wj_grace.enabled = false
	left_wj_grace.enabled = false
	
	# Corner correcting raycast (just making sure they off)
	top_right.enabled = false
	top_left.enabled = false
	
	if (parent.fastFalling):
		
		# Landing in fast fall
		parent.update_ff_landings(1.0)
		
		parent.fastFalling = false
		parent.animation.speed_scale = 1.0
		
	else:
		parent.update_ff_landings(0.0)

# Processing input in this state, returns nil or new state
func process_input(_event: InputEvent) -> PlayerState:
	
	if Input.is_action_just_pressed("Down"):
		parent.fastFalling = true
		parent.animation.speed_scale = 2.0
		
	if Input.is_action_just_released("Down") and have_stand_room():
		parent.crouchJumping = false
		parent.current_animation = parent.ANI_STATES.FALLING
		parent.set_standing_collider()
		
	if Input.is_action_just_pressed("Jump"):
		jump_buffer.start()
	
	return null

# Processing Physics in this state, returns nil or new state
func process_physics(delta: float) -> PlayerState:
	
	
	apply_gravity(delta)
	
	# Short hops
	handle_coyote(delta)
	handle_sHop(delta)
	
	# Grace Wall Jumps
	if right_wj_grace.is_colliding():
		WALL_STATE.handle_walljump(delta, parent.vertical_axis, -1)
	elif left_wj_grace.is_colliding():
		WALL_STATE.handle_walljump(delta, parent.vertical_axis, 1)
	
	
	handle_acceleration(delta, parent.horizontal_axis)
	apply_airResistance(delta, parent.horizontal_axis)
	
	parent.move_and_slide()
	
	# Make Sure we're still grounded after this
	if parent.is_on_floor():
		if Input.is_action_pressed("Down") or not have_stand_room():
			return SLIDING_STATE
		else:
			return GROUNDED_STATE
	elif parent.is_on_wall_only():
		return WALL_STATE
	return null
	
func animation_end() -> PlayerState:

	if (parent.current_animation == parent.ANI_STATES.JUMP):
		parent.current_animation = parent.ANI_STATES.FALLING
	
	if parent.current_animation == parent.ANI_STATES.FALLING:
		parent.animation.pause()
	
	return null
	
func handle_coyote(_delta):
	if coyote_time.time_left > 0.0:
		if Input.is_action_just_pressed("Jump") or jump_buffer.time_left > 0.0:
			
			# Prevent silly interactions between jumping and wall jumping
			jump_buffer.stop()
			#jump_buffer.wait_time = -1
			
			# Apply Velocity
			parent.velocity.y = parent.jump_velocity
			
			# Play Jump Cloud
			var new_cloud = parent.JUMP_DUST.instantiate()
			new_cloud.set_name("jump_dust_temp")
			jump_dust.add_child(new_cloud)
			var animation = new_cloud.get_node("AnimationPlayer")
			animation.play("free")
			
			jumping_sfx.play(0)
			
			
			if (parent.current_animation != parent.ANI_STATES.CRAWL):
				parent.current_animation = parent.ANI_STATES.FALLING
	
func handle_sHop(_delta):
	if Input.is_action_just_released("Jump") and parent.velocity.y < parent.ff_velocity:
			
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
		
		
	return gravity_to_apply

func apply_gravity(delta):
	
	parent.velocity.y -= get_gravity() * delta

func handle_acceleration(delta, direction):
	
	var airDrift = 0
	
	# If air drift has been disabled then set it to 0
	if parent.airDriftDisabled:
		airDrift = 0
	
	# If player is jumping in a tunnel
	elif parent.crouchJumping and not have_stand_room():
		airDrift = parent.tunnel_jump_accel
	
	# Otherwise use the default airDrift
	else:
		airDrift = parent.air_accel
	
	# If we are in wall jump then we have no air drift, this restores this when we start falling
	if parent.airDriftDisabled and parent.velocity.y > 0:
			parent.airDriftDisabled = false
	
	if direction:
		# AIR ACCEL
		parent.velocity.x  = move_toward(parent.velocity.x, parent.air_speed*direction, airDrift * delta)
	

func apply_airResistance(delta, direction):
	
	# Ok this makes the game really slippery when changing direction
	if direction == 0:
		parent.velocity.x = move_toward(parent.velocity.x, 0, parent.air_frict * delta)
	

func have_stand_room():
	return not (stand_room_left.is_colliding() or stand_room_right.is_colliding())
			


