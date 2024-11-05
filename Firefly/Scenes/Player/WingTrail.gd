extends Line2D

@export var player: Flyph
@export var length: float = 15
@export var bob_strength: float = 1.0  # Strength of the bobbing motion
@export var bob_speed: float = 2.0  # Speed of the bobbing motion
@export var resting_position: Vector2 = Vector2(3, 11)
@export var smoothing: float = 30
@export var num_segments: int = 5  # Number of points between the base and the trailing point

@export var offset: float = 0

var time_passed: float = 0.0  # To keep track of the time for the sine wave

var base_point: Vector2 # globals cheese :3


@onready var local_smoothing: float = smoothing

# Called when the node enters the scene tree for the first time.
func _ready():
	
	time_passed = offset
	
	_initialize_points()

# Initialize the points of the Line2D
func _initialize_points():
	clear_points()
	for i in range(num_segments + 2):  # +2 to account for the initial and final points
		add_point(Vector2.ZERO)

func set_wing_length(wing_len: float) -> void:
	
	resting_position = resting_position.normalized() * wing_len


var desired_trailing_point

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if player:
		base_point = Vector2.ZERO
		

		resting_position.x = abs(resting_position.x) * sign(get_parent().position.x)


		local_smoothing = smoothing
		desired_trailing_point = calc_wing_pos(delta)
		
		# Smoothly interpolate the current trailing point towards the desired trailing point
		var trailing_point = get_point_position(num_segments + 1)
		trailing_point = trailing_point.move_toward(desired_trailing_point, delta * local_smoothing)
		
		# Update the points of the Line2D
		set_point_position(num_segments + 1, trailing_point)

		# Calculate intermediate points
		for i in range(1, num_segments + 1):
			var t = float(i) / float(num_segments + 1)
			var intermediate_point = base_point.lerp(trailing_point, t)
			set_point_position(i, intermediate_point)
		
		# Set the initial point to the player's current position
		set_point_position(0, base_point)


func calc_wing_pos(delta) -> Vector2:
	
	if player.StateMachine.current_state == player.GLIDING_STATE:
		
		
		if player.velocity.y > 0:
			return gliding_wings(delta)
		else:
			return flapping_wings(delta)
	
	# Grounded values
	elif player.is_on_floor():
		
		if player.StateMachine.current_state == player.SLIDING_STATE:
			return sliding_wings(delta)
		
		# Player running or walking
		if player.velocity.length() > 0:
			return grounded_movement_wings(delta)
		
		return idle_wings(delta)
	
	# Aerial Situations
	else:
		
		# If we're fast falling kinda tuck in the wings
		if player.fastFalling:
			local_smoothing = smoothing * 3
			return idle_wings(delta)
		
		# The player is falling
		elif player.velocity.y > 0:
			return aerial_falling_wings(delta)
		elif player.velocity.y < 0:
			return aerial_rising_wings(delta)
		
		# When the player is not on the floor, just use the resting position
		return base_point + resting_position

func bob_offset(delta: float, speed: float = bob_speed, strength: float = bob_strength) -> Vector2:
	time_passed += delta
	# Create an up and down bobbing effect using a sine wave
	return Vector2(0, sin(time_passed * speed) * strength)

func get_length(base: Vector2) -> float:
	return (resting_position - base).length()

func constrain_length(unconstrained_point, base) -> Vector2:
	return unconstrained_point.normalized() * get_length(base)

# This is disgusting but in a raw way
func constrain_length_with_offset(unconstrained_point, base, offset_length) -> Vector2:
	var adjusted_base_point = base + (base - unconstrained_point).normalized() * offset_length
	return constrain_length(unconstrained_point, adjusted_base_point)


func idle_wings(delta) -> Vector2:
	var idle_offset: Vector2 = base_point + resting_position + bob_offset(delta)
	return constrain_length(idle_offset, base_point)
	

func grounded_movement_wings(delta) -> Vector2:
	# Based on the velocity, have the wings rise upwards to emulate inertia like a cape
	var velocity_offset = Vector2(0, max(-player.velocity.length() * 0.04, -5)) # bullshit constants, go
	var long_offset: Vector2 = base_point + resting_position + velocity_offset + bob_offset(delta, 9 if offset == 0 else 15,1.2)
	return constrain_length(long_offset, base_point)


func sliding_wings(delta) -> Vector2:
	# Based on the velocity, have the wings stretch outwards to emulate sliding motion
	var velocity_offset = Vector2(0, max(-player.velocity.length() * 0.04, -5))
	var long_offset: Vector2 = base_point + resting_position + velocity_offset + bob_offset(delta, 10 * (player.velocity.x/player.hill_speed), 1.5)
	
	# Make the base point lower because when we slide the player goes lower (do this after we constrain the length
	base_point.y += 4
	
	return constrain_length_with_offset(long_offset, base_point, 5)

func aerial_rising_wings(delta) -> Vector2:
	# Based on the velocity, have the wings tuck inwards to emulate the upward motion
	var velocity_offset = Vector2(0, min(player.velocity.length() * 0.03, 3))
	var long_offset: Vector2 = base_point + resting_position + velocity_offset + bob_offset(delta, 8, 0.8)
	return constrain_length(long_offset, base_point)

func aerial_falling_wings(delta) -> Vector2:
	# Based on the velocity, have the wings extend outwards to emulate inertia
	var velocity_offset = Vector2(0, max(-player.velocity.length() * 0.06, -5.5))
	var long_offset: Vector2 = base_point + resting_position + velocity_offset + bob_offset(delta, 6 if offset == 0 else 10, 1.0)
	return constrain_length(long_offset, base_point)


func gliding_wings(delta) -> Vector2:

	# Woo!
	var max_extension: float = -8.0 if offset == 0 else -6.2
	
	local_smoothing = smoothing * 5
	
	var velocity_offset = Vector2(0, max(-player.velocity.length() * 0.06, max_extension))
	var long_offset: Vector2 = base_point + resting_position + velocity_offset + bob_offset(delta, 50 if offset == 0 else 25, 10.0)
	return constrain_length(long_offset, base_point)
	
func flapping_wings(delta) -> Vector2:

	# Woo!
	var max_extension: float = -8.0 if offset == 0 else -6.2
	
	local_smoothing = smoothing * 5
	
	var velocity_offset = Vector2(0, max(-player.velocity.length() * 0.06, max_extension))
	var long_offset: Vector2 = base_point + resting_position + velocity_offset + bob_offset(delta, 50 if offset == 0 else 25, 10.0)
	return constrain_length(long_offset, base_point)
