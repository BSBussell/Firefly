extends Node
class_name UiComponent


# Dependent Components
var dependencies: Array[UiComponent]  = []

# The current running level
var context: Level = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Override function
	pass


# Called when the node exits the scene tree.
func _exit_tree() -> void:
	# Override function
	pass


# Defines the dependencies the component needs. Called before the component is added to the scene
func define_dependencies() -> void:
	# Override function
	pass
	
	
# Passes the current level to the component
func connect_level(level: Level) -> void:
	print("Context Assigned to ", self.name)
	context = level


# dep objects of value null are used to define the necesssary types for the component
func define_dependency(dep: UiComponent) -> void:
	
	# If the type is not in the list then add it
	dependencies.append(dep)


# Then once the depdency has been initialized, the add_dependency function can be used to add the actual dependency
func connect_dependency(dep: UiComponent) -> void:
	
	# Loop through dependencies, looking for a type match
	for d: UiComponent in dependencies:
		
		# Checks if the type is already in the list
		if d.name == dep.name:
			
			# If it is then override the existing dependency
			d = dep

# Returns an object of the specified dependency type
func get_dependency(dep_name: String) -> UiComponent:
	
	# Loop through dependencies, looking for a type match
	for d: UiComponent in dependencies:
		
		# Checks if the type is already in the list
		if d.name == dep_name:
			
			# If it is then return the dependency
			return d
			
	return null
