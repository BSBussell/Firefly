extends Path2D
class_name CameraRail

@export var ActivationArea: Area2D

@export var STIFFNESS = 100.0
@onready var DAMPING = 2.0 * sqrt(STIFFNESS)  # critical damping

@onready var follow_node: PathFollow2D = $FollowNode
@onready var camera_target = $FollowNode/CameraTarget

var player: Flyph = null

# Called when the node enters the scene tree for the first time.
func _ready():

	# If we have an activation area, connect the signal to the function.
	if ActivationArea:
		ActivationArea.connect("body_entered", Callable(self, "_on_activation_area_body_entered"))
		ActivationArea.connect("body_exited", Callable(self, "_on_activation_area_body_exited"))
	else:
		push_error("CameraRail: Failed to setup ActivationArea")

	set_process(false) # Disable process by default.

	pass # Replace with function body.


var cam_vel := 0.0  # store this as a member variable



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not player:
		return
	
	target_blend(delta)
	
	
	if not (curve and curve.get_point_count() > 0):
		push_error("CameraRail: Curve is missing or has no points")
		return
		
	
	
	var local_pos: Vector2 = to_local(player.global_position)
	var closest_points: Vector2 = curve.get_closest_point(local_pos)
	var closest_offset: float = curve.get_closest_offset(local_pos)
	
	if !is_finite(closest_offset):
		push_error("CameraRail: Closest offset is not finite")
		return
	
	# Get distance from each other
	var distance: float = (closest_points - local_pos).length()
	if distance < 200:
		
		camera_target.enable_target()
		var target = closest_offset
		var pos = follow_node.progress

		# spring force = –k·x
		var force = STIFFNESS * (target - pos)
		# damping force = –c·v
		var damp  = -DAMPING * cam_vel

		# integrate acceleration
		cam_vel += (force + damp) * delta
		# integrate velocity
		pos += cam_vel * delta

		follow_node.progress = pos
	else:
		camera_target.disable_target()
		follow_node.progress = closest_offset
		
	


var blend_smooth: float = 1
func target_blend(delta):
	camera_target.blend_override = move_toward(camera_target.blend_override, 1.0, blend_smooth* delta)	
	print(camera_target.blend_override)
	
	camera_target.pull_strength = move_toward(camera_target.pull_strength, 20, blend_smooth * 15 * delta)
	print(camera_target.pull_strength)

func _on_player_in(flyph: Flyph):
	# This function is called when the player enters the activation area.
	print("Player entered the activation area")
	
	camera_target.enable_target()
	camera_target.blend_override = 0.0
	camera_target.pull_strength = 0
	print(camera_target.blend_override)
	player = flyph
	
	var local_pos = to_local(player.global_position)
	var closest_offset = curve.get_closest_offset(local_pos)
	follow_node.progress = closest_offset
	
	set_process(true) # Enable process when player is in the area.




func _on_player_out(_flyph: Flyph):
	# This function is called when the player exits the activation area.
	print("Player exited the activation area")
	
	camera_target.disable_target()
	player = null
	set_process(false) # Disable process when player is out of the area.


func _on_activation_area_body_entered(body):
	
	# Check if body is of type Flyph
	if body is Flyph:
		_on_player_in(body)
	else:
		print("Not a Flyph")
	
	

func _on_activation_area_body_exited(body):
	
	# Check if body is of type Flyph
	if body is Flyph:
		_on_player_out(body)
		
	else:
		print("Not a Flyph")
	
	

#
#func player_died():
	#camera_target.blend_override = 0
	#camera_target.ca

# func _on_activation_area_body_entered(body):
# 	pass # Replace with function body.


# func _on_activation_area_body_exited(body):
# 	pass # Replace with function body.
