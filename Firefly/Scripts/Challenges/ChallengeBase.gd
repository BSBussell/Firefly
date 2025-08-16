extends Area2D
class_name ChallengeBase

# Core exported configuration
@export var challenge_id: String = "challenge_id"
@export var jars: JarManager
@export var reward_spawn: Marker2D
@export var camera_focus_duration: float = 3.0
@export var auto_disable_on_complete: bool = true
@export var skip_reward_if_completed: bool = true

# Signals (generic lifecycle + legacy compatibility)
signal cleared_challenge(challenge_id: String) # legacy
signal challenge_started(challenge_id: String)
signal challenge_succeeded(challenge_id: String)
signal challenge_failed(challenge_id: String, reason: String)
signal challenge_reset(challenge_id: String)

var cleared: bool = false
var _spawned_jar: FlyJar = null

func _ready() -> void:
	register_persistence()
	load_completion_status()
	if cleared and auto_disable_on_complete:
		_disable_triggers_post_load()

# --------------------------------------------------
# To be optionally overridden by subclasses
# --------------------------------------------------
func start_challenge() -> void:
	emit_signal("challenge_started", challenge_id)

func succeed_challenge() -> void:
	if cleared:
		return
	cleared = true
	_persist.save_values()
	emit_signal("challenge_succeeded", challenge_id)
	emit_signal("cleared_challenge", challenge_id)
	if auto_disable_on_complete:
		_disable_triggers_post_load()
	_spawn_reward_and_focus()

func fail_challenge(reason: String = "") -> void:
	emit_signal("challenge_failed", challenge_id, reason)

func reset_challenge() -> void:
	emit_signal("challenge_reset", challenge_id)

func _disable_triggers_post_load() -> void:
	# Subclasses can override to turn off their specific Area2D monitors
	pass

# --------------------------------------------------
# Reward + Camera Focus (shared)
# --------------------------------------------------
func _spawn_reward_and_focus() -> void:
	if skip_reward_if_completed and cleared and _spawned_jar:
		return
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
		_spawned_jar = new_jar
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

# --------------------------------------------------
# Persistence (shared)
# --------------------------------------------------
func register_persistence() -> void:
	var save_callable: Callable = Callable(self, "_save_data")
	var load_callable: Callable = Callable(self, "_load_data")
	_persist.register_persistent_class(challenge_id, save_callable, load_callable)

func _save_data() -> Dictionary:
	return {"completed": cleared, "challenge_id": challenge_id}

func _load_data(save_data: Dictionary) -> void:
	if save_data.has("completed"):
		cleared = save_data["completed"]

func load_completion_status() -> void:
	if cleared and auto_disable_on_complete:
		_disable_triggers_post_load()

func _exit_tree() -> void:
	_persist.unregister_persistent_class(challenge_id)
