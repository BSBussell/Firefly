extends Node

## A dictionary that store values from the current game session.
var stored_values: Dictionary = {}

## The functions that will be called when unloading the current level
var save_funcs: Dictionary = {}

## The functions that will be called when loading the next level
var load_funcs: Dictionary = {}


## Save File
var file_path: String = "user://save.json"

func _ready():
	load_file()

## Register a classes save and load functions
func register_persistent_class(parent_name: String, save_func: Callable, load_func: Callable):
	
	# Create class dictionary if it doesn't exist
	if not stored_values.has(parent_name):

		# Create a dictionary for the class
		stored_values[parent_name] = {}

	# Put the callable functions in the dictionary
	save_funcs[parent_name] = save_func
	load_funcs[parent_name] = load_func


func save_file() -> void:
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		var save_data: String = JSON.stringify(stored_values)
		file.store_string(save_data)
		file.close()

# Load settings from the configuration file
func load_file() -> void:
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var config_data: String = file.get_as_text()
		var json: JSON = JSON.new()
		var error: Error = json.parse(config_data)
		if error == OK:
			stored_values = json.data
		file.close()

## Template save and load functions
# func save() -> Dictionary:
# Load all data after loading the level
	

# func load(saved_dict: Dictionary):
# Is passed a dictionary of values from a prior context

## Calls all save functions and stores the values in the dictionary
func save_values():
	
	for key in save_funcs.keys():
		stored_values[key] = save_funcs[key].call()
		
	save_file()

## Calls all load functions and passes the stored values to them
func load_values():
	for key in load_funcs.keys():
		
		# If the keys dictionary is empty, skip it
		if stored_values[key] != {}:
			load_funcs[key].call(stored_values[key])
			
	load_file()


## Reset persistent data
func reset():
	stored_values = {}
	save_funcs = {}
	load_funcs = {}
