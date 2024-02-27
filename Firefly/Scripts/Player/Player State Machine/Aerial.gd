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

var shopped: bool = false


# Called on state entrance, setup
func enter() -> void:
	
	print("Aerial State")
	
	shopped = false
	
	if (parent.current_animation != parent.ANI_STATES.JUMP):	
		parent.current_animation = parent.ANI_STATES.FALLING
	pass

# Called before exiting the state, cleanup
func exit() -> void:
	
	if (parent.fastFalling):
		
		print("Adding ff")
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
		
	if Input.is_action_just_pressed("Jump"):
		jump_buffer.start()
	
	return null

# Processing Physics in this state, returns nil or new state
func process_physics(delta: float) -> PlayerState:
	
	
	apply_gravity(delta)
	
	# Short hops
	handle_coyote(delta)
	handle_sHop(delta)
	
	
	handle_acceleration(delta, parent.horizontal_axis)
	apply_airResistance(delta, parent.horizontal_axis)
	
	parent.move_and_slide()
	
	# Make Sure we're still grounded after this
	if parent.is_on_floor():
		if Input.is_action_pressed("Down"):
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
			
			
			if (parent.current_animation != parent.ANI_STATES.CRAWL):
				parent.current_animation = parent.ANI_STATES.FALLING
	
func handle_sHop(_delta):
	if Input.is_action_just_released("Jump") and parent.velocity.y < parent.ff_velocity:
			
				shopped = true
				#parent.velocity.y = parent.jump_velocity / parent.movement_data.FASTFALL_MULTIPLIER
				parent.ff_velocity = parent.jump_velocity / parent.movement_data.FASTFALL_MULTIPLIER
				parent.velocity.y = parent.ff_velocity
				
				#if (parent.current_animation != parent.ANI_STATES.CROUCH):
					#parent.current_animation = parent.ANI_STATES.FALLING
func get_gravity() -> float:

	var gravity_to_apply = parent.fall_gravity
	print(shopped)
	if parent.velocity.y <= 0 and not shopped:
		print("Rising gravity")
		gravity_to_apply = parent.jump_gravity
	elif parent.fastFalling:
		
		print("Applying ff gravity")
		# This could be a gradual increase instead of an immediate jump to a higher value
		gravity_to_apply = parent.ff_gravity
	
	return gravity_to_apply

func apply_gravity(delta):
	
	
	# If we are just in the air use normal gravity
	# AIR STATE
	#if not parent.fastFalling:
		#parent.velocity.y += gravity * delta
	#else:
		parent.velocity.y -= get_gravity() * delta

func handle_acceleration(delta, direction):
	
	var airDrift = 0
	
	if parent.airDriftDisabled:
		airDrift = 0
	else:
		airDrift = parent.movement_data.AIR_DRIFT_MULTIPLIER
	
	# If we are in wall jump then we have no air drift, this restores this when we start falling
	if parent.airDriftDisabled and parent.velocity.y > 0:
			print("Restoring Air Drift")
			parent.airDriftDisabled = false
	
	if direction:
		# AIR ACCEL
		parent.velocity.x  = move_toward(parent.velocity.x, parent.movement_data.SPEED*direction, (parent.movement_data.ACCEL * airDrift) * delta)
	

func apply_airResistance(delta, direction):
	
	# Ok this makes the game really slippery when changing direction
	if direction == 0:
		parent.velocity.x = move_toward(parent.velocity.x, 0, parent.movement_data.AIR_RESISTANCE*delta)
			


