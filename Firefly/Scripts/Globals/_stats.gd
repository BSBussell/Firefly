extends Node

var DEATHS: int = 0
var TIME: float = 0

var INVALID_RUN: bool = false

var run_timer: bool = false

func _process(delta):
	# If the game isn't paused increase the timer
	if not get_tree().paused and run_timer:
		TIME += delta

## Returns Time as a String in MM:SS:MS
func get_timer_string() -> String:

	

	var minutes: int = int(TIME) / 60
	var seconds: int = int(TIME) % 60
	var milliseconds: int = int((TIME - int(TIME)) * 1000)

	var display_time: String = "%02d:%02d:%03d" % [minutes, seconds, milliseconds]

	if INVALID_RUN:
		display_time += " - Debug Commands Used"
		
		# If the player is adjusting the time scale
		if Engine.time_scale != 1:
			display_time += " - x%0.2f Time Scale" % [Engine.time_scale]


	return display_time


func reset_timer() -> void:

	run_timer = 0
	TIME = 0

func stop_timer() -> void:
	run_timer = false

func start_timer() -> void:
	run_timer = true