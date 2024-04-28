extends PinJoint2D

# Define the maximum allowable angle in degrees
var max_angle = 30.0

func _process(delta):
	var body_a = get_node_or_null(node_a) as RigidBody2D
	var body_b = get_node_or_null(node_b) as RigidBody2D

	if body_a and body_b:
		# Calculate the current angle difference using global orientations
		var rotation_a = body_a.global_rotation_degrees
		var rotation_b = body_b.global_rotation_degrees
		var angle_difference = rotation_b - rotation_a

		# Normalize the angle to the range -180 to 180
		angle_difference = fmod(angle_difference + 180, 360) - 180

		# Enforce angular limits
		var correction = 0
		if angle_difference > max_angle:
			correction = max_angle - angle_difference
		elif angle_difference < -max_angle:
			correction = -max_angle - angle_difference
		
			

		body_b.rotate(deg_to_rad(correction))
