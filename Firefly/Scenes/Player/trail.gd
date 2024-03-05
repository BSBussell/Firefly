extends Line2D

@export var length = 10
var point = Vector2()

# Interpolation state
var interpolating: bool = false
var interpolation_time: float = 0.0
var interpolation_duration: float = 1.0  # Adjust this to control the speed of the interpolation

# Color values
@onready var current_color: Color = modulate
@onready var goal_color: Color = modulate

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_position = Vector2(0, 0)
	global_rotation = 0

	point = get_parent().get_parent().global_position
	point.y -= 10

	add_point(point)

	while get_point_count() > length:
		remove_point(0)

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
