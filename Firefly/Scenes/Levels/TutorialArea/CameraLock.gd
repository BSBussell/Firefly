extends Node2D

@onready var camera_target: CameraTarget = $CameraTarget

# Called when the node enters the scene tree for the first time.
func _ready():
	camera_target.disable_target()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_controls_finish_dialogue():
	camera_target.enable_target()
	await get_tree().create_timer(2).timeout
	camera_target.disable_target()
