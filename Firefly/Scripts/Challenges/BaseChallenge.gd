extends Area2D
class_name BaseChallenge

# A minimal unified challenge base: handles persistence, reward spawning, camera focus.
# Derived classes (e.g., BounceTest, SpeedGate) implement their own gating / success logic
# and call _on_challenge_succeeded() when complete or _on_challenge_failed(reason).

# --- Exports (common) ---
@export var challenge_id: String = "challenge_id"
@export var jars: JarManager
@export var reward_spawn: Marker2D
@export var camera_focus_duration: float = 3.0

# --- Signals ---
signal challenge_started(challenge_id: String)
signal challenge_succeeded(challenge_id: String)
signal challenge_failed(challenge_id: String, reason: String)
signal challenge_reset(challenge_id: String)
signal cleared_challenge(challenge_id: String) # legacy compatibility

# --- State ---
var cleared: bool = false
var _active: bool = false

func _ready() -> void:
	register_persistence()
	load_completion_status()
	if cleared:
		_on_already_cleared_post_load()

# --- Lifecycle hooks for derived classes ---
func start_challenge() -> void:
	if cleared:
		return
	if _active:
		return
	_active = true
	emit_signal("challenge_started", challenge_id)

func reset_challenge() -> void:
	if cleared:
		return
	_active = false
	emit_signal("challenge_reset", challenge_id)

# Derived class should call when success criteria met
func _on_challenge_succeeded() -> void:
	if cleared:
		return
	_active = false
	await _spawn_jar_and_focus()
	mark_as_completed()
	emit_signal("challenge_succeeded", challenge_id)
	emit_signal("cleared_challenge", challenge_id)

# Derived class can call to register a fail (and then may call start again later)
func _on_challenge_failed(reason: String = "") -> void:
	if cleared:
		return
	_active = false
	emit_signal("challenge_failed", challenge_id, reason)

# Override if needed to visually disable triggers, etc.
func _on_already_cleared_post_load() -> void:
	modulate = Color(0.6, 0.6, 0.6, 0.8)

# --- Reward + Camera Focus (shared) ---
func _spawn_jar_and_focus() -> void:
	if not jars:
		return
	var jar_pos: Vector2 = reward_spawn.global_position if reward_spawn else global_position
	jars.create_bluejar(jar_pos)
	await get_tree().process_frame
	if _config.get_setting("skip_jar_reveal") == true:
		return
	var blue_jars: Array[Node] = get_tree().get_nodes_in_group("BlueJar")
	var new_jar: FlyJar = null
	for j in blue_jars:
		var jar_node: FlyJar = j as FlyJar
		if jar_node and jar_node.global_position.distance_to(jar_pos) < 10.0:
			new_jar = jar_node
			break
	if new_jar:
		var large_target: Area2D = _create_large_camera_target()
		new_jar.add_child(large_target)
		await get_tree().create_timer(camera_focus_duration).timeout
		if is_instance_valid(large_target):
			large_target.queue_free()

func _create_large_camera_target() -> Area2D:
	var camera_target: Area2D = Area2D.new()
	camera_target.name = "LargeCameraTarget"
	var cs: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 800.0
	cs.shape = circle
	camera_target.add_child(cs)
	var camera_target_script: Script = load("res://Scenes/Camera/CameraTriggers/CameraTarget.gd")
	if camera_target_script:
		camera_target.set_script(camera_target_script)
		camera_target.blend_priority = 10
		camera_target.blend_override = 1.0
		camera_target.pull_strength = 2000.0
		camera_target.target_snap = true
		camera_target.collision_layer = 0
		camera_target.collision_mask = 0
		camera_target.enable_target()
	return camera_target

# --- Persistence ---
func register_persistence() -> void:
	var save_callable: Callable = Callable(self, "save_challenge_data")
	var load_callable: Callable = Callable(self, "load_challenge_data")
	_persist.register_persistent_class(challenge_id, save_callable, load_callable)

func save_challenge_data() -> Dictionary:
	return {"completed": cleared, "challenge_id": challenge_id}

func load_challenge_data(save_data: Dictionary) -> void:
	if save_data.has("completed"):
		cleared = save_data["completed"]

func load_completion_status() -> void:
	if cleared:
		_on_already_cleared_post_load()

func mark_as_completed() -> void:
	cleared = true
	_persist.save_values()

func _exit_tree() -> void:
	unregister_persistence()

func unregister_persistence() -> void:
	_persist.unregister_persistent_class(challenge_id)
