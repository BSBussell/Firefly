## TODO: Fix the trail getting longer/shorter the lower the fps

extends Line2D

@export var length: int = 10

# Color values
@onready var current_color: Color = modulate
@onready var goal_color: Color = modulate




# Interpolation state
var interpolating: bool = false
var interpolation_time: float = 0.0
var interpolation_duration: float = 1.0  # Adjust this to control the speed of the interpolation

var point = Vector2()

var fps_adjusted_length: int = 10


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	fps_adjusted_length = max(length * (Engine.get_frames_per_second() / 60), 0)
	
	global_position = Vector2(0, 0)
	global_rotation = 0

	point = get_parent().get_parent().global_position
	point.y -= 10

	add_point(point)

	#if fps_adjusted_length >= 0: 
	while get_point_count() > fps_adjusted_length:
		remove_point(0)
	#else:
		#print("WOAH FR?")

	if interpolating:
		interpolation_time += delta
		var t = min(interpolation_time / interpolation_duration, 1.0)  # Clamp to [0, 1]

		current_color = current_color.lerp(goal_color, t)
		modulate = current_color

		if t >= 1.0:
			interpolating = false  # Stop interpolating

func set_glow(new_color: Color, duration: float = 1.0) -> void:
	goal_color = new_color
	interpolating = true
	interpolation_time = 0.0  # Reset interpolation time
	interpolation_duration = duration  # Set the duration for this transition
