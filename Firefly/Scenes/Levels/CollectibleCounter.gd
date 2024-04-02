extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	
	_ui.MAX = get_child_count()
	
	#_ui.COUNTER.text = "0 / %f" % _ui.COLLECTED % _ui.MAX
	pass # Replace with function body.
