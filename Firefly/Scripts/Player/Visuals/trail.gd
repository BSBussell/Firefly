extends Line2D
class_name trail

@export var length: int = 10
@export var FLYPH: Flyph
@export var offset: Vector2 = Vector2(0, -10)
@export var obey_gravity: bool = false  # New export variable to toggle gravity effect
@export var gravity_strength: float = 9.8  # Gravity strength, tweak as needed

# Color values
@onready var current_color: Color = modulate
@onready var goal_color: Color = modulate

# Interpolation state
var interpolating: bool = false
var interpolation_time: float = 0.0
var interpolation_duration: float = 1.0  # Adjust this to control the speed of the interpolation

var point = Vector2()
var points_velocity: Array = []  # To store velocity of each point
var fps_adjusted_length: int = 10

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_logger.info("Flyph - Trail Process")

	fps_adjusted_length = max(length * (Engine.get_frames_per_second() / 60), 0)
	
	global_position = Vector2(0, 0)
	global_rotation = 0

	point = FLYPH.global_position + offset
	add_point(point)
	points_velocity.append(Vector2())  # Initialize velocity for the new point

	# Handle the gravity effect
	if obey_gravity:
		for i in range(get_point_count()):
			points_velocity[i] += Vector2(0, gravity_strength * delta)  # Apply gravity
			var new_point = get_point_position(i) + points_velocity[i] * delta
			set_point_position(i, new_point)

	# Maintain the trail length
	while get_point_count() > fps_adjusted_length:
		remove_point(0)
		points_velocity.pop_front()

	# Handle color interpolation
	if interpolating:
		interpolation_time += delta
		var t = min(interpolation_time / interpolation_duration, 1.0)  # Clamp to [0, 1]

		current_color = current_color.lerp(goal_color, t)
		modulate = current_color

		if t >= 1.0:
			interpolating = false  # Stop interpolating
	
	_logger.info("Flyph - Trail Process End")

func set_glow(new_color: Color, duration: float = 1.0) -> void:
	goal_color = new_color
	interpolating = true
	interpolation_time = 0.0  # Reset interpolation time
	interpolation_duration = duration  # Set the duration for this transition
