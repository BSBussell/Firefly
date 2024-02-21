extends Marker2D


enum process {Physics, Draw}

@export var Player: Flyph
@export var max_offset = 5
@export var smoothing = 0.2
@export var horizontal_strength = 0.8
@export var vertical_strength = 0.3
@export var processor: process

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _physics_process(delta):
	
	if processor == process.Physics:
		move_cursor(delta)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if processor != process.Physics:
		move_cursor(delta)
	
	pass


func move_cursor(delta):
	var target_position = Vector2.ZERO
	print("Target before adding velocity: ", target_position)
	
	
	# The vector we are basing everything off of
	var velocity = Player.velocity
	
	var smoothed: Vector2
	smoothed.x = velocity.x * horizontal_strength
	smoothed.y = velocity.y * vertical_strength
	
	if smoothed.length() > max_offset:
		smoothed = smoothed.normalized()
		smoothed *= max_offset
	
	print(smoothed)
	
	target_position += smoothed
	print("Target afer adding velocity: ", target_position)
	
	# Smoothly move the marker towards the target position
	position = position.lerp(target_position, smoothing * delta)
