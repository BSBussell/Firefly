extends PointLight2D

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

	energy = current_brightness

	if t >= 1.0:
		
		set_process(false)
	


func set_brightness(new_brightness: float) -> void:
	goal_brightness = new_brightness
	interpolating = true
	interpolation_time = 0.0  # Reset interpolation time
	
	set_process(true)
