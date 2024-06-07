extends Node

## A dictionary that store values from the current game session.
var stored_values: Dictionary = {}

## The functions that will be called when unloading the current level
var save_funcs: Dictionary = {}

## The functions that will be called when loading the next level
var load_funcs: Dictionary = {}

## Register a classes save and load functions
func register_persistent_class(parent_name: String, save_func: Callable, load_func: Callable):
	
	# Create class dictionary if it doesn't exist
	if not stored_values.has(parent_name):

		# Create a dictionary for the class
		stored_values[parent_name] = {}

	# Put the callable functions in the dictionary
	save_funcs[parent_name] = save_func
	load_funcs[parent_name] = load_func

## Template save and load functions
# func save() -> Dictionary:
# Load all data after loading the level
	

# func load(saved_dict: Dictionary):
# Is passed a dictionary of values from a prior context

## Calls all save functions and stores the values in the dictionary
func save_values():
	for key in stored_values.keys():
		stored_values[key] = save_funcs[key].call()

## Calls all load functions and passes the stored values to them
func load_values():
	for key in stored_values.keys():
		
		# If the keys dictionary is empty, skip it
		if stored_values[key] != {}:
			
			load_funcs[key].call(stored_values[key])


## Reset persistent data
func reset():
	stored_values = {}
	save_funcs = {}
	load_funcs = {}