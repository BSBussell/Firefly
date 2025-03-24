extends Node

## Dictionary stores the state of jars by their silly ID (i have a silly id calc)
var known_jars: Dictionary = {}  

func _ready():
	
	register_global_saves()
	#_persist.load_values()
	

func register_global_saves() -> void:
	
	var save_callable: Callable = Callable(self, "save_jars")
	var load_callable: Callable = Callable(self, "load_jars")
	
	_persist.register_global_class("JarTracker", save_callable, load_callable)
	
func save_jars() -> Dictionary:
	
	var save_data: Dictionary = {}
	save_data["_comment"] = "Please, be careful messing with this section, progress could be lost 🤗"
	save_data["known_jars"] = known_jars
	return save_data

func load_jars(save_data: Dictionary) -> void:
	
	if save_data.has("known_jars"):
		known_jars = save_data["known_jars"]

func is_registered(jar: FlyJar) -> bool:
	return known_jars.has(jar.id)

func register_jar_exists(jar: FlyJar) -> void:
	if not _loader.loading and not known_jars.has(jar.id):
		
		var jar_data: Dictionary = {}
		jar_data["nabbed"] = jar.nabbed
		jar_data["level_id"] = jar.level_id
		jar_data["blue"] = jar.blue
		
		known_jars[jar.id] = jar_data

func mark_jar_collected(jar_id: String) -> void:
	if not _loader.loading:
		known_jars[jar_id]["nabbed"] = true
		
		# Update the discord jar count	
		_discord.update_jar_count()
	
		# Save the data
		_persist.save_values()


# Also calculates the running tally of jars
func is_jar_collected(jar_id: String) -> bool:
	return known_jars.has(jar_id) and known_jars[jar_id]["nabbed"]


func filter(filt_func: Callable) -> Array:
	return known_jars.values().filter(filt_func)

func get_level_jars(level: int):
	var level_jars: Array = filter(func (value): return value["level_id"] == level)
	return level_jars

## Returns the number of found jars for a specific level
func num_found_jars(level: int):
	
	var found_jars: Array = filter(func (value): 
		return value["level_id"] == level and value["nabbed"] == true
	)
	 
	return found_jars.size()
	
## Returns the total number of jars on a level
func num_known_jars(level: int):
	return get_level_jars(level).size()

## Returns the number of found jars
func total_num_found_jars() -> int:
	var found_jars: Array = filter(func (value): return value["nabbed"] == true) 
	return found_jars.size()

## Returns the total number of jars attainable
func total_num_known_jars() -> int:
	return known_jars.size()

## Clears the collected jars dict
func reset_jars() -> void:
	known_jars.clear()
