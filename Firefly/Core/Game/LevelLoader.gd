extends Node

@onready var game_view_port = $GameViewPort


var current_level_instance: Node = null

func load_level(level_path: String):
	clear_current_level()
	
	# Load the PackedScene from the specified path
	var level_scene = load(level_path) as PackedScene
	if level_scene:
		current_level_instance = level_scene.instantiate()
		game_view_port.add_child(current_level_instance)
	else:
		print("Failed to load level as a PackedScene at path:", level_path)

func clear_current_level():
	if current_level_instance:
		current_level_instance.queue_free()
		current_level_instance = null
