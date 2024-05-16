# UIScript.gd
extends Node
class_name UiLoader

const PAUSE_MENU: PackedScene = preload("res://Core/Game/pause.tscn")
const COLLECTIBLE_COUNTER: PackedScene = preload("res://Scenes/UI_Elements/collectible_counter.tscn")
const RESULTS: PackedScene = preload("res://Scenes/UI_Elements/results.tscn")
const LEVEL_TITLE: PackedScene = preload("res://Scenes/UI_Elements/LevelTitle.tscn")

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
	
	# Empty the ui_components
	ui_components = {}



var ui_components: Dictionary = {}

func load_ui(context: Level) -> void:
	
	# Remove all existing ui
	reset_ui()
	
	# Loop through the packed ui components
	for componentsScenes: PackedScene in context.ui_components:

		# Load the scene
		var instance: Node = componentsScenes.instantiate()

		# Cast it to a UiComponent
		var ui_element: UiComponent = instance as UiComponent

		if ui_element:
			# Add it to the ui_components array with the class name as the key
			ui_components[ui_element.name] = ui_element

			# Connect it to the level
			ui_element.connect_level(context)

			

		
			ui_element.define_dependencies()



	# Fuck bro, do i really wanna get the map out for this tn?
	# Isn't that pre-mature optimizations :3
	# Loop through the ui components
	for ui_component: UiComponent in ui_components.values():
		# Loop through the dependencies
		for dependency: UiComponent in ui_component.dependencies:
			# Look up the dependency in the map
			var dep: UiComponent = ui_components[dependency.name]
			if dep:
				ui_component.connect_dependency(dep)
		
		# Finally add it to the ui_viewport
		_viewports.ui_viewport.add_child(ui_component)
		
			


	# If we haven't already said the levels name
	#if not has_displayed_title or context.id != 0:
		#
		## Put in the levels name
		#var level_title = LEVEL_TITLE.instantiate()
		#level_title.set_title(context.Text)
		#_viewports.ui_viewport.add_child(level_title)
		#has_displayed_title = true
	
	
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
		
