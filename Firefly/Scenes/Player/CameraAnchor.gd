extends Marker2D

@onready var camera_2d = $Camera2D
@onready var camera_hit_box = $CameraHitBox

enum process {Physics, Draw}

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

# Where the camera position is processed at
@export var processor: process



@onready var startingPos: Vector2 = position
@onready var actual_cam_pos := global_position

var prevTarget: Vector2 = Vector2(0,0)


# Called when the node enters the scene tree for the first time.
func _ready():
	
	position = Vector2.ZERO
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
	var target_position = Player.global_position
	
	# The vector we are basing everything off of
	var velocity = Player.velocity
	
	# This is how far we will offset from our center
	var offset: Vector2 = Vector2.ZERO

	
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
		
	# Add our offset to the target position
	target_position += offset
	
	# Smoothly move the marker towards the target position
	actual_cam_pos.x = lerpi(actual_cam_pos.x, target_position.x, smoothing * delta)
	actual_cam_pos.y = lerpi(actual_cam_pos.y, target_position.y, smoothing * delta)
	
	prevTarget = target_position
	
	
	# Set the global position to a rounded position of the actual cam
	global_position = actual_cam_pos.round()
			
	# BTW spent the day debugging this code trying to fix it just to find
	# Someone on github be like "yeah doing this makes it work btw"
	camera_2d.align()
	
	
func has_escape_margin():
	var player_pos = Player.global_position
	var camera_pos = camera_2d.global_position
	var camera_size = Vector2(320, 180)
	
	
	var left_margin = camera_pos.x - camera_2d.drag_left_margin * camera_size.x / 2
	var right_margin = camera_pos.x + camera_2d.drag_right_margin * camera_size.x / 2
	var top_margin = camera_pos.y - camera_2d.drag_top_margin * camera_size.y / 2
	var bottom_margin = camera_pos.y + camera_2d.drag_bottom_margin * camera_size.y / 2

	return player_pos.x < left_margin || player_pos.x > right_margin || player_pos.y < top_margin || player_pos.y > bottom_margin

	
	

# Magic function made by Gerblesh on github from https://github.com/godotengine/godot-proposals/issues/6389
static func lerpi(origin: float, target: float, weight: float) -> float:
	target = floorf(target)
	origin = floorf(origin)
	var distance: float = ceilf(absf(target - origin) * weight)
	return move_toward(origin, target, distance)
