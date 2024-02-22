extends Marker2D

@onready var camera_2d = $Camera2D

enum process {Physics, Draw}
enum curve {Linear, Cubic, Gerblesh}

@export_category("Player Cam Settings")
# The player the camera is based around
@export var Player: CharacterBody2D

# Max distance the camera can be from the player
@export var max_offset: int = 5

# Essentially the cameras speed
@export var smoothing: float = 4.0

@export_group("Nerd Shit")
# How responsive the camera is to the players horizontal velocity
@export var horizontal_strength: float = 0.8

# How responsive the camera is to the players vertical velocity
@export var vertical_strength: float = 0.3

# The type of camera smoothing to use
@export var curve_type: curve = curve.Cubic

# Where the camera position is processed at
@export var processor: process

# Broken lmao
@export var sub_pixel_smoothing: bool = false

@export var use_global_position: bool = false


@onready var actual_cam_pos := global_position


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


func move_cursor(delta):
	
	# Our Center / Starting Position
	var target_position = Vector2.ZERO
	
	if use_global_position: 
		target_position = Player.global_position
	
	
	# The vector we are basing everything off of
	var velocity = Player.velocity
	
	# This is how far we will offset from our center
	var offset: Vector2
	offset.x = velocity.x * horizontal_strength
	
	if velocity.y > -40:
		offset.y = velocity.y * vertical_strength
	else:
		offset.y = velocity.y * 0.1
	
	# Ensure we aren't further than the max offset
	if offset.length() > max_offset:
		# Get the normalized value
		offset = offset.normalized()
		
		# Set the length to now be the max offset
		offset *= max_offset
	
	print(offset)
	
	# Add our offset to the target position
	target_position += offset
	print("Target afer adding velocity: ", target_position)
	
	# Smoothly move the marker towards the target position
	if curve_type == curve.Linear:
		actual_cam_pos = actual_cam_pos.lerp(target_position, smoothing * delta)
		
		
	elif curve_type == curve.Gerblesh:
		actual_cam_pos.x = lerpi(actual_cam_pos.x, target_position.x, smoothing * delta)
		actual_cam_pos.y = lerpi(actual_cam_pos.y, target_position.y, smoothing * delta)
		
	# Use cubic interpolation for smoother camera movement
	else:
		actual_cam_pos = actual_cam_pos.cubic_interpolate(target_position, actual_cam_pos, target_position, smoothing * delta)

	
	if sub_pixel_smoothing:
	
		# Calculate the "subpixel" position of the new camera position
		var cam_subpixel_pos = actual_cam_pos.round() - actual_cam_pos
		
		# I'll work on this once i have subpixel working at any amount of smoothness lmao
		#cam_subpixel_pos = snapped(cam_subpixel_pos, Vector2(0.01,0.01))

		# Update the Main ViewportContainer's shader uniform
		_viewports.game_viewport_container.material.set_shader_parameter("sub_pixel_offset", cam_subpixel_pos)
		print("SubPixel: ", cam_subpixel_pos)
	
	
	
	# Set the global position to a rounded position of the actual cam
	if use_global_position:
		global_position = actual_cam_pos.round()
	else:
		position = actual_cam_pos.round()
		
	camera_2d.align()
	

static func lerpi(origin: float, target: float, weight: float) -> float:
	target = floorf(target)
	origin = floorf(origin)
	var distance: float = ceilf(absf(target - origin) * weight)
	return move_toward(origin, target, distance)
