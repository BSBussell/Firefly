extends Node
class_name LevelLoader

## Emitted when the level has been fully cleaned up
signal level_free

@onready var game_view_port: Viewport = $GameViewPort

var current_level_path: String
var current_level_instance: Level = null


## Returns true if the level has been fully cleaned up
func finished_cleaning():
	return game_view_port.get_child_count() == 0

# Called every frame while cleaning up the level, once the level is cleaned up we emit the level_free signal, and stop processing 
func _process(delta) -> void:
	
	if finished_cleaning():
		emit_signal("level_free")
		set_process(false)

 
func begin_threaded_loading(level_path: String) -> void:
	ResourceLoader.load_threaded_request(level_path)


func load_level(level_path: String, spawn_id: String = "") -> Level:
	
	# Update the current level path
	current_level_path = level_path
	
	# Load the PackedScene from the specified path
	var level_scene: Resource = ResourceLoader.load_threaded_get(level_path)
	
	if level_scene:
		
		current_level_instance = level_scene.instantiate()
		
		_globals.ACTIVE_LEVEL = current_level_instance
		
		# If we are given a spawn point id set it
		if spawn_id:
			current_level_instance.set_spawn_id(spawn_id)
			
		# Connect the level loader to the level
		current_level_instance.connect_level_loader(self)
		
		# Add the level to the game_view_port
		game_view_port.add_child(current_level_instance)
		
		return current_level_instance
	
	else:
		print("Level failed to be loaded at path:", level_path)
		return null

func reload_level() -> Level:
	return await load_level(current_level_path)
	

func clear_current_level() -> void:
	if current_level_instance:
		current_level_instance.queue_free()
		current_level_instance = null
		
		# Begin checking if the level has been cleaned.
		set_process(true)

## Returns the current level instance
func get_current_level() -> Level:
	return current_level_instance

