extends CharacterBody2D

@export_subgroup("Movement Properties")
@export var SPEED = 100.0
@export var ACCEL = 600.0
@export var FRICTION = 600.0
@export var JUMP_VELOCITY = -200.0
@export var FASTFALL_MULTIPLIER = 3
var FF_Vel = JUMP_VELOCITY / FASTFALL_MULTIPLIER

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if is_on_floor():
		
		if Input.is_action_just_pressed("ui_accept"):
			velocity.y = JUMP_VELOCITY
	else:
		if Input.is_action_just_released("ui_accept") and velocity.y < FF_Vel:
			velocity.y = FF_Vel

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = move_toward(velocity.x, SPEED*direction, ACCEL * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION*delta)

	move_and_slide()
