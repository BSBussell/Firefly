extends Node

var first_level: String = "res://Scenes/Levels/TutorialLevel/tutorial.tscn"


var CURRENT_LEVEL: String
var TIME: float = 0
var DEATHS: int = 0

## Bool thats set when a run is no longer valid
var INVALID_RUN: bool = false


var run_timer: bool = false

func _ready():
	
	var save_callable: Callable = Callable(self,"save_values")
	var load_callable: Callable = Callable(self,"load_values")
	
	_persist.register_persistent_class("stats", save_callable, load_callable)
	#_persist.load_values()

func save_values() -> Dictionary:
	
	var save_data: Dictionary = {}
	
	save_data["Level"] = CURRENT_LEVEL
	save_data["Time"] = TIME
	save_data["Deaths"] = DEATHS
	save_data["Invalid"] = INVALID_RUN
	
	return save_data
	
	
	
func load_values(vals: Dictionary) -> void:


	CURRENT_LEVEL = vals.get("Level")
	DEATHS = vals.get("Deaths")	
	TIME = vals.get("Time")
	INVALID_RUN = vals.get("Invalid")



func _process(delta):
	# If the game isn't paused increase the timer
	if not get_tree().paused and run_timer:
		
		# If there is an active player who isn't an actor
		if _globals.ACTIVE_PLAYER and not _globals.ACTIVE_PLAYER.is_actor:
			TIME += delta

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
	
	if INVALID_RUN:
		display_time += " - Debug"
		
		# If the player is adjusting the time scale
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
	
	# Take us back to the first level
	CURRENT_LEVEL = "res://Scenes/Levels/TutorialLevel/tutorial.tscn"
