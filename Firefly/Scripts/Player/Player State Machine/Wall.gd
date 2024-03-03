extends PlayerState

@export_subgroup("TRANSITIONAL STATES")
@export var GROUNDED_STATE: PlayerState = null
@export var AERIAL_STATE: PlayerState = null

# And check the jump buffer on landing
@export_subgroup("Input Assists")
@export var jump_buffer: Timer

@onready var wall_jump_sfx = $"../../Audio/WallJumpSFX"

@onready var wj_dust_spawner = $"../../Particles/WJDustSpawner"



var cache_airdrift

# Called on state entrance, setup
func enter() -> void:
	print("Enter Wall State")
	pass

# Called before exiting the state, cleanup
func exit() -> void:
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
	
	handle_acceleration(delta, parent.horizontal_axis)
	apply_airResistance(delta, parent.horizontal_axis)
	
	parent.move_and_slide()
	
	if parent.is_on_floor():
		return GROUNDED_STATE
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
	
	# WALL STATE
	# Priortize fast falling
	#if parent.fastFalling:
		#parent.velocity.y += gravity * parent.movement_data.FASTFALL_MULTIPLIER * delta

	# If holding into wall and falling, slow our fall
	if parent.velocity.y > 0 and Input.is_action_pressed(get_which_wall_collided()):  # Ensure we're moving downwards
		parent.velocity.y -= silly_grav * delta * (1/parent.movement_data.WALL_FRICTION_MULTIPLIER)  # Reduce the gravity's effect to slow down descent
	
	# otherwise just fall normally
	else:
		parent.velocity.y -= silly_grav * delta
		

func handle_walljump(delta, vc_direction, dir = 0):	
	

	if Input.is_action_just_pressed("Jump") or jump_buffer.time_left > 0.0:
	
		# Set Flag for gravity :3
		parent.wallJumping = true
	
		
		
		# Prevent silly interactions between jumping and wall jumping
		jump_buffer.stop()
		
		
		
		#var wall_normal = parent.get_wall_normal()
		var jump_dir: float = dir
		if dir == 0:
			jump_dir = parent.get_wall_normal().x
			
		# SFX!!
		wall_jump_sfx.play(0)
		var pitch = 0.2 * jump_dir
		wall_jump_sfx.pitch_scale = 1 + pitch 
		
		var new_cloud = parent.WJ_DUST.instantiate()
		new_cloud.set_name("WJ_dust_temp")
		wj_dust_spawner.add_child(new_cloud)
		new_cloud.direction.x *= jump_dir
		var animation = new_cloud.get_node("AnimationPlayer")
		animation.play("free")
		
		# TODO: Walljump Animation (Crouch overrides all)
		if (parent.current_animation != parent.ANI_STATES.CRAWL):
			parent.current_animation = parent.ANI_STATES.FALLING
			parent.restart_animation = true
		
		
			
		
		# Ok so if you are up on a walljump it'll launch you up
		if vc_direction > 0:
			
			parent.velocity.y = parent.up_walljump_velocity_y
			parent.velocity.x = parent.up_walljump_velocity_x * jump_dir
			
			# Facing the fall we're jumping up 
			if (parent.movement_data.UP_WALL_JUMP_VECTOR.x < 5):
				parent.animation.flip_h = (jump_dir > 0)
			else:
				parent.animation.flip_h = (jump_dir < 0)
			
			if parent.movement_data.UP_DISABLE_DRIFT:
				parent.airDriftDisabled = true
			
			parent.current_wj = parent.WALLJUMPS.UPWARD
			
		# Secret Downward WallJump :3
		elif vc_direction < 0:
			
			parent.velocity.y = parent.down_walljump_velocity_y
			parent.velocity.x = parent.down_walljump_velocity_x * jump_dir
			
			# Face away from the wall we jumping off of
			parent.animation.flip_h = (jump_dir < 0)
			
			if parent.movement_data.DOWN_DISABLE_DRIFT:
				parent.airDriftDisabled = true
				print("Removing AirDrift")
		
		
			parent.horizontal_axis = jump_dir
			
			parent.current_wj = parent.WALLJUMPS.DOWNWARD
			
		# else itll launch you away
		else:
			parent.velocity.y = parent.walljump_velocity_y
			parent.velocity.x = parent.walljump_velocity_x * jump_dir
		
			# Face away from the wall we jumping off of
			parent.animation.flip_h = (jump_dir < 0)
			
			if parent.movement_data.DISABLE_DRIFT:
				parent.airDriftDisabled = true
		
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
