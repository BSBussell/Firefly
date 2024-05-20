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
			ui_components[get_script_class_name(ui_element)] = ui_element
			# Connect it to the level
			ui_element.connect_level(context)
			
			ui_element.define_dependencies()



	# Fuck bro, do i really wanna get the map out for this tn?
	# Isn't that pre-mature optimizations :3
	# Loop through the ui components
	for ui_component: UiComponent in ui_components.values():
		# Loop through the dependencies
		for dependency_name: String in ui_component.dependencies.keys():
			# Look up the dependency in the map
			if ui_components.has(dependency_name):
				ui_component.connect_dependency(ui_components[dependency_name])
			else:
				push_warning("Depdency: ", dependency_name, " could not be found!")
		
		# Finally add it to the ui_viewport
		_viewports.ui_viewport.add_child(ui_component)
		

# Method to get the custom class name
func get_script_class_name(obj: Node) -> String:
	var script_class_name = obj.get_class()
	var script: Script = obj.get_script()
	if script != null:
		var script_resource_path = script.resource_path
		for x in ProjectSettings.get_global_class_list():
			if str(x["path"]) == script_resource_path:
				script_class_name = str(x["class"])
				break
	return script_class_name
