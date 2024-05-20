extends Node2D
class_name RopeManager

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.



func reset_worms():
	
	var ropes = []
	ropes = get_children()
	for rope: Rope in ropes:
		if rope.GlowWorm:
			rope.kill_worm()
