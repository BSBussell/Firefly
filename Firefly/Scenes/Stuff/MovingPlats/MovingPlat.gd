extends Path2D
class_name MovingPlat

## Emitted when a full cycle is completed
signal cycle_finished

## If the cycle is considered active
@export var active: bool = true

@export_category("Protected Variables")
@export_group("Only touch in child classes")

## The PathFollowNode to modify
@export var progress_node: PathFollow2D
## The curve defining the platforms relative position along the path over time.
## You can be more flexible with this one if you want to modify it in an instance.
@export var movement_curve: Curve

## Velocity
@export var avg_velocity: float = 50.0

## Launch Multiplier, modify to adjust launch speed
@export var launch_multi: Vector2 = Vector2(3,2)

## Launch velocity threshold: How much faster than the average velocity, our
## platform has to be to launch
@export var launch_threshold: float = 1.0




## The pixel length of the path
var max_length: int = 0

## How much time has passed in the cycle
var current_time: float = 0.0

## What percentage of the cycle we are in
var time_ratio: float = 0.0

## The amount of time that a cycle will take
var cycle_time: float = 0.0

## Movement Directoin
var movement_direction: Vector2 = Vector2.ZERO

## How fast the platform is moving
var actual_velocity: Vector2 = Vector2.ZERO

## What was our previous position
var previous_positon: Vector2 = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	
	if progress_node:
		
		# Get Max Length
		progress_node.progress_ratio = 1.0
		max_length = floor(progress_node.progress)
		progress_node.progress_ratio = 0.0
		
		# Get the time the cycle should take
		# t = d/v
		cycle_time = max_length / avg_velocity
		
		child_ready()
		
	else:
		printerr("FAILED TO SETUP PROTECTED VARIABLES IN: ", self.name)


## Child overrides, enables individualized setup
func child_ready():
	pass

func  _physics_process(delta):
	if can_run_cycle():
		run_cycle(delta)
		
## Moves the platform	
func run_cycle(delta: float) -> void:
	
	if progress_node:
		
		# Increment time
		current_time += delta
			
		if current_time >= cycle_time:
			
			## Signal to potential child classes or others that we've run a cycle
			emit_signal("cycle_finished")
			
			## Make sure we can still run a cycle before taking the next step
			if not can_run_cycle():
				current_time = 0
				return
			
		current_time = fmod(current_time, cycle_time)
		
		# Get ratio on our curve
		time_ratio = current_time / cycle_time
		
		# Get our progress values
		var curve_val: float = movement_curve.sample(time_ratio)
		
		# Apply the offsets for subpixel smoothing
		progress_node.h_offset = 0
		progress_node.v_offset = 0
		
		# Set the progress nodes progress val, then floor position for pixel res
		progress_node.set_progress_ratio(curve_val)
		
		# Get the exact position
		var exact_position = progress_node.position

		# Calculate the decimal offset
		var decimals: Vector2 = exact_position - floor(exact_position)

		# Apply the offsets for subpixel smoothing
		progress_node.h_offset = -decimals.x
		progress_node.v_offset = -decimals.y
		
		# Use the previous position to calculatte the direction we are moving in
		actual_velocity = (progress_node.position - previous_positon) / delta
		movement_direction = actual_velocity.normalized()
		
		# Update previous position
		previous_positon = progress_node.position
		

## Call this function when we ready to launch the player from the plat
func plat_launch(player: Flyph):
	
	var vel_over_threshold: bool = (actual_velocity.length() < (avg_velocity * launch_threshold))
	var falling: bool = not player.jumping and not player.boostJumping
	
	if vel_over_threshold or falling:
		return
	
	
	movement_direction = snapped(movement_direction, Vector2(0.2,0.2))
	print(movement_direction)
	#if abs(movement_direction.x) > abs(movement_direction.y):
		#movement_direction = Vector2(sign(movement_direction.x), 0)
	#elif abs(movement_direction.x) < abs(movement_direction.y):
		#movement_direction = Vector2(0, sign(movement_direction.y))
	
	
	
	if player.boostJumping and  player.reverseBoostJumping:
		if sign(movement_direction.x) != sign(player.horizontal_axis):
			movement_direction.x *= -1
		
	
	if sign(player.horizontal_axis) == sign(movement_direction.x):
		player.velocity.x += (avg_velocity * movement_direction.x) * launch_multi.x
	
	if sign(movement_direction.y) < 0:
		player.velocity.y += (avg_velocity * movement_direction.y) * launch_multi.y	
		
		## If the player is not moving up faster than  
	
	#print(actual_velocity)
	#print(player.velocity)
	
## Returns if the moving platform is active
func is_active() -> bool:
	return active		
		
## Sets the active bool to true
func activate() -> void:
	active = true
	previous_positon = progress_node.position
	
## Sets the active bool to false
func deactivate() -> void:
	active = false
	
	actual_velocity = Vector2.ZERO
	movement_direction = Vector2.ZERO
	
		
## Called each physics frame to decide if we should move the platform
## Override for custom behavior
func can_run_cycle() -> bool:
	return is_active()	
	

