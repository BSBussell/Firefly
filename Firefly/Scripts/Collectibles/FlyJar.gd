extends "res://Scenes/Camera/CameraTriggers/CameraTarget.gd"
class_name FlyJar

@onready var Sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@export var point_value = 0.0

var nabbed = false
signal collected(jar: FlyJar)

func _ready():
	animation_player.play("Idle")

func _on_area_entered(area):

	# And prevent the player from going into the thing again
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	# Call Collection Logic
	collect()

func collect():
	
	animation_player.play("Grab")
	

	# Emit to any listeners
	# Listeners:
	#   Jar Manager
	#   Potentially UI
	if not nabbed:
		nabbed = true
		emit_signal("collected", self)

	
# I am going to kms	
func _exit_tree():
	remove_from_group("Collectible")

