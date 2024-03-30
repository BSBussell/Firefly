extends Node2D

@export var rebound_speed: float = 0.5
@export var bounce_curve: Curve

# State
var original_scale: Vector2 = Vector2(1.0, 1.0)
var squish_from: Vector2 = Vector2.ZERO
var interpolating: bool = false
var interpolation_time: float = 0.0
var initial_difference: Vector2 = Vector2()
 

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if interpolating:
		interpolation_time += delta
		var t = min(interpolation_time / rebound_speed, 1.0)  # Clamp to [0, 1]
		var curve_value = bounce_curve.sample(t)
		scale = lerp(squish_from, original_scale, curve_value)
		
		if t >= 1.0:
			interpolating = false  # Stop interpolating

# Set the scale for squash/stretch and start interpolating back to original scale
func squish(new_scale: Vector2, new_speed: float = rebound_speed) -> void:
	scale = new_scale
	squish_from = new_scale
	initial_difference = new_scale - original_scale
	interpolating = true
	interpolation_time = 0.0  # Reset interpolation time
 
