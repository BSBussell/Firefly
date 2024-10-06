extends Node

var collected_jars: Dictionary = {}  # Dictionary to store the collected state of jars by their instance ID

func _ready():
	
	var save_callable: Callable = Callable(self, "save_jars")
	var load_callable: Callable = Callable(self, "load_jars")
	
	_persist.register_persistent_class("JarTracker", save_callable, load_callable)
	_persist.load_values()
	
func save_jars() -> Dictionary:
	
	var save_data: Dictionary = {}
	save_data["collected_jars"] = collected_jars
	return save_data

func load_jars(save_data: Dictionary) -> void:
	
	collected_jars = save_data["collected_jars"]

func is_registered(jar_id: String) -> bool:
	return collected_jars.has(jar_id)

func register_jar_exists(jar_id: String) -> void:
	if not _loader.loading and not collected_jars.has(jar_id):
		collected_jars[jar_id] = false

func mark_jar_collected(jar_id: String) -> void:
	if not _loader.loading:
		collected_jars[jar_id] = true
		
		_persist.save_values()


# Also calculates the running tally of jars
func is_jar_collected(jar_id: String) -> bool:
	return collected_jars.has(jar_id) and collected_jars[jar_id]


## Returns the number of found jars
func num_found_jars() -> int:
	var found_jars: Array = collected_jars.values().filter(func (value): return value == true)
	return found_jars.size()
	
func num_known_jars() -> int:
	return collected_jars.size()

## Clears the collected jars dict
func reset_jars() -> void:
	collected_jars.clear()
