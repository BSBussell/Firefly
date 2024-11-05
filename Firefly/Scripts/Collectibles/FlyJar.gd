extends "res://Scenes/Camera/CameraTriggers/CameraTarget.gd"
class_name FlyJar

@onready var Sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@export var point_value = 20

var nabbed = false
signal collected(jar: FlyJar)

func _ready():
	animation_player.play("Idle")
	
	
	
	var id: String = gen_id()
	
	if _jar_tracker.is_jar_collected(id):
		
		visible = false
		
		# Wait for loading to finish
		await _loader.finished_loading
		
		# Signal to the counter
		emit_signal("collected", self)
		
		# Free it
		queue_free()
	
	elif not _jar_tracker.is_registered(id):
		
		# Wait for loading to finish
		await _loader.finished_loading
		
		# Make it exist
		_jar_tracker.register_jar_exists(id)
		

func gen_id() -> String:
	
	# Variables that make this jar unique
	var identifiers = [
		global_position,
		_globals.ACTIVE_LEVEL.id
	]
	
	return str(hash(str(identifiers)))

func _on_area_entered(_area):

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
		
	_globals.ACTIVE_PLAYER.add_glow(point_value  )

	
# I am going to kms	
func _exit_tree():
	remove_from_group("Collectible")

