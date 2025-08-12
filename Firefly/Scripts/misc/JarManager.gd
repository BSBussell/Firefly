extends Node2D
class_name JarManager

signal AllJarsCollected()
signal YellowJarsCollected()
signal BlueJarsCollected()

@export var gem_manager: GemManager

@export var FLYJAR: PackedScene
@export var BLUEJAR: PackedScene

var yellow_collected: int
var yellow_max: int

var blue_collected: int
var blue_max: int

# Called when the node enters the scene tree for the first time.
func _ready():
	
	yellow_collected = 0
	blue_collected = 0

	# Get all jars in the scene in the group "FlyJar"
	var yellow_jars = get_tree().get_nodes_in_group("FlyJar")
	var blue_jars = get_tree().get_nodes_in_group("BlueJar")

	yellow_max = yellow_jars.size()
	blue_max = blue_jars.size()

	for jar: FlyJar in yellow_jars:
		jar.connect("collected", Callable(self, "yellow_jar_collected"))
		_jar_tracker.register_jar_exists(jar)
	
	for jar: FlyJar in blue_jars:
		jar.connect("collected", Callable(self, "blue_jar_collected"))
		_jar_tracker.register_jar_exists(jar)
		
		
	
func create_flyjar(jar_position: Vector2) -> void:
	var flyjar = FLYJAR.instantiate()
	flyjar.global_position = jar_position
	add_child(flyjar)
	
	
	# Add to proper group and connect signals
	flyjar.add_to_group("FlyJar")
	flyjar.connect("collected", Callable(self, "yellow_jar_collected"))
	
	# Update counts
	yellow_max += 1
	
	# Register with jar tracker after full setup
	_jar_tracker.register_jar_exists(flyjar)

func create_bluejar(jar_position: Vector2) -> void:
	var bluejar = BLUEJAR.instantiate()
	bluejar.global_position = jar_position
	add_child(bluejar)
	
	
	# Add to proper group and connect signals  
	bluejar.add_to_group("BlueJar")
	bluejar.connect("collected", Callable(self, "blue_jar_collected"))
	
	# Update counts
	blue_max += 1
	
	# Register with jar tracker after full setup
	_jar_tracker.register_jar_exists(bluejar)


## Emits a signal when all jars are collected
func yellow_jar_collected(jar: FlyJar):
	
	yellow_collected += 1
	
	if gem_manager: 
		var new_gem: Gem =  await  gem_manager.spawn_gem(jar.global_position)
		
		# Setup the gem to spawn in 15s
		new_gem.deactivate()
		await get_tree().create_timer(15).timeout
		new_gem.activate()
	
	if yellow_collected >= yellow_max:
		emit_signal("YellowJarsCollected")

## Emits a signal when blue jars are collected
func blue_jar_collected(jar: FlyJar):
	
	blue_collected += 1
	
	if gem_manager: 
		var new_gem: Gem = await gem_manager.spawn_blue_gem(jar.global_position)
		
		# Setup the gem to spawn in 15s
		new_gem.deactivate()
		await get_tree().create_timer(15).timeout
		new_gem.activate()
	
	if blue_collected >= blue_max:
		emit_signal("BlueJarsCollected")
		
## Setups a function that listens for if all jars are collected
func connect_jar_listener(function: Callable):
	var error = connect("YellowJarsCollected", function)
	if error != OK:
		print("Error connecting signal: ", error)


