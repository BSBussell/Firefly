extends Node2D
class_name MovingPlat

@export var speed_scale: float = 1.0
@export var closed: bool = false

@export_category("Protected Variables")
@export_group("Only touch in child classes")
@export var progress_node: PathFollow2D

var max_length: int


# Called when the node enters the scene tree for the first time.
func _ready():
	
	
	
	if progress_node:
		
		# Get Max Length
		progress_node.progress_ratio = 1.0
		max_length = floor(progress_node.progress)
		progress_node.progress_ratio = 0.0
		
		if closed:
			
			progress_node.loop = false  
		else:
			
			progress_node.loop = true
	else:
		printerr("FAILED TO SETUP PROTECTED VARIABLES IN: ", self.name)



func  _process(delta):
	
	if progress_node:
		if closed:
			progress_node.progress += (1 * speed_scale)
		else:
			progress_node.progress += (1 * speed_scale)
			if progress_node.progress_ratio >= 1.0 or progress_node.progress_ratio <= 0:
				speed_scale *= -1
