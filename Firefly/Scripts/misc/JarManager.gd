extends Node2D
class_name JarManager

var max: int

# Called when the node enters the scene tree for the first time.
func _ready():
	
	max = get_child_count()
	
	
	
	#_ui.MAX = get_child_count()
	
	#_ui.COUNTER.text = "0 / %f" % _ui.COLLECTED % _ui.MAX


