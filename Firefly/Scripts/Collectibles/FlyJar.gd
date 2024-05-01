extends "res://Scenes/Camera/CameraTriggers/CameraTarget.gd"
class_name FlyJar

@onready var Sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@export var point_value = 0.0

var nabbed = false
signal collected(jar: FlyJar)

func _ready():
	animation_player.play("Idle")
	
	var id = gen_id()
	if _jar_tracker.is_jar_collected(id):
		
		await get_tree().create_timer(1).timeout
		
		# Signal to the counter
		emit_signal("collected", self)
		
		# Free it
		queue_free()

func gen_id() -> int:
	
	# Variables that make this jar unique
	var identifiers = [
		global_position,
		_globals.ACTIVE_LEVEL.id
	]
	
	return hash(str(identifiers))

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
		_jar_tracker.mark_jar_collected(gen_id())
		emit_signal("collected", self)

	
# I am going to kms	
func _exit_tree():
	remove_from_group("Collectible")

