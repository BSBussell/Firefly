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
	# Refresh distance-based camera targets before state updates
	_refresh_distance_camera_targets()
	state_machine.process_physics(delta)
	_logger.info("CameraAnchor - Physics Process End")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	# Calculating a smoothed velocity value constantly
	smoothed_velocity = smoothed_velocity.lerp(Player.velocity, delta * velocity_smoothing)
	# Refresh distance-based camera targets before state updates
	_refresh_distance_camera_targets()
	state_machine.process(delta)


	
# Dictionary to hold target positions with area instance IDs as keys
var targets: Dictionary = {}

func _refresh_distance_camera_targets():
	# Rebuild active targets purely by distance each frame.
	if Player == null:
		return
	var active: Dictionary = {}
	for t in _get_all_camera_targets():
		if not t.is_enabled():
			continue
		if t.OnDistant > 0.0 and Player.global_position.distance_to(t.global_position) <= t.OnDistant:
			active[t.get_instance_id()] = t
	# Swap in the freshly computed set
	targets = active

func _get_all_camera_targets() -> Array:
	var list: Array = []
	var root := get_tree().get_current_scene()
	if root == null:
		root = get_tree().get_root()
	_collect_camera_targets(root, list)
	return list

func _collect_camera_targets(n: Node, out: Array) -> void:
	var t: CameraTarget = n as CameraTarget
	if t != null:
		out.append(t)
	for c in n.get_children():
		_collect_camera_targets(c, out)

# When an area is entered, add its position to the dictionary
func _on_area_2d_area_entered(area: Area2D):
	# Sensor is ignored; distance-based activation only
	pass

# When an area is exited, remove it from the dictionary
func _on_area_2d_area_exited(area: Area2D):
	# Sensor is ignored; distance-based activation only
	pass
