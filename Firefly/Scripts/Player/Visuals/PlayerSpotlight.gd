extends PointLight2D
class_name PlayerLight

# Animation Curves to use
@export var curve_in: Curve
@export var curve_out: Curve

# Brightness values
@onready var current_brightness: float = energy
@onready var goal_brightness: float = energy

# Interpolation state
var interpolating: bool = false
var interpolation_time: float = 0.0
var interpolation_duration: float = 1.0  # Adjust this to control the speed of the interpolation


var flicker_val1: float = energy
var flicker_val2: float = energy

var flickering: bool = false
var is_flick_1: bool = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	
	

	interpolation_time += delta
	var t = min(interpolation_time / interpolation_duration, 1.0)  # Clamp to [0, 1]

	if current_brightness < goal_brightness:
		var curve_value = curve_in.sample(t)
		current_brightness = snappedf(lerp(current_brightness, goal_brightness, curve_value), 0.01)
	elif current_brightness > goal_brightness:
		var curve_value = curve_out.sample(t)
		current_brightness = snappedf(lerp(current_brightness, goal_brightness, curve_value), 0.01)

	# Set the energy accordingly
	energy = current_brightness

	if t >= 1.0:
		if not flickering:
			set_process(false)
		else:
			
			# Handle changing the brightness goal
			if is_flick_1: 
				goal_brightness = flicker_val2				
			else: 
				goal_brightness = flicker_val1
				
			# Flip this bool
			is_flick_1 = not is_flick_1
			
			# Reset interpolation
			interpolation_time = 0.0
	


func set_brightness(new_brightness: float, ease_speed: float = 1.0) -> void:
	goal_brightness = new_brightness
	flickering = false
	interpolating = true
	
	interpolation_time = 0.0  # Reset interpolation time
	interpolation_duration = ease_speed
	
	set_process(true)



func set_flicker(brightness1: float, brightness2: float, speed: float = 0.2) -> void:
	
	flickering = true
	
	# Set vals
	flicker_val1 = brightness1
	flicker_val2 = brightness2
	
	is_flick_1 = true
	
	# Setup for interpolating to first light val
	goal_brightness = flicker_val1
	interpolating = true
	interpolation_time = 0.0
	interpolation_duration = speed # to speed to make it interpolate in that time
	
	set_process(true)
	
