extends Control

@export var wobble_speed: float = 2.0
@export var wobble_amplitude_rot: float = 1.5 # degrees
@export var wobble_amplitude_scale: float = 0.02

var time := 0.0

# func _init():
	
	# Make pivot offset center of object
	

func _process(delta):

	pivot_offset.x = size.x / 2
	pivot_offset.y = size.y / 2
	print("Offset:", pivot_offset)
	time += delta * wobble_speed
	var rot_deg = sin(time * TAU) * wobble_amplitude_rot
	var scale_x = 1.0 + sin(time * TAU + PI/2) * wobble_amplitude_scale
	var scale_y = 1.0 - sin(time * TAU + PI/2) * wobble_amplitude_scale

	rotation_degrees = rot_deg
	scale = Vector2(scale_x, scale_y)
