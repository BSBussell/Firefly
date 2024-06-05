extends Node
class_name LevelLoader


@onready var game_view_port = $GameViewPort

signal level_free

var current_level_path: String
var current_level_instance: Level = null

func finished_cleaning():
	return game_view_port.get_child_count() == 0

# Called every frame after 
func _process(delta):
	
	if finished_cleaning():
		emit_signal("level_free")
		set_process(false)


func begin_threaded_loading(level_path: String):
	ResourceLoader.load_threaded_request(level_path)


func load_level(level_path: String, spawn_id: String = ""):
	
	current_level_path = level_path
	
	# Load the PackedScene from the specified path
	var level_scene = ResourceLoader.load_threaded_get(level_path)
	# Simulate long load
	# await get_tree().create_timer(5.0).timeout
	if level_scene:
		
		current_level_instance = level_scene.instantiate()
		
		_globals.ACTIVE_LEVEL = current_level_instance
		
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
	return await load_level(current_level_path)
	

func clear_current_level():
	if current_level_instance:
		current_level_instance.queue_free()
		current_level_instance = null
		
		# Our way of beginning the process of checking when godot frees the level
		set_process(true)

func get_current_level():
	
	return current_level_instance

