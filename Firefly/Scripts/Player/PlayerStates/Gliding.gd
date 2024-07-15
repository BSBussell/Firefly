extends PlayerState
class_name Gliding

@export_subgroup("TRANSITIONAL STATES")
@export var AERIAL_STATE: PlayerState = null
@export var WALL_STATE: PlayerState = null
@export var GROUNDED_STATE: PlayerState = null
@export var SLIDING_STATE: PlayerState = null

# Called on state entrance, setup
func enter() -> void:
	print("holy shit mom im flying")
	pass

# Called before exiting the state, cleanup
func exit() -> void:
	print("mom save me")
	pass

# Processing input in this state, returns nil or new state
func process_input(_event: InputEvent) -> PlayerState:
	return null

# Processing Frames in this state, returns nil or new state
func process_frame(_delta: float) -> PlayerState:
	return null

# Processing Physics in this state, returns nil or new state
func process_physics(delta: float) -> PlayerState:
	
	apply_gravity(delta)
	
	apply_acceleration(delta, parent.horizontal_axis)
	
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
	elif Input.is_action_just_released("Jump"):
		return AERIAL_STATE
	
	return null
	
func apply_gravity(delta: float) -> void:
	
	var max_fall_speed: float = 20
	parent.velocity.y = move_toward(parent.velocity.y, max_fall_speed, -AERIAL_STATE.get_gravity() * delta)

## Addes Acceleration when the player holds a direction
func apply_acceleration(delta, direction) -> void:

	# If we're moving in a direction
	if direction:

		var airAccel: float


		# Slowing ourselves down in the air
		if (abs(parent.velocity.x) > parent.air_speed and sign(parent.velocity.x) == sign(direction)):
			airAccel = parent.movement_data.AIR_SPEED_RECUTION

		# Speed ourselves up
		else:
			airAccel = 90

		parent.velocity.x  = move_toward(parent.velocity.x, parent.air_speed*direction, airAccel * delta)
