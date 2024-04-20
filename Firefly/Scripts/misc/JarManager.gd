extends Node2D
class_name JarManager

signal AllJarsCollected()

var collected: int
var max: int

# Called when the node enters the scene tree for the first time.
func _ready():
	
	collected = 0
	max = get_child_count()
	
	for child in get_children():
		var jar: FlyJar = child as FlyJar
		if jar:
			jar.connect("collected", Callable(self, "jar_collected"))



## Emits a signal when all jars are collected
func jar_collected(jar: FlyJar):
	
	print("We can find this here")
	
	collected += 1
	
	if collected >= max:
		emit_signal("AllJarsCollected")
		
## Setups a function that listens for if all jars are collected
func connect_jar_listener(function: Callable):
	var error = connect("AllJarsCollected", function)
	if error != OK:
		print("Error connecting signal: ", error)


