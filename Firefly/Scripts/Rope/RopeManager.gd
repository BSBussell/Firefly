extends Node2D
class_name RopeManager


# Set the worms back to their initial position
func reset_worms():
	
	var ropes = []
	ropes = get_children()
	for rope: Rope in ropes:
		if rope.GlowWorm:
			rope.kill_worm()
