extends "res://Scripts/Events/base_event.gd"

enum HEIGHTS { HIGH, MID, LOW}

@export var HEIGHT: HEIGHTS

@onready var player_cam = $"../../PlayerCam"

var heights = [-45, -20, 10]

func _ready():
	set_physics_process(false)

func _physics_process(_delta):
	if enter_body:
		print(heights[HEIGHT])
		player_cam.set_camera_height(heights[HEIGHT])
		set_physics_process(false)

func on_enter(_body):
	print("lol")
	set_physics_process(true)

func on_exit(_body):
	set_physics_process(true)


func _on_area_entered(area):
	pass # Replace with function body.
