extends PlayerState

@export_subgroup("TRANSITIONAL STATES")
@export var GROUNDED_STATE: PlayerState = null
@export var AERIAL_STATE: PlayerState = null

# And check the jump buffer on landing
@export_subgroup("Input Assists")
@export var jump_buffer: Timer

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
		

func handle_walljump(delta, vc_direction):	
	
	
	# In walljump
	
			#print("falling")
	
	if parent.is_on_wall_only():
		if Input.is_action_just_pressed("Jump") or jump_buffer.time_left > 0.0:
		
			# The vector for neutral wall jumps
			# 3., .75
			var neutralX = parent.movement_data.NEUTRAL_WJ_VECTOR.x
			var neutralY = parent.movement_data.NEUTRAL_WJ_VECTOR.y
			
			# The vector for away wall jumps
			# 10, .5
			var awayX = parent.movement_data.AWAY_WJ_VECTOR.x
			var awayY = parent.movement_data.AWAY_WJ_VECTOR.y
			
			var wall_normal = parent.get_wall_normal()	
			# Prevent silly interactions between jumping and wall jumping
			jump_buffer.stop()
			#jump_buffer.wait_time = -1
			
			# TODO: Walljump Animation (Crouch overrides all)
			if (parent.current_animation != parent.ANI_STATES.CRAWL):
				parent.current_animation = parent.ANI_STATES.FALLING
				parent.restart_animation = true
			
			var jump_dir = wall_normal.x
				
			# Ok so if you are up on a walljump it'll launch you up
			if vc_direction > 0:
				parent.velocity.y = parent.jump_velocity * neutralY
				parent.velocity.x = move_toward(parent.velocity.x, (parent.movement_data.SPEED * neutralX) * jump_dir, (parent.movement_data.ACCEL * neutralX) * delta) 
				
				# Facing the fall we're jumping up
				if (parent.movement_data.NEUTRAL_WJ_VECTOR.y < 1.7):
					parent.animation.flip_h = (jump_dir > 0)
				else:
					parent.animation.flip_h = (jump_dir < 0)
				
				
				parent.wallJumping = true
				
			# else itll launch you away
			else:
				parent.velocity.y = parent.jump_velocity * awayY
				parent.velocity.x = move_toward(parent.velocity.x, (parent.movement_data.SPEED * awayX) * jump_dir, (parent.movement_data.ACCEL * awayX * 1.5) * delta)
			
				# Face away from the wall we jumping off of
				parent.animation.flip_h = (jump_dir < 0)
				
				
				
				
				if parent.movement_data.DISABLE_DRIFT:
					parent.airDriftDisabled = true
					print("Removing AirDrift")
			
				parent.horizontal_axis = jump_dir
	


func handle_acceleration(delta, direction):
	if direction:
		# Wall Accel
		parent.velocity.x  = move_toward(parent.velocity.x, parent.movement_data.SPEED*direction, (parent.movement_data.ACCEL / parent.movement_data.WALL_DRIFT_MULTIPLIER) * delta)
		

func apply_airResistance(delta, direction):
	
	# Ok this makes the game really slippery when changing direction
	if direction == 0:
		parent.velocity.x = move_toward(parent.velocity.x, 0, parent.movement_data.AIR_RESISTANCE*delta)
			
	

func get_which_wall_collided():

	if parent.get_wall_normal().x > 0.5:
		return "Left"
	elif parent.get_wall_normal().x < -0.5:
		return "Right"
