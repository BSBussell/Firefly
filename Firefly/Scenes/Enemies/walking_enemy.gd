extends CharacterBody2D
class_name goober


@export var speed = 60.0


@onready var standing_zone = $Standing_Zone

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var facing_right = true

func process(delta):
	
	if scale != Vector2(1.0, 1.0):
		scale = scale.move_toward(Vector2(1.0,1.0), delta)

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
	

	var wall_in_front: bool = $FrontRayCast.is_colliding()
	var close_to_ledge: bool = !$BelowRayCast.is_colliding() && is_on_floor()

	if wall_in_front or close_to_ledge:
		flip()
	
	velocity.x = speed
	
	# Have the standing zones applied velocity be the current vel
	standing_zone.constant_linear_velocity = velocity
	move_and_slide()
	
func flip():
	facing_right = !facing_right
	
	scale.x = abs(scale.x) * -1
	
	if facing_right:
		speed = abs(speed)
	else:
		speed = abs(speed) * -1
		
	#scale = Vector2(1.1,0.9)
