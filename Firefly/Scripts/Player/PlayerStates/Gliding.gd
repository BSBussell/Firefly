extends PlayerState
class_name Gliding

@export_subgroup("TRANSITIONAL STATES")
@export var AERIAL_STATE: PlayerState = null
@export var WALL_STATE: PlayerState = null
@export var GROUNDED_STATE: PlayerState = null
@export var SLIDING_STATE: PlayerState = null


@export_subgroup("Temp Knobs")
@export var glide_y_boost: float = -200
@export var glide_x_boost: float = 80

## The speed multiplier when reversing directions
@export var reverse_boost: float = -0.9

## How strong gravity is when floating
@export var grav_speed: float = 100

## How quickly we approach the gravity speed
@export var grav_accel: float = 500

## The multiplier applied to friction. Applied when we stop pressing a button.
@export var air_frict_multiplier: float = 0.6

## The multipler applied to the speed reduction when we're over the speed limit.
@export var glide_reduction: float = 0.8

## Speed multiplier when gliding, as you glide your speed approaches your air speed times this.
@export var glide_speed_floor_multi: float = 0.9

## How quickly your glide speed decreases
@export var glide_speed_reduct: float = 10

@onready var flap_sfx = $"../../Audio/FlapSFX"


## This is the max accel we can reach while gliding.
var glide_speed: float = 0.0

# When we start gliding, the glide speed is set to a speed floor that slowly decreases.
# Also floors the speed when direction is changed/speed equals 0.
# This decision was made to de-incentize just holding glide everywhere.
# I didn't want gliding constantly to be the fastest movement option.


# Called on state entrance, setup
func enter() -> void:
	
	print("holy shit mom im flying")
	
	parent.current_animation = parent.ANI_STATES.FALLING
	parent.restart_animation = true
	
	
	
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
	
		# Audio FX
		flap_sfx.pitch_scale = randf_range(1.0, 1.3)
		flap_sfx.play()
		
		# Particle FX
		parent.spawn_jump_dust()
		
		# Squish FX
		parent.squish_node.squish(Vector2(0.7,1.3))
	
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
		
		parent.spawn_jump_dust() 
		
		# Squish FX
		parent.squish_node.squish(Vector2(0.7,1.3))
	
	# Reset fastFalling Flag
	parent.fastFalling = false
	
	pass

# Called before exiting the state, cleanup
func exit() -> void:
	
	# Reset their rotation
	parent.squish_node.rotation = 0
	pass

# Processing input in this state, returns nil or new state
func process_input(_event: InputEvent) -> PlayerState:
	
	# Check if jump is realeased
	if Input.is_action_just_released("Jump") or Input.is_action_just_pressed("Down"):
		
		# Set Fast Fall Flags
		if Input.is_action_just_pressed("Down"):
			parent.fastFalling = true
			parent.animation.speed_scale = 2.0
			if parent.temp_gravity_active:
				parent.temp_gravity_active = false
				parent.velocity.y = max(parent.jump_velocity * 0.5, parent.velocity.y)
		
		return AERIAL_STATE
		   
	return null

# Processing Frames in this state, returns nil or new state
func process_frame(delta: float) -> PlayerState:
	
	if sign(parent.velocity.x) > 0:
		parent.animation.flip_h = false
	else:
		parent.animation.flip_h = true
		
	# Smoothly rotate the sprite based on input direction
	rotate_with_dir(delta)
	
	return null

# Processing Physics in this state, returns nil or new state
func process_physics(delta: float) -> PlayerState:
	
	apply_gravity(delta)
	
	apply_acceleration(delta, parent.horizontal_axis)
	apply_air_resistance(delta, parent.horizontal_axis)
	
	return state_status()
	

# Called when animation ends, returns nil or new state
func animation_end() -> PlayerState:
	return null

func rotate_with_dir(delta: float) -> void:
	
	# Define the target rotation based on the horizontal axis input
	var target_rotation_degrees: float = 0

	if parent.horizontal_axis > 0:
		# Holding right
		target_rotation_degrees = 4.5
		
	elif parent.horizontal_axis < 0:
		# Holding left
		target_rotation_degrees = -4.5

	# Smoothly rotate into the held direction
	parent.squish_node.rotation = lerp_angle(
		parent.squish_node.rotation, 
		deg_to_rad(target_rotation_degrees), 
		10 * delta
	)
	
	
	
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
			airAccel = parent.movement_data.AIR_SPEED_RECUTION * glide_reduction

		# Speed ourselves upd  009
		else:
			airAccel = parent.air_accel

		parent.velocity.x  = move_toward(parent.velocity.x, glide_speed*direction, airAccel * delta)



# Over time slow the players x velocity to 0 
func apply_air_resistance(delta: float, direction: float) -> void:
	
	if not direction:
		
		var glide_stopping: float = parent.air_frict * air_frict_multiplier
		
		parent.velocity.x = move_toward(parent.velocity.x, 0.0, delta * glide_stopping)
		
		# If velocity reaches 0 while we arent holding a direction, then we floor the max glide_speed
		if parent.velocity.x == 0:
			glide_speed = parent.air_speed * glide_speed_floor_multi
	
	glide_speed = move_toward(glide_speed, parent.air_speed * glide_speed_floor_multi, delta * glide_speed_reduct)
	
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
		return GROUNDED_STATE
		
	# If we're launched get us out of gliding	
	if parent.launched:
		return AERIAL_STATE
	
	elif parent.is_on_wall_only():

		_logger.info("Flyph Aerial State -> Wall State")
		return WALL_STATE
		
	
	
	return null
