extends Area2D

@export var jars: JarManager
@export var challenge_id: String = "speed_test_1"  # Unique identifier for this challenge
@export var camera_focus_duration: float = 3.0     # How long to focus camera on jar

signal cleared_challenge

var player: Flyph
var high_Speed: bool = false
var cleared = false


# Called when the node enters the scene tree for the first time.
func _ready():
	set_process(false)
	register_persistence()
	load_completion_status()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	
	if abs(player.velocity.x) < player.air_speed:
		high_Speed = false
		set_process(false)


func _on_body_entered(body):
	
	# Don't allow re-completion if already cleared
	if cleared:
		return
		
	player = body as Flyph
	print(player.air_speed)
	print(player.velocity.x)
	if player and abs(player.velocity.x) > player.air_speed:
		
		high_Speed = true
		set_process(true)
	


func _on_body_exited(_body):
	if high_Speed and not cleared:
		print("HighSpeed success")
		emit_signal("cleared_challenge")
		# Create jar at center of the speed test area, not where player exited
		# This prevents immediate collection
		var jar_position = self.global_position
		call_deferred("_create_jar_with_camera_focus", jar_position)
	else:
		print("HighSpeed Fail")

## Create blue jar and temporarily focus camera on it
func _create_jar_with_camera_focus(jar_position: Vector2):
	# Create the jar first
	await jars.create_bluejar(jar_position)
	print("Blue jar created at: ", jar_position)
	
	# Find the newly created jar
	var blue_jars = get_tree().get_nodes_in_group("BlueJar")
	var new_jar: FlyJar = null
	
	# Find the jar at our position (the one we just created)
	for jar in blue_jars:
		if jar.global_position.distance_to(jar_position) < 10.0:  # Close enough
			new_jar = jar
			break
	
	if new_jar:
		print("Found new jar, creating camera target")
		# Create a large camera target to force camera focus
		var large_camera_target = create_large_camera_target()
		new_jar.add_child(large_camera_target)
		print("Large camera target added to jar")
		
		# Wait for camera to focus, then remove the large target
		await get_tree().create_timer(camera_focus_duration).timeout
		
		if is_instance_valid(large_camera_target):
			large_camera_target.queue_free()
			print("Large camera target removed")
	else:
		print("WARNING: Could not find newly created blue jar!")
	
	# Mark as completed after the camera sequence
	mark_as_completed()
	cleared = true

## Create a large camera target area for dramatic focus
func create_large_camera_target() -> Area2D:
	var camera_target = Area2D.new()
	camera_target.name = "LargeCameraTarget"
	
	# Create a large collision shape
	var collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 800.0  # Large radius to ensure camera focus
	collision_shape.shape = circle_shape
	camera_target.add_child(collision_shape)
	
	# Attach the CameraTarget script behavior
	var camera_target_script = load("res://Scenes/Camera/CameraTriggers/CameraTarget.gd")
	if camera_target_script:
		camera_target.set_script(camera_target_script)
		# Set high priority and strong pull to override other targets
		camera_target.blend_priority = 10      # High priority
		camera_target.blend_override = 1.0     # Strong blend toward jar
		camera_target.pull_strength = 2000.0   # Strong pull weight
		camera_target.target_snap = true      # Smooth movement
		
		# Ensure default is no presence
		camera_target.collision_layer = 0
		camera_target.collision_mask = 0 

		# Enable the camera target (sets collision layer)
		camera_target.enable_target()
		
	
	return camera_target


## Persistence Functions
func register_persistence() -> void:
	var save_callable: Callable = Callable(self, "save_challenge_data")
	var load_callable: Callable = Callable(self, "load_challenge_data")
	
	_persist.register_persistent_class(challenge_id, save_callable, load_callable)

func save_challenge_data() -> Dictionary:
	var save_data: Dictionary = {}
	save_data["completed"] = cleared
	save_data["challenge_id"] = challenge_id
	return save_data

func load_challenge_data(save_data: Dictionary) -> void:
	if save_data.has("completed"):
		cleared = save_data["completed"]

func load_completion_status() -> void:
	# If already completed, don't allow re-completion and hide the challenge area
	if cleared:
		print("Speed test already completed: ", challenge_id)
		# Optionally disable the area or change its behavior
		set_collision_mask_value(1, false)  # Disable player detection
		# You could also make the area visually different to indicate completion
		modulate = Color(0.5, 0.5, 0.5, 0.7)  # Make it grayed out

func mark_as_completed() -> void:
	cleared = true
	_persist.save_values()
	print("Speed test completed and saved: ", challenge_id)

func _exit_tree():
	# Unregister persistence functions when the node is destroyed
	unregister_persistence()

func unregister_persistence() -> void:
	# Remove this object's save/load functions from the persistence system
	_persist.unregister_persistent_class(challenge_id)


func _on_end_point_body_exited(body):
	pass # Replace with function body.
