extends Node

## A dictionary that store values from the current game session.
var stored_values: Dictionary = {}

## Global
var global_save_funcs: Dictionary = {}

var global_load_funcs: Dictionary = {}

## The functions that will be called when unloading the current level
var save_funcs: Dictionary = {}

## The functions that will be called when loading the next level
var load_funcs: Dictionary = {}

var save_dir_path: String = "user://saves/"

var save_dir: DirAccess

## Save File
var current_file_path: String = ""

func _ready():
	
	save_dir = DirAccess.open(save_dir_path)
	
	# Create the "saves" directory if it doesn't exist
	if not save_dir:
		var dir: DirAccess = DirAccess.open("user://")
		dir.make_dir("saves")
		save_dir = DirAccess.open(save_dir_path)
	
	#load_file(file_path)


## Template save and load functions
# func save() -> Dictionary:
# Load all data after loading the level
	

# func load(saved_dict: Dictionary):
# Is passed a dictionary of values from a prior context

## Register a classes save and load functions
func register_persistent_class(parent_name: String, save_func: Callable, load_func: Callable):
	
	# Create class dictionary if it doesn't exist
	if not stored_values.has(parent_name):

		# Create a dictionary for the class
		stored_values[parent_name] = {}

	# Put the callable functions in the dictionary
	save_funcs[parent_name] = save_func
	load_funcs[parent_name] = load_func

func register_global_class(parent_name: String, save_func: Callable, load_func: Callable):

	# Create class dictionary if it doesn't exist
	if not stored_values.has(parent_name):

		# Create a dictionary for the class
		stored_values[parent_name] = {}

	# Put the callable functions in the dictionary
	global_save_funcs[parent_name] = save_func
	global_load_funcs[parent_name] = load_func

func new_file(file_name: String) -> String:
	
	var path: String
	
	# Build path 
	path = save_dir_path + file_name + ".json"
	
	# Reset Save Vals
	stored_values = {}
	_stats.reset_stats()
	_stats.NAME = file_name
	_jar_tracker.reset_jars()
	save_file(path)
	
	
	# Return the path
	return file_name + ".json"
	
## Relatively simple tbh but like we'll see what it needs in the future
func delete_file(file_name: String) -> void:
	save_dir.remove(file_name)

## Saves either the current instanced file, or a specified one
func save_file(path: String = current_file_path) -> void:
	
	if path == "":
		return
		
	path = save_dir_path + path
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file:
		var save_data: String = JSON.stringify(stored_values, "\t")
		file.store_string(save_data)
		file.close()

# Load settings from the configuration file
func load_file(path: String) -> void:
	
	path = save_dir_path + path
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file:
		var config_data: String = file.get_as_text()
		var json: JSON = JSON.new()
		var error: Error = json.parse(config_data)
		if error == OK:
			stored_values = json.data
		file.close()



## Calls all save functions and stores the values in the dictionary
func save_values():
	
	# Global Save Funcs
	var keys_to_remove = []
	for key in global_save_funcs.keys():
		if global_save_funcs[key] and global_save_funcs[key].is_valid():
			stored_values[key] = global_save_funcs[key].call()
		else:
			# Mark invalid functions for removal
			keys_to_remove.append(key)
	
	# Remove invalid global functions
	for key in keys_to_remove:
		global_save_funcs.erase(key)
		global_load_funcs.erase(key)
		print("Removed invalid global persistence functions for: ", key)
	
	# Local Save Funcs
	keys_to_remove.clear()
	for key in save_funcs.keys():
		if save_funcs[key] and save_funcs[key].is_valid():
			stored_values[key] = save_funcs[key].call()
		else:
			# Mark invalid functions for removal
			keys_to_remove.append(key)
	
	# Remove invalid local functions
	for key in keys_to_remove:
		save_funcs.erase(key)
		load_funcs.erase(key)
		print("Removed invalid persistence functions for: ", key)
		
	save_file()

## Calls all load functions and passes the stored values to them
func load_values():
	
	# Load Global Values
	var keys_to_remove = []
	for key in global_load_funcs.keys():
		
		# If the keys dictionary is empty skip it
		if stored_values.has(key) and stored_values[key] != {}:
			if global_load_funcs[key] and global_load_funcs[key].is_valid():
				global_load_funcs[key].call(stored_values[key])
			else:
				# Mark invalid functions for removal
				keys_to_remove.append(key)
	
	# Remove invalid global functions
	for key in keys_to_remove:
		global_save_funcs.erase(key)
		global_load_funcs.erase(key)
		print("Removed invalid global load functions for: ", key)
	
	# Load Local Values
	keys_to_remove.clear()
	for key in load_funcs.keys():
		
		# If the keys dictionary is empty, skip it
		if stored_values.has(key) and stored_values[key] != {}:
			if load_funcs[key] and load_funcs[key].is_valid():
				load_funcs[key].call(stored_values[key])
			else:
				# Mark invalid functions for removal
				keys_to_remove.append(key)
	
	# Remove invalid local functions
	for key in keys_to_remove:
		save_funcs.erase(key)
		load_funcs.erase(key)
		print("Removed invalid load functions for: ", key)
			
	#load_file(file_path)


## Returns a PackedStringArray of all the saves filepaths, sorted by most reccently saved
func get_saves() -> Array:
	var saves = Array(save_dir.get_files())
	saves.sort_custom(Callable(self, "_sort_by_modified_time"))
	return saves

# Helper function to sort files by modification time.
func _sort_by_modified_time(a: String, b: String) -> int:
	var dir_path = save_dir.get_current_dir()  # Get the directory path
	var time_a = FileAccess.get_modified_time(dir_path + "/" + a)
	var time_b = FileAccess.get_modified_time(dir_path + "/" + b)
	return time_a > time_b 
	
## Gets the values from the key
func get_values(key: String) -> Dictionary:
	if stored_values.has(key):
		return stored_values[key]
	return {}
	
## Gets the values of the save at the specified file path
func get_save_values(file_path: String) -> Dictionary:
	reset()
	load_file(file_path)
	load_values()
	return stored_values
	
	
func load_save(file_path: String) -> void:
	
	current_file_path = file_path
	
	load_file(file_path)
	load_values()
	
	

## Reset persistent data
func reset():
	stored_values = {}
	save_funcs = {}
	load_funcs = {}

## Clean up invalid function references
func cleanup_invalid_functions():
	
	# Clean up global functions
	var keys_to_remove = []
	for key in global_save_funcs.keys():
		if not global_save_funcs[key] or not global_save_funcs[key].is_valid():
			keys_to_remove.append(key)
	
	for key in keys_to_remove:
		global_save_funcs.erase(key)
		global_load_funcs.erase(key)
		print("Cleaned up invalid global functions for: ", key)
	
	# Clean up local functions
	keys_to_remove.clear()
	for key in save_funcs.keys():
		if not save_funcs[key] or not save_funcs[key].is_valid():
			keys_to_remove.append(key)
	
	for key in keys_to_remove:
		save_funcs.erase(key)
		load_funcs.erase(key)
		print("Cleaned up invalid local functions for: ", key)

## Unregister a specific persistent class
func unregister_persistent_class(parent_name: String):
	if save_funcs.has(parent_name):
		save_funcs.erase(parent_name)
	if load_funcs.has(parent_name):
		load_funcs.erase(parent_name)
	print("Unregistered persistent class: ", parent_name)

## Unregister a specific global class
func unregister_global_class(parent_name: String):
	if global_save_funcs.has(parent_name):
		global_save_funcs.erase(parent_name)
	if global_load_funcs.has(parent_name):
		global_load_funcs.erase(parent_name)
	print("Unregistered global class: ", parent_name)
	
	
