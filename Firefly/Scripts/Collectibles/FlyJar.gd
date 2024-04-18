extends "res://Scenes/Camera/CameraTriggers/CameraTarget.gd"

@onready var Sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@export var point_value = 0.0

func _ready():
	animation_player.play("Idle")



func _on_area_entered(area):
	animation_player.play("Grab")
	_ui.new_item_found()
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	set_collision_layer_value(7, false)
