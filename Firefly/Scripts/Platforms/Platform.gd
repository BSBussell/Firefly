extends Node2D
class_name Platform

signal player_landed(player: Flyph)
signal player_left(player: Flyph)


@export_category("Player Detector")
@export_subgroup("Nodes")
@export var player_detector: Area2D


## Player
var flyph: Flyph = null


func _ready():
	
	var err: Error = player_detector.connect("body_entered", Callable(self, "_on_player_detection_body_entered"))
	
	if err != OK:
		print(err)
		
	err = player_detector.connect("body_exited", Callable(self, "_on_player_detection_body_exited"))
	
	if err != OK:
		print(err)
	
	child_ready()

## Called after parent class ready
func child_ready():
	pass

# We look for if the player touches the ground in the physics function
# Because the player might not be on the ground when they initially enter
# Player detection area. So when the player enters that we know to begin
# Looking for the player land. And we are gambling that they won't land
# on anything else :3
func _physics_process(_delta):
	if flyph and flyph.is_on_floor():
		set_physics_process(false)
		emit_signal("player_landed", flyph)
		flyph = null

func _on_player_detection_body_entered(body):
	
	var player: Flyph = body as Flyph
	if player:
	
		flyph = player
		
		# Begin to check if player is on platform
		set_physics_process(true)


func _on_player_detection_body_exited(body):
	
	if body and not body is Flyph:
		return
	
	emit_signal("player_left", body)
	
	if flyph:
		set_physics_process(false)
		flyph = null
		
