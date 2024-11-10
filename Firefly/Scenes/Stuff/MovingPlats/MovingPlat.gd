extends Node2D
class_name MovingPlat

## Emitted when a full cycle is completed
signal cycle_finished

@export_category("Local Variables")

## How many seconds a cycle lasts
@export var cycle_time: float = 1.0
## If the cycle is considered active
@export var active: bool = true

@export_category("Protected Variables")
@export_group("Only touch in child classes")

## The PathFollowNode to modify
@export var progress_node: PathFollow2D
## The curve defining the platforms relative position along the path over time.
## You can be more flexible with this one if you want to modify it in an instance.
@export var movement_curve: Curve




## The pixel length of the path
var max_length: int = 0

## How much time has passed in the cycle
var current_time: float = 0.0

## What percentage of the cycle we are in
var time_ratio: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	
	if progress_node:
		
		# Get Max Length
		progress_node.progress_ratio = 1.0
		max_length = floor(progress_node.progress)
		progress_node.progress_ratio = 0.0
		
	else:
		printerr("FAILED TO SETUP PROTECTED VARIABLES IN: ", self.name)



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
		
		
	
	
## Returns if the moving platform is active
func is_active() -> bool:
	return active		
		
## Sets the active bool to true
func activate() -> void:
	active = true	
	
## Sets the active bool to false
func deactivate() -> void:
	active = false
	
		
## Called each physics frame to decide if we should move the platform
## Override for custom behavior
func can_run_cycle() -> bool:
	return is_active()	
	

