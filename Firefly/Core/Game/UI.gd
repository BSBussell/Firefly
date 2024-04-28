# UIScript.gd
extends Node
class_name UiLoader

const PAUSE_MENU: PackedScene = preload("res://Core/Game/pause.tscn")
const COLLECTIBLE_COUNTER: PackedScene = preload("res://Scenes/UI_Elements/collectible_counter.tscn")
const RESULTS: PackedScene = preload("res://Scenes/UI_Elements/results.tscn")

# Corresponding instance variables
var pause_instance: PauseMenu
var counter_instance: JarCounter
var results_instance: VictoryScreen


var currentLevel: Level


func setup(level: Level):
	
	level.connect_ui_loader(self)
	load_ui(level)
	


func reset_ui():
	
	
	
	for child in _viewports.ui_viewport.get_children():
		child.queue_free()
		
	pause_instance = null
	counter_instance = null
	results_instance = null

func load_ui(context: Level):
	
	# Remove all existing ui
	reset_ui()
	
	if context.Can_Pause:
		print("Setting Up Pause Instance")
		pause_instance = PAUSE_MENU.instantiate()
		_viewports.ui_viewport.add_child(pause_instance)
		pause_instance.visible = false
	
	# If there are jars to collect
	if context.jar_manager:
		
		
	
		# Setup Victory Screen
		results_instance = RESULTS.instantiate()
		_viewports.ui_viewport.add_child(results_instance)
		
		var victory_function: Callable = Callable(results_instance, "show_Victory_Screen")
		context.connect_to_win(victory_function)
		
		# Setup the colelctible counter
		print("Setting up Counter")
		counter_instance = COLLECTIBLE_COUNTER.instantiate()
		_viewports.ui_viewport.add_child(counter_instance)
		
		# If the pause instance exists too
		if context.Can_Pause:
			pause_instance.connect_counter(counter_instance)
			pause_instance.connect_results(results_instance)
		
		# Connect it to the victory screen
		counter_instance.setup(results_instance)
		
