extends Node
class_name LevelLoader


@onready var game_view_port = $GameViewPort


var current_level_path: String
var current_level_instance: Level = null


func load_level(level_path: String, spawn_id: String = ""):
	clear_current_level()
	current_level_path = level_path
	
	# Load the PackedScene from the specified path
	var level_scene = load(level_path) as PackedScene
	if level_scene:
		
		current_level_instance = level_scene.instantiate()
		
		print(spawn_id)
		# If we are given a spawn point id set it
		if spawn_id:
			print(spawn_id)
			current_level_instance.set_spawn_id(spawn_id)
			
		current_level_instance.connect_level_loader(self)
		
		game_view_port.add_child(current_level_instance)
		
		
		
		
		
		return current_level_instance
	else:
		print("Failed to load level as a PackedScene at path:", level_path)

func reload_level() -> Level:
	return load_level(current_level_path)
	

func clear_current_level():
	if current_level_instance:
		current_level_instance.queue_free()
		current_level_instance = null

func get_current_level():
	
	return current_level_instance

