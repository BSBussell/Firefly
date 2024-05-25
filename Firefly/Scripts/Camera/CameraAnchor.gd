class_name PlayerCam
extends Marker2D

@onready var camera_2d = $Camera2D

enum process {Physics, Draw}

@export_category("Player Cam Settings")
# The player the camera is based around
@export var Player: CharacterBody2D

@export_group("Nerd Shit")

# Smooths out the players velocity, used by lookahead
@export var velocity_smoothing: float = 0.8

# At what velocity should the camera move to "falling" mode
@export var fallingThres: float = 150

# Where the camera position is processed at. Keep this the same as the camera2d node
@export var processor: process


@onready var state_machine = $StateMachine

# Lol this is the dumbest way to do this but i'm so raw for it
@onready var startingPos: Vector2 = Vector2(0, 10)
@onready var actual_cam_pos := global_position

@onready var sensor: Area2D = $Sensor/Area2D
# If something is on screen that shouldn't be
var collider: bool = false

var camera_speed: float = 0
var camera_velocity: Vector2 = Vector2.ZERO

# Cause this players bouncin all over the place
var smoothed_velocity: Vector2 = Vector2.ZERO



# Called when the node enters the scene tree for the first time.
func _ready():
	
	# Disable whichever process we aren't using
	if processor == process.Physics:
		set_process(false)
	else:
		set_physics_process(false)
	
	state_machine.init(self)
	pass # Replace with function body.

func _unhandled_input(event):
	
	state_machine.process_input(event)

func _physics_process(delta):
	
	# Calculating a smoothed velocity value constantly
	_logger.info("CameraAnchor - Physics Process")
	smoothed_velocity = smoothed_velocity.lerp(Player.velocity, delta * velocity_smoothing)
	state_machine.process_physics(delta)
	_logger.info("CameraAnchor - Physics Process End")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	# Calculating a smoothed velocity value constantly
	smoothed_velocity = smoothed_velocity.lerp(Player.velocity, delta * velocity_smoothing)
	state_machine.process(delta)


	
# Dictionary to hold target positions with area instance IDs as keys
var targets: Dictionary = {}

# When an area is entered, add its position to the dictionary
func _on_area_2d_area_entered(area: Area2D):
	
	# Cast and do stuff if working
	var target: CameraTarget = area as CameraTarget
	if target:
		targets[target.get_instance_id()] = target

# When an area is exited, remove it from the dictionary
func _on_area_2d_area_exited(area: Area2D):
	
	# Cast
	var target: CameraTarget = area as CameraTarget
	if target:
		var area_id = target.get_instance_id()
		if targets.has(area_id):
			targets.erase(area_id)
