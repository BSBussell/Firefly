extends Node
class_name UiComponent

# Dependent Components
var dependencies: Dictionary = {}

# The current running level
var context: Level = null


# Defines the dependencies the component needs. Called before the component is added to the scene
func define_dependencies() -> void:
	# Override function
	pass
	
	
# dep objects of value null are used to define the necesssary types for the component
func define_dependency(name_of_class: String, dep: UiComponent) -> void:
	
	
	
	# Put null dependencies in the thing, most importantly, initialize the entry
	dependencies[name_of_class] = dep


# Then once the depdency has been initialized, the add_dependency function can be used to add the actual dependency
func connect_dependency(dep: UiComponent) -> void:
	
	var className: String = get_script_class_name(dep)
	
	# Fill the dependency slot with the actual val
	dependencies[className] = dep

# Returns an object of the specified dependency type
func get_dependency(name_of_class: String, warn_on_missing: bool = true) -> UiComponent:
	
	if dependencies.has(name_of_class):
		return dependencies[name_of_class]
	
	if warn_on_missing:
		push_warning("Dependency: ", name_of_class, " could not be found by: ", self.name)	
	
	return null


# Passes the current level to the component
func connect_level(level: Level) -> void:
	print("Context Assigned to ", self.name)
	context = level
	
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
