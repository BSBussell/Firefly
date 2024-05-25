extends CharacterBody2D
class_name goober


@export var accel = 750
@export var deccel = 550
@export var speed = 60.0

@onready var standing_zone = $Standing_Zone
@onready var animated_sprite_2d = $SquishNode/AnimatedSprite2D
@onready var bounce_cool_down = $BounceCoolDown
@onready var front_ray_cast = $Raycasts/FrontRayCast
@onready var below_ray_cast = $Raycasts/BelowRayCast


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var facing_right = true

func _ready():
	pass


func _physics_process(delta):
	
	_logger.info("Goober - Physics Process")
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
	

	var wall_in_front: bool = front_ray_cast.is_colliding()
	var close_to_ledge: bool = !below_ray_cast.is_colliding() && is_on_floor()

	if wall_in_front or close_to_ledge:
		flip()
	
	accelerate(delta)
	
	move_and_slide()
	
	_logger.info("Goober - Physics Process End")

func accelerate(delta: float) -> void:
	
	if sign(velocity.x) != sign(speed):
		velocity.x = move_toward(velocity.x, speed, delta * deccel)
	else:
		velocity.x = move_toward(velocity.x, speed, delta * accel)

	
func flip():
	facing_right = !facing_right
	
	scale.x = abs(scale.x) * -1
	
	if facing_right:
		speed = abs(speed)
	else:
		speed = abs(speed) * -1
		

var stored_speed: float
func _on_bouncy_bounce():
	print("Starting Cool Down")
	#stored_speed = speed
	#speed = 0
	velocity.x = velocity.x * -0.5
	#bounce_cool_down.start()
	
	
func _on_bounce_cool_down_timeout():
	speed = stored_speed
