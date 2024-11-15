extends Node2D
class_name Platform

signal player_landed(player: Flyph)
signal player_left(player: Flyph)


@export_category("Player Detector")
@export_subgroup("Nodes")
@export var player_detector: Area2D


## Player
var flyph: Flyph = null

var landed: bool = false

func _ready():
	
	var err: Error = player_detector.connect("body_entered", Callable(self, "_on_player_detection_body_entered"))
	
	if err != OK:
		print(err)
		
	
	err = player_detector.connect("body_exited", Callable(self, "_on_player_detection_body_exited"))
	
	if err != OK:
		print(err)
		
	set_physics_process(false)
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
	
	# If we havent landed on the plat yet begin looking for a landing
	if not landed:
		if flyph and flyph.is_on_floor():
			
			landed = true
			emit_signal("player_landed", flyph)
			
	# If we have landed, begin looking for an exit
	elif landed:
		if flyph and not flyph.is_on_floor():
			set_physics_process(false)
			landed = false
			emit_signal("player_left", flyph)
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
	

	if flyph:
		pass
		if flyph.is_on_floor():
			return
		
		set_physics_process(false)
		if landed:
			landed = false
			emit_signal("player_left", flyph)
		
		flyph = null
		
