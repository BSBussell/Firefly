extends Area2D
class_name BounceTest

@export var gate_1: Area2D
@export var gate_2: Area2D
@export var jars: JarManager
@export var challenge_id: String = "bounce_test_1"
@export var camera_focus_duration: float = 3.0
@export var reward_spawn: Marker2D
@export var ground_touch_grace: float = 0.02
@export var require_min_air_time: float = 0.0
@export var bidirectional: bool = true

# Primary signals
signal cleared_challenge(challenge_id: String)                # legacy success signal
signal challenge_started(challenge_id: String, start_gate: String)
signal challenge_succeeded(challenge_id: String, start_gate: String, finish_gate: String, air_time: float)
signal challenge_failed(challenge_id: String, reason: String)
signal challenge_reset(challenge_id: String)

var player: Flyph
var cleared: bool = false

enum State { IDLE, WAIT_AIR, AIRBORNE, COMPLETED }
var state: BounceTest.State = BounceTest.State.IDLE

var _armed_player_id: int = -1
var _airborne_time: float = 0.0
var _ground_touch_accum: float = 0.0
var _start_gate: Area2D = null
var _finish_gate: Area2D = null

# --------------------------------------------------
# Lifecycle
# --------------------------------------------------
func _ready():
	if gate_1 and not gate_1.body_entered.is_connected(_on_gate_1_entered):
		gate_1.body_entered.connect(_on_gate_1_entered)
	if gate_2 and not gate_2.body_entered.is_connected(_on_gate_2_entered):
		gate_2.body_entered.connect(_on_gate_2_entered)
	if not bidirectional and gate_2:
		gate_2.monitoring = false
	register_persistence()
	load_completion_status()
	set_physics_process(false)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		_fail("lost player reference")
		return
	match state:
		BounceTest.State.WAIT_AIR:
			if not player.is_on_floor():
				_transition_to_airborne()
		BounceTest.State.AIRBORNE:
			if player.is_on_floor():
				_ground_touch_accum += delta
				if _ground_touch_accum > ground_touch_grace:
					_fail("touched ground beyond grace (%.3f > %.3f)" % [_ground_touch_accum, ground_touch_grace])
			else:
				_ground_touch_accum = 0.0
				_airborne_time += delta

# --------------------------------------------------
# Gate + Player Detection
# --------------------------------------------------
func _on_body_entered(body: Node):
	if body == _globals.ACTIVE_PLAYER:
		player = body as Flyph
		_armed_player_id = player.get_instance_id()
		_logger.info("BounceTest %s: ACTIVE_PLAYER registered" % challenge_id)

func _on_gate_1_entered(body: Node) -> void:
	_gate_entered(body, gate_1)

func _on_gate_2_entered(body: Node) -> void:
	_gate_entered(body, gate_2)

func _gate_entered(body: Node, gate: Area2D) -> void:
	if cleared or state == BounceTest.State.COMPLETED:
		return
	if body != _globals.ACTIVE_PLAYER:
		return
	player = _globals.ACTIVE_PLAYER
	if state == BounceTest.State.IDLE:
		_arm_run(gate)
		return
	if gate == _finish_gate:
		_evaluate_finish(gate)

# --------------------------------------------------
# Arming + Transitions
# --------------------------------------------------
func _arm_run(start_gate: Area2D) -> void:
	if not bidirectional and start_gate != gate_1:
		return
	_start_gate = start_gate
	_finish_gate = (gate_2 if start_gate == gate_1 else gate_1)
	_armed_player_id = player.get_instance_id()
	state = BounceTest.State.WAIT_AIR if player.is_on_floor() else BounceTest.State.AIRBORNE
	_airborne_time = 0.0
	_ground_touch_accum = 0.0
	if _finish_gate and not _finish_gate.monitoring:
		_finish_gate.monitoring = true
	set_physics_process(true)
	_emit_started()
	_logger.info("BounceTest %s: Armed start=%s finish=%s state=%s on_floor=%s" % [challenge_id, _gate_name(_start_gate), _gate_name(_finish_gate), str(state), str(player.is_on_floor())])

func _transition_to_airborne() -> void:
	state = BounceTest.State.AIRBORNE
	_airborne_time = 0.0
	_ground_touch_accum = 0.0
	_logger.info("BounceTest %s: Transition -> AIRBORNE" % challenge_id)

# --------------------------------------------------
# Finish Evaluation
# --------------------------------------------------
func _evaluate_finish(_gate: Area2D) -> void:
	if player.get_instance_id() != _armed_player_id:
		_fail("finish gate player mismatch")
		return
	if state != BounceTest.State.AIRBORNE:
		_fail("finish reached without airborne state")
		return
	if require_min_air_time > 0.0 and _airborne_time < require_min_air_time:
		_fail("air_time %.3f < required %.3f" % [_airborne_time, require_min_air_time])
		return
	_succeed()

# --------------------------------------------------
# State Helpers
# --------------------------------------------------
func _succeed() -> void:
	state = BounceTest.State.COMPLETED
	set_physics_process(false)
	_disable_triggers()
	await _spawn_jar_and_focus()
	mark_as_completed()
	_emit_success()
	emit_signal("cleared_challenge", challenge_id) # backward compatibility
	_logger.info("BounceTest %s: SUCCESS air_time=%.3f" % [challenge_id, _airborne_time])

func _fail(reason: String = "") -> void:
	if state == BounceTest.State.COMPLETED:
		return
	_emit_failed(reason)
	_logger.info("BounceTest %s: FAIL %s" % [challenge_id, reason])
	_reset()

func _reset() -> void:
	if state == BounceTest.State.COMPLETED:
		return
	state = BounceTest.State.IDLE
	set_physics_process(false)
	_armed_player_id = -1
	_airborne_time = 0.0
	_ground_touch_accum = 0.0
	_start_gate = null
	_finish_gate = null
	if bidirectional:
		if gate_1: gate_1.monitoring = true
		if gate_2: gate_2.monitoring = true
	else:
		if gate_1: gate_1.monitoring = true
		if gate_2: gate_2.monitoring = false
	_emit_reset()

func _disable_triggers() -> void:
	if gate_1: gate_1.monitoring = false
	if gate_2: gate_2.monitoring = false
	monitoring = false
	modulate = Color(0.6, 0.6, 0.6, 0.8)

# --------------------------------------------------
# Reward + Camera Focus
# --------------------------------------------------
func _spawn_jar_and_focus() -> void:
	if not jars:
		return
	var jar_pos: Vector2 = reward_spawn.global_position if reward_spawn else (_finish_gate.global_position if _finish_gate else global_position)
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

# --------------------------------------------------
# Persistence
# --------------------------------------------------
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
		state = BounceTest.State.COMPLETED
		_disable_triggers()
		_logger.info("BounceTest %s: already completed on load" % challenge_id)

func mark_as_completed() -> void:
	cleared = true
	_persist.save_values()

func _exit_tree() -> void:
	unregister_persistence()

func unregister_persistence() -> void:
	_persist.unregister_persistent_class(challenge_id)

# --------------------------------------------------
# Signal Emit Helpers
# --------------------------------------------------
func _emit_started() -> void:
	emit_signal("challenge_started", challenge_id, _gate_name(_start_gate))

func _emit_success() -> void:
	emit_signal("challenge_succeeded", challenge_id, _gate_name(_start_gate), _gate_name(_finish_gate), _airborne_time)

func _emit_failed(reason: String) -> void:
	emit_signal("challenge_failed", challenge_id, reason)

func _emit_reset() -> void:
	emit_signal("challenge_reset", challenge_id)

# --------------------------------------------------
# Utility
# --------------------------------------------------
func _gate_name(g: Area2D) -> String:
	if g == null:
		return "None"
	if g == gate_1:
		return "Gate1"
	if g == gate_2:
		return "Gate2"
	return g.name

