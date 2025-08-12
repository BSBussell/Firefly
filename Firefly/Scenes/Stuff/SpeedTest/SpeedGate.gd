extends Node2D
class_name SpeedGate

signal cleared_challenge(challenge_id: String)

@export var entry_area: Area2D
@export var exit_area: Area2D
@export var jars: JarManager
@export var challenge_id: String = "speed_gate_1"

# Camera / Jar
@export var camera_focus_duration: float = 3.0
@export var reward_spawn: Marker2D    # where the jar appears

# Tuning
@export var use_horizontal_only: bool = true
@export var grace_seconds: float = 0.20            # startup window AND dip tolerance
@export var air_speed_factor: float = 1.0          # multiplier on player.air_speed

# Guide/Firefly exports
@export var guide_path: Path2D                     # Drawn in the level scene
@export var firefly_visual: PackedScene            # Visual for the guide (Particles/Sprite scene)
@export var firefly_speed_scale: float = 1.0       # Multiplier on player speed
@export var firefly_min_speed: float = 120.0
@export var firefly_max_speed: float = 1200.0
@export var firefly_finish_time: float = 0.6       # Dash-to-end duration on success/fail
@export var firefly_fade_time: float = 0.4         # Fade out duration

enum State { IDLE, ARMED, RUNNING, COMPLETED }

var player: Flyph = null
var state: SpeedGate.State = SpeedGate.State.IDLE
var below_timer: float = 0.0
var speed_avg: float = 0.0

var cleared: bool = false

var _guide_follow: PathFollow2D = null
var _path_len: float = 0.0
var _firefly_tween: Tween = null

func _ready() -> void:
	if entry_area and not entry_area.body_entered.is_connected(_on_entry_entered):
		entry_area.body_entered.connect(_on_entry_entered)
	if exit_area and not exit_area.body_entered.is_connected(_on_exit_entered):
		exit_area.body_entered.connect(_on_exit_entered)

	set_physics_process(false)
	register_persistence()
	load_completion_status()
	if guide_path and guide_path.curve:
		_path_len = guide_path.curve.get_baked_length()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		_fail()
		return

	var s: float = _current_speed(player)
	# light smoothing so a single frame doesn't flip state
	speed_avg = lerp(speed_avg, s, 0.25)

	match state:
		SpeedGate.State.ARMED:
			# Startup window: must reach threshold within grace_seconds
			if _meets_threshold(player, speed_avg):
				_start_run()
				return
			below_timer += delta
			if below_timer >= grace_seconds:
				_fail()
			_update_firefly_speed(s, delta)

		SpeedGate.State.RUNNING:
			# Dip tolerance: can be under threshold up to grace_seconds
			if _meets_threshold(player, speed_avg):
				below_timer = 0.0
			else:
				below_timer += delta
				if below_timer >= grace_seconds:
					_fail()
			_update_firefly_speed(s, delta)

func _on_entry_entered(body: Node) -> void:
	if cleared or state == SpeedGate.State.COMPLETED:
		return
	var p: Flyph = body as Flyph
	if p == null:
		return

	player = p
	state = SpeedGate.State.ARMED
	below_timer = 0.0              # start startup window now
	speed_avg = _current_speed(player)
	set_physics_process(true)
	_init_firefly_guide()
	_reset_firefly_to_start(true)

	# If already fast enough, start immediately
	if _meets_threshold(player, speed_avg):
		_start_run()

func _on_exit_entered(body: Node) -> void:
	if state != SpeedGate.State.RUNNING or body != player:
		return
	_succeed()

# ——— State helpers ———

func _start_run() -> void:
	_init_firefly_guide()
	state = SpeedGate.State.RUNNING
	below_timer = 0.0
	if is_instance_valid(player):
		# prime slightly above bar so first-frame flicker doesn't insta-fail
		speed_avg = max(speed_avg, _air_bar(player) + 1.0)

func _succeed() -> void:
	state = SpeedGate.State.COMPLETED
	set_physics_process(false)
	_disable_triggers()
	_firefly_finish_and_fade(true)
	await _spawn_jar_and_focus()
	mark_as_completed()
	emit_signal("cleared_challenge", challenge_id)

func _fail() -> void:
	state = SpeedGate.State.IDLE
	set_physics_process(false)
	_firefly_finish_and_fade(false)
	player = null
	speed_avg = 0.0
	below_timer = 0.0
# ——— Reward + camera focus ———

func _init_firefly_guide() -> void:
	if _guide_follow != null or guide_path == null:
		return
	if _path_len <= 0.0 and guide_path.curve:
		_path_len = guide_path.curve.get_baked_length()
	_guide_follow = PathFollow2D.new()
	_guide_follow.rotates = false
	_guide_follow.loop = false
	_guide_follow.h_offset = 0.0
	_guide_follow.v_offset = 0.0
	# Start the guide near the entry position if possible
	var start_progress: float = 0.0
	if entry_area and guide_path and guide_path.curve:
		var local_entry: Vector2 = guide_path.to_local(entry_area.global_position)
		start_progress = clamp(guide_path.curve.get_closest_offset(local_entry), 0.0, _path_len)
	_guide_follow.progress = start_progress
	guide_path.add_child(_guide_follow)

	if firefly_visual:
		var vis: Node2D = firefly_visual.instantiate() as Node2D
		if vis:
			_guide_follow.add_child(vis)

func _reset_firefly_to_start(fade_in: bool) -> void:
	_kill_firefly_tween()
	if _path_len <= 0.0 and guide_path and guide_path.curve:
		_path_len = guide_path.curve.get_baked_length()
	if _guide_follow == null:
		_init_firefly_guide()
	if _guide_follow == null:
		return
	var start_progress: float = 0.0
	if entry_area and guide_path and guide_path.curve:
		var local_entry: Vector2 = guide_path.to_local(entry_area.global_position)
		start_progress = clamp(guide_path.curve.get_closest_offset(local_entry), 0.0, _path_len)
	_guide_follow.progress = start_progress
	var vis: CanvasItem = null
	if _guide_follow.get_child_count() > 0:
		vis = _guide_follow.get_child(0) as CanvasItem
	if fade_in and vis:
		var m: Color = vis.modulate
		m.a = 0.0
		vis.modulate = m
		_firefly_tween = create_tween()
		_firefly_tween.tween_property(vis, "modulate:a", 1.0, firefly_fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	elif vis:
		var m2: Color = vis.modulate
		m2.a = 1.0
		vis.modulate = m2

func _dispose_firefly() -> void:
	_kill_firefly_tween()
	if is_instance_valid(_guide_follow):
		_guide_follow.queue_free()
	_guide_follow = null

func _kill_firefly_tween() -> void:
	if _firefly_tween != null and is_instance_valid(_firefly_tween):
		_firefly_tween.kill()
	_firefly_tween = null

func _update_firefly_speed(current_speed: float, delta: float) -> void:
	if _guide_follow == null or _path_len <= 0.0:
		return
	var target_speed: float = clamp(current_speed * firefly_speed_scale, firefly_min_speed, firefly_max_speed)
	_guide_follow.progress = clamp(_guide_follow.progress + target_speed * delta, 0.0, _path_len)

func _firefly_finish_and_fade(on_success: bool) -> void:
	_kill_firefly_tween()
	_firefly_tween = create_tween()
	var tween: Tween = _firefly_tween
	if _path_len > 0.0:
		tween.tween_property(_guide_follow, "progress", _path_len, firefly_finish_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var vis: CanvasItem = null
	if _guide_follow.get_child_count() > 0:
		vis = _guide_follow.get_child(0) as CanvasItem
	if vis:
		tween.parallel().tween_property(vis, "modulate:a", 0.0, firefly_fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func() -> void:
		_dispose_firefly()
	)

func _disable_triggers() -> void:
	if entry_area:
		entry_area.monitoring = false
	if exit_area:
		exit_area.monitoring = false
	modulate = Color(0.6, 0.6, 0.6, 0.8)

# ——— Speed logic ———

func _current_speed(p: Flyph) -> float:
	return abs(p.velocity.x) if use_horizontal_only else p.velocity.length()

func _air_bar(p: Flyph) -> float:
	return max(1.0, p.air_speed * air_speed_factor)

func _meets_threshold(p: Flyph, s: float) -> bool:
	return s >= _air_bar(p)

# ——— Reward + camera focus ———

func _spawn_jar_and_focus() -> void:
	var jar_pos: Vector2 = reward_spawn.global_position if reward_spawn else global_position
	jars.create_bluejar(jar_pos)
	await get_tree().process_frame

	# If skipping jar reveal, do not create camera target / cinematic
	if _config.get_setting("skip_jar_reveal") == true:
		return

	# Find the created jar near the spawn point
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

# ——— Persistence ———

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
		state = SpeedGate.State.COMPLETED
		_disable_triggers()
		print("Speed gate already completed: ", challenge_id)

func mark_as_completed() -> void:
	cleared = true
	_persist.save_values()
	print("Speed gate completed and saved: ", challenge_id)

func _exit_tree() -> void:
	unregister_persistence()

func unregister_persistence() -> void:
	_persist.unregister_persistent_class(challenge_id)
