extends "res://Scenes/Camera/CameraTriggers/CameraTarget.gd"
class_name FlyJar

signal collected(jar: FlyJar)

## How many glow points to give on collect
@export var point_value: int = 20
@export var blue: bool = false

@onready var Sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var level_id: int

var id: String
var nabbed: bool = false

func _ready():
	animation_player.play("Idle")
	id = _globals.gen_id(global_position)
	level_id = _globals.ACTIVE_LEVEL.id
	
	if _jar_tracker.is_jar_collected(id):
		
		visible = false
		
		# Wait for loading to finish
		await _loader.finished_loading
		
		# Signal to the counter
		emit_signal("collected", self)
		
		# Free it
		queue_free()
	
	elif not _jar_tracker.is_registered(self):
		
		# Wait for loading to finish
		await _loader.finished_loading
		
		# Make it exist
		_jar_tracker.register_jar_exists(self)
	
func _on_body_entered(body):
	var player: Flyph = body as Flyph
	if not player: return

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
		_jar_tracker.mark_jar_collected(id)
		emit_signal("collected", self)
		
	_globals.ACTIVE_PLAYER.add_glow(point_value)

	
# I am going to kms	
func _exit_tree():
	remove_from_group("Collectible")




