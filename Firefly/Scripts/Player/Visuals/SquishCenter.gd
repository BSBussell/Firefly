extends Node2D

@export var base_rebound_speed: float = 0.5
@export var bounce_curve: Curve



# State
var rebound_speed: float = 0.0
var original_scale: Vector2 = Vector2(1.0, 1.0)
var squish_from: Vector2 = Vector2.ZERO
var interpolating: bool = false
var interpolation_time: float = 0.0
var initial_difference: Vector2 = Vector2()
 

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	print("Squish  - Process")
	
	if interpolating:
		interpolation_time += delta
		var t = min(interpolation_time / rebound_speed, 1.0)  # Clamp to [0, 1]
		var curve_value = bounce_curve.sample(t)
		var uncapped_scale: Vector2 = lerp(squish_from, original_scale, curve_value)
		var capped_scale = Vector2(snappedf(uncapped_scale.x, 0.001), snappedf(uncapped_scale.y,  0.001))
		scale = capped_scale
		
		if t >= 1.0:
			interpolating = false  # Stop interpolating
	print("Squish  - Process Exit")

# Set the scale for squash/stretch and start interpolating back to original scale
func squish(new_scale: Vector2, new_speed: float = base_rebound_speed) -> void:
	
	# Make sure the order of magnitude stays in the hundreths place
	var safe_scale: Vector2 = Vector2.ZERO
	safe_scale.x = snappedf(new_scale.x, 0.01)
	safe_scale.y = snappedf(new_scale.y, 0.01)
	
	# Set Scale
	scale = safe_scale
	
	# Tweening variables
	squish_from = new_scale
	initial_difference = new_scale - original_scale
	interpolating = true
	
	# Reset Tween Time
	interpolation_time = 0.0
	
	# Set new_speed
	rebound_speed = new_speed 
 
