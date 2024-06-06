extends Node

## A dictionary that store values from the current game session.
var stored_values: Dictionary = {}


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func register_save_func(class_name: String, save_func: Callable):
	pass