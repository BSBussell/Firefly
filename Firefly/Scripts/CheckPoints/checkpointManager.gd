extends Node2D
class_name CheckPointManager

var active_Checkpoint: CheckPoint = null

# Called when the node enters the scene tree for the first time.
func _ready():

	# Register all our checkpoints
	for child in get_children():
		var checkpoint = child as CheckPoint
		if checkpoint:
			checkpoint.set_manager(self)

## Deactivates the current active checkpoint and replaces it with this
func update_Active(checkpoint: CheckPoint):
	
	# If one is already active, deactivate it
	if active_Checkpoint:
		active_Checkpoint.deactivate_checkpoint()
		
	# Set the active one
	active_Checkpoint = checkpoint

# Not sure why you'd do this but ya know
func deactivate():
	active_Checkpoint.deactivate_checkpoint()
	active_Checkpoint = null
