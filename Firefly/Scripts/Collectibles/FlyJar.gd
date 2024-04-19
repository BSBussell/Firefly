extends "res://Scenes/Camera/CameraTriggers/CameraTarget.gd"
class_name FlyJar

@onready var Sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@export var point_value = 0.0

signal collected(jar: FlyJar)

func _ready():
	animation_player.play("Idle")



func _on_area_entered(area):
	animation_player.play("Grab")
	
	# TODO: Use Signals for this
	# So instead of falling a global method
	# Emit a signal. That way you can have multiple
	# Methods respond to that signal
	emit_signal("collected", self)
	#_ui.new_item_found()
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	set_collision_layer_value(7, false)
