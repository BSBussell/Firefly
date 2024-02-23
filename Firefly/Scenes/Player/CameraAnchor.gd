class_name PlayerCam
extends Marker2D

@onready var camera_2d = $Camera2D
@onready var camera_hit_box = $CameraHitBox

enum process {Physics, Draw}

@export_category("Player Cam Settings")
# The player the camera is based around
@export var Player: CharacterBody2D

# Max distance the camera can be from the player
@export var max_offset: int = 80

# Essentially the cameras speed
@export var smoothing: float = 3.0

@export_group("Nerd Shit")

@export var velocity_smoothing: float = 2.0


# How responsive the camera is to the players horizontal velocity
@export var horizontal_strength: float = 0.7

# How responsive the camera is to the players vertical velocity
@export var vertical_strength: float = 0.3

@export var horizontal_deadzone: float = 20.0

# Sometimes we wanna eat a jump
@export var vertical_deadzone: float = 150

# Where the camera position is processed at
@export var processor: process


@onready var state_machine = $StateMachine

@onready var startingPos: Vector2 = Vector2(0, 10)
@onready var actual_cam_pos := global_position



# Cause this players bouncin all over the place
var smoothed_velocity: Vector2 = Vector2.ZERO

var prevOffset: Vector2 = Vector2(0,0)
var prevBase: Vector2 = Vector2(0,0)


# Called when the node enters the scene tree for the first time.
func _ready():
	
	state_machine.init(self)
	pass # Replace with function body.


func _physics_process(delta):
	if processor == process.Physics:
		state_machine.process_physics(delta)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if processor != process.Physics:
		state_machine.process(delta)



	


