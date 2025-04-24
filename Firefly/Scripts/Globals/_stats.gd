extends Node

var first_level: String = "res://Scenes/Levels/TutorialLevel/tutorial.tscn"

var NAME: String = ""
var CURRENT_LEVEL: String
var POSITION: Vector2 = Vector2.ZERO
var TIME: float = 0
var DEATHS: int = 0

## Bool thats set when a run is no longer valid
var INVALID_RUN: bool = false


var run_timer: bool = false

func _ready():
	
	register_global_save()
	#_persist.load_values()
	
func register_global_save() -> void:
	var save_callable: Callable = Callable(self,"save_values")
	var load_callable: Callable = Callable(self,"load_values")
	
	_persist.register_global_class("stats", save_callable, load_callable)

func save_values() -> Dictionary:
	
	var save_data: Dictionary = {}
	
	save_data["Name"] = NAME
	save_data["Level"] = CURRENT_LEVEL
	save_data["Position_X"] = POSITION.x
	save_data["Position_Y"] = POSITION.y
	save_data["Time"] = TIME
	save_data["Deaths"] = DEATHS
	save_data["Invalid"] = INVALID_RUN
	
	return save_data
	
	
	
func load_values(vals: Dictionary) -> void:

	NAME = vals.get("Name", NAME)
	CURRENT_LEVEL = vals.get("Level", CURRENT_LEVEL)
	POSITION.x = vals.get("Position_X", POSITION.x)
	POSITION.y = vals.get("Position_Y", POSITION.y ) 
	DEATHS = vals.get("Deaths", DEATHS)	
	TIME = vals.get("Time", TIME)
	INVALID_RUN = vals.get("Invalid", INVALID_RUN)



func _process(delta):
	# If the game isn't paused increase the timer
	if not get_tree().paused and run_timer:
		
		# If there is an active player who isn't an actor
		if _globals.ACTIVE_PLAYER and not _globals.ACTIVE_PLAYER.is_actor:
			TIME += delta
			
			# IF the user is speeding we show people
			if _config.get_setting('show_speedometer'):
				# Update the discord game time
				_discord.sync_to_game_time(TIME)
				
			# Otherwise don't
			else:
				_discord.sync_to_launch_time()

## Returns Time as a String format specifier in HH:MM:SS:MS format
func get_timer_string(format: String = "HH:MM:SS:MS") -> String:
	var hours: int = int(TIME) / 3600
	var minutes: int = (int(TIME) % 3600) / 60
	var seconds: int = int(TIME) % 60
	var milliseconds: int = int((TIME - int(TIME)) * 1000)

	var display_time: String = format
	  
	display_time = display_time.replace("HH", "%02d" % hours)
	display_time = display_time.replace("MM", "%02d" % minutes)
	display_time = display_time.replace("SS", "%02d" % seconds)
	display_time = display_time.replace("MS", "%03d" % milliseconds)
	
	return display_time

func get_timer_debug_string(format: String = "HH:MM:SS:MS") -> String:
	var display_time: String = get_timer_string(format)
	
	# If the run is   "invalid" attach strings indicating as such
	if INVALID_RUN:
		display_time += " - Assist"
		if Engine.time_scale != 1:
			display_time += " - x%0.2f Time Scale" % [Engine.time_scale]
	
	return display_time

	
	

func reset_timer() -> void:
	TIME = 0

func stop_timer() -> void:
	run_timer = false

func start_timer() -> void:
	run_timer = true
	

func reset_stats() -> void:
	
	reset_timer()
	DEATHS = 0
	INVALID_RUN = false
	POSITION = Vector2.ZERO
	
	# Take us back to the first level
	CURRENT_LEVEL = first_level
