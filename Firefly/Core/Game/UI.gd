# UIScript.gd
extends Control
class_name UiLoader

@onready var global_themer = $UIViewPort/GlobalThemer

signal FinishedLoading


# The level that is loaded
var currentLevel: Level

## The current active ui components, keyed by their class name
var ui_components: Dictionary = {}

## Begin setup the ui components requested by the level
func setup(level: Level):
	level.connect_ui_loader(self)
	load_ui(level)
	

## Removes all the ui components from the ui_viewport
func reset_ui():
	
	for child in global_themer.get_children():
		child.queue_free()
		
	# Empty the ui_components
	ui_components = {}




## Load the ui components from the level
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



	
	
	# Loop through the ui components, match dependencies and connect them where needed
	for ui_component: UiComponent in ui_components.values():

		# Loop through the dependencies
		for dependency_name: String in ui_component.dependencies.keys():
			
			# Look up the dependency in the map
			if ui_components.has(dependency_name):
				ui_component.connect_dependency(ui_components[dependency_name])
			else:
				push_warning("Dependency: ", dependency_name, " could not be found!")
		
		# Now that we've connected it's dependency we can add it to the themer
		global_themer.add_child(ui_component)
		
	emit_signal("FinishedLoading")
		
		

## Method for grabbing components
func get_component(comp_key: String):
	if ui_components.has(comp_key):
		return ui_components[comp_key]
	return null

# Method to get the custom class name, black magic found within the depth of stack overflow
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
