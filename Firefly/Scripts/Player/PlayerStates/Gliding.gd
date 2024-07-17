extends PlayerState
class_name Gliding

@export_subgroup("TRANSITIONAL STATES")
@export var AERIAL_STATE: PlayerState = null
@export var WALL_STATE: PlayerState = null
@export var GROUNDED_STATE: PlayerState = null
@export var SLIDING_STATE: PlayerState = null

@export var wing_line: trail = null
@export var wing_2: trail = null

@export_subgroup("Temp Knobs")
@export var glide_y_boost: float = -200
@export var glide_x_boost: float = 80
@export var reverse_boost: float = -0.9

@export var accel: float = 90

@export var grav_speed: float = 100
@export var grav_accel: float = 500

@export var air_resistance: float = 100


@onready var flap_sfx = $"../../Audio/FlapSFX"


var glide_speed: float = 0.0

# Called on state entrance, setup
func enter() -> void:
	print("holy shit mom im flying")
	
	# Show the proto-wing visual
	wing_line.length = 7
	wing_2.length = 5
	wing_line.gravity_strength = -500

	wing_line.obey_gravity = false
	
	
	parent.current_animation = parent.ANI_STATES.FALLING
	parent.restart_animation = true
	parent.spawn_jump_dust()
	
	
	if not parent.has_glided:
		
		# Modify the boost to scale with an increase of y velocity. the faster the player is falling,
		# The bigger of a boost they get
		var actual_boost: Vector2 = Vector2.ZERO
		actual_boost.x = lerpf(glide_x_boost * 0.9, glide_x_boost * 1.3, parent.velocity.y/parent.movement_data.MAX_FALL_SPEED)
		actual_boost.y = lerpf(glide_y_boost * 0.9, glide_y_boost * 1.3, parent.velocity.y/parent.movement_data.MAX_FALL_SPEED)
		
		parent.velocity.y = actual_boost.y
		if sign(parent.horizontal_axis) == sign(parent.velocity.x):
			parent.velocity.x += actual_boost.x * sign(parent.horizontal_axis)
		else:
			parent.velocity.x *= reverse_boost
			parent.velocity.x += (glide_x_boost * sign(parent.horizontal_axis))
		parent.has_glided = true
		
		glide_speed = parent.air_speed
	
		flap_sfx.pitch_scale = randf_range(1.0, 1.3)
		flap_sfx.play()
	
	# If you have glided already this jump, then only enable another boost if we're falling at a certain speed
	elif (parent.velocity.y / parent.movement_data.MAX_FF_SPEED) >= 0.45:
		
		var actual_boost_y = lerpf(0, glide_y_boost, parent.velocity.y / parent.movement_data.MAX_FF_SPEED)
		var actual_boost_x = lerpf(0, glide_x_boost, parent.velocity.y / parent.movement_data.MAX_FF_SPEED)
		
		parent.velocity.y = actual_boost_y
		if sign(parent.horizontal_axis) == sign(parent.velocity.x):
			parent.velocity.x += actual_boost_x * sign(parent.horizontal_axis)
		else:
			parent.velocity.x *= reverse_boost
			parent.velocity.x += (glide_x_boost * sign(parent.horizontal_axis))
			
		parent.has_glided = true
		
		glide_speed = parent.air_speed
		
		flap_sfx.pitch_scale = randf_range(1.0, 1.3)
		flap_sfx.play()
	
	# Reset fastFalling Flag
	parent.fastFalling = false
	
	pass

# Called before exiting the state, cleanup
func exit() -> void:
	
	# Hide the proto-wing visual
	wing_line.length = 5
	wing_line.gravity_strength = 1500
	wing_2.length = 4
	
	wing_line.obey_gravity = true
	pass

# Processing input in this state, returns nil or new state
func process_input(_event: InputEvent) -> PlayerState:
	return null

# Processing Frames in this state, returns nil or new state
func process_frame(_delta: float) -> PlayerState:
	
	if sign(parent.velocity.x) > 0:
		parent.animation.flip_h = false
	else:
		parent.animation.flip_h = true
	
	return null

# Processing Physics in this state, returns nil or new state
func process_physics(delta: float) -> PlayerState:
	
	apply_gravity(delta)
	
	apply_acceleration(delta, parent.horizontal_axis)
	apply_air_resistance(delta)
	
	return state_status()
	

# Called when animation ends, returns nil or new state
func animation_end() -> PlayerState:
	return null


## Returns what state we should exit to. Contains 
func state_status() -> PlayerState:
	
	if parent.is_on_floor():
		
		# If we've gone from gliding to on the floor
		Input.start_joy_vibration(1, 0.1, 0.08, 0.175)

		# If we're falling (not mid launch) then swap to this
		# That way 
		if parent.velocity.y >= 0:
			parent.boostJumping = false
			parent.launched = false


		# If we're pressing down and have standing room go into a slide
		if Input.is_action_pressed("Down") or not AERIAL_STATE.have_stand_room():
			return SLIDING_STATE

		# We just land otherwise
		else:
			return GROUNDED_STATE
	
	elif parent.is_on_wall_only():

		_logger.info("Flyph Aerial State -> Wall State")
		return WALL_STATE
		
	# Check if jump is realeased
	elif Input.is_action_just_released("Jump") or Input.is_action_just_pressed("Down"):
		return AERIAL_STATE
	
	return null
	
func apply_gravity(delta: float) -> void:
	
	# TODO: Strengthen gravity as x_velocity decreases
	var max_fall_speed: float = grav_speed
	parent.velocity.y = move_toward(parent.velocity.y, max_fall_speed, grav_accel * delta)

## Addes Acceleration when the player holds a direction, the longer the player is in the air the slower they should move
func apply_acceleration(delta, direction) -> void:

	# If we're moving in a direction
	if direction:

		var airAccel: float

		# Slowing ourselves down in the air
		if (abs(parent.velocity.x) > parent.air_speed and sign(parent.velocity.x) == sign(direction)):
			airAccel = parent.movement_data.AIR_SPEED_RECUTION * 0.8

		# Speed ourselves upd  009
		else:
			airAccel = parent.air_accel

		parent.velocity.x  = move_toward(parent.velocity.x, glide_speed*direction, airAccel * delta)

# Over time slow the players x velocity to 0 
func apply_air_resistance(delta: float) -> void:
	
	glide_speed = move_toward(glide_speed, parent.air_speed * 0.9  , delta * 10)
	
	#if parent.velocity.x != 0:
		#parent.velocity.x = move_toward(parent.velocity.x, 0, air_resistance * delta)
