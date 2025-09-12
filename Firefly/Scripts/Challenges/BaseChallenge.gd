extends Node2D
class_name BaseChallenge

# ——— Core Challenge Signals ———
# Legacy compatibility signal (used by both existing challenges)
signal cleared_challenge(challenge_id: String)

# Comprehensive challenge lifecycle signals
signal challenge_started(challenge_id: String, context: Dictionary)
signal challenge_succeeded(challenge_id: String, context: Dictionary)
signal challenge_failed(challenge_id: String, reason: String, context: Dictionary)
signal challenge_reset(challenge_id: String)
signal challenge_progress_updated(challenge_id: String, progress_data: Dictionary)
signal challenge_status_loaded(challenge_id: String, state: int, cleared: bool)

# ——— Core Exports ———
@export_group("Challenge Identity")
@export var challenge_id: String = "base_challenge"
@export var challenge_name: String = ""
@export var challenge_description: String = ""

@export_group("Reward System")
@export var jars: JarManager
@export var reward_spawn: Marker2D
@export var reward_type: RewardType = RewardType.BLUE_JAR
@export var skip_jar_focus: bool = false

@export_group("Camera Focus")
@export var camera_focus_duration: float = 3.0
@export var camera_focus_radius: float = 800.0
@export var camera_blend_priority: int = 10
@export var camera_blend_override: float = 1.0
@export var camera_pull_strength: float = 2000.0

@export_group("Visual Settings")
@export var completion_modulate: Color = Color(0.6, 0.6, 0.6, 0.8)
@export var use_completion_visual: bool = true

# ——— Enums ———
enum ChallengeState { IDLE, ACTIVE, COMPLETED }
enum RewardType { BLUE_JAR, GOLD_JAR, GEM, CUSTOM }

# ——— Core State ———
var player: Flyph = null
var state: BaseChallenge.ChallengeState = BaseChallenge.ChallengeState.IDLE
var cleared: bool = false
var challenge_context: Dictionary = {}

# Track a spawned-but-uncollected reward so we can restore it across loads
var reward_pending: bool = false
var _spawned_reward: FlyJar = null

# Protected variables that subclasses can access
var _trigger_areas: Array[Area2D] = []
var _monitoring_enabled: bool = true

# ——— Virtual Methods (Override in subclasses) ———

# Called when challenge should start its logic
func _on_challenge_start() -> void:
	pass

# Called every physics frame when challenge is active
func _process_challenge_logic(_delta: float) -> void:
	pass

# Called when challenge should be reset to idle state
func _on_challenge_reset() -> void:
	pass

# Called when challenge succeeds - return context data for signals
func _on_challenge_succeed() -> Dictionary:
	return {}

# Called when challenge fails - return reason and context
func _on_challenge_fail(reason: String) -> Dictionary:
	return {"reason": reason}

# Called to check if player meets challenge requirements
func _validate_player_requirements() -> bool:
	return is_instance_valid(player)

# Called to disable specific triggers when completed
func _disable_challenge_specific_triggers() -> void:
	pass

# ——— Lifecycle ———

func _ready() -> void:
	set_physics_process(false)
	register_persistence()
	load_completion_status()
	_setup_challenge()
	# Emit initial status so listeners can sync on first load
	emit_signal("challenge_status_loaded", challenge_id, state, cleared)

func _physics_process(delta: float) -> void:
	if state != BaseChallenge.ChallengeState.ACTIVE:
		return
	
	if not _validate_player_requirements():
		fail_challenge("Player validation failed")
		return
	
	_process_challenge_logic(delta)

func _exit_tree() -> void:
	unregister_persistence()

# ——— Challenge Management API ———

func start_challenge(starting_player: Flyph = null, context: Dictionary = {}) -> bool:
	if state == BaseChallenge.ChallengeState.COMPLETED:
		return false
	
	if starting_player:
		player = starting_player
	elif not player:
		player = _globals.ACTIVE_PLAYER
	
	if not _validate_player_requirements():
		_logger.warn("BaseChallenge %s: Cannot start - player validation failed" % challenge_id)
		return false
	
	challenge_context = context.duplicate()
	state = BaseChallenge.ChallengeState.ACTIVE
	set_physics_process(true)
	
	_on_challenge_start()
	emit_challenge_started(context)
	
	_logger.info("BaseChallenge %s: Started" % challenge_id)
	return true

func succeed_challenge(success_context: Dictionary = {}) -> void:
	if state != BaseChallenge.ChallengeState.ACTIVE:
		return
	
	state = BaseChallenge.ChallengeState.COMPLETED
	set_physics_process(false)
	_disable_all_triggers()
	
	var full_context: Dictionary = challenge_context.duplicate()
	full_context.merge(_on_challenge_succeed())
	full_context.merge(success_context)
	
	# Mark reward pending and spawn it. Completion is finalized on pickup.
	reward_pending = true
	_persist.save_values()

	_spawned_reward = await _spawn_reward_and_focus(true)
	if _spawned_reward and not _spawned_reward.collected.is_connected(_on_reward_collected):
		_spawned_reward.connect("collected", Callable(self, "_on_reward_collected"))

	emit_challenge_succeeded(full_context)
	
	_logger.info("BaseChallenge %s: Succeeded with context: %s" % [challenge_id, str(full_context)])

func fail_challenge(reason: String, fail_context: Dictionary = {}) -> void:
	if state == BaseChallenge.ChallengeState.COMPLETED:
		return
	
	var full_context: Dictionary = challenge_context.duplicate()
	full_context.merge(_on_challenge_fail(reason))
	full_context.merge(fail_context)
	
	emit_challenge_failed(reason, full_context)
	
	_logger.info("BaseChallenge %s: Failed - %s" % [challenge_id, reason])
	reset_challenge()

func reset_challenge() -> void:
	if state == BaseChallenge.ChallengeState.COMPLETED:
		return
	
	var was_active: bool = (state == BaseChallenge.ChallengeState.ACTIVE)
	
	state = BaseChallenge.ChallengeState.IDLE
	set_physics_process(false)
	_restore_trigger_monitoring()
	
	challenge_context.clear()
	player = null
	
	_on_challenge_reset()
	
	if was_active:
		emit_signal("challenge_reset", challenge_id)
	
	_logger.info("BaseChallenge %s: Reset to idle" % challenge_id)

func update_challenge_progress(progress_data: Dictionary) -> void:
	emit_signal("challenge_progress_updated", challenge_id, progress_data)

# ——— Player Detection Helpers ———

func is_valid_player(body: Node) -> bool:
	return body == _globals.ACTIVE_PLAYER or body == player

func setup_area_monitoring(area: Area2D, enter_callback: Callable, exit_callback: Callable = Callable()) -> void:
	if not area:
		return
	
	_trigger_areas.append(area)
	
	if not area.body_entered.is_connected(enter_callback):
		area.body_entered.connect(enter_callback)
	
	if exit_callback.is_valid() and not area.body_exited.is_connected(exit_callback):
		area.body_exited.connect(exit_callback)
	
	area.monitoring = _monitoring_enabled

# ——— Trigger Management ———

func _disable_all_triggers() -> void:
	_monitoring_enabled = false
	
	for area in _trigger_areas:
		if is_instance_valid(area):
			area.set_deferred("monitoring", false)
	
	_disable_challenge_specific_triggers()
	
	if use_completion_visual:
		modulate = completion_modulate

func _restore_trigger_monitoring() -> void:
	_monitoring_enabled = true
	
	for area in _trigger_areas:
		if is_instance_valid(area):
			area.set_deferred("monitoring", true)
	
	if use_completion_visual:
		modulate = Color.WHITE

# ——— Reward System ———

# Spawns reward and optionally focuses camera. Returns the spawned jar if applicable.
func _spawn_reward_and_focus(focus: bool = true) -> FlyJar:
	if not jars:
		printerr("BaseChallenge %s: No JarManager assigned for reward" % challenge_id)
		return null
	
	var reward_pos: Vector2 = _get_reward_position()
	var spawned_jar: FlyJar = null
	
	match reward_type:
		RewardType.BLUE_JAR:
			spawned_jar = await jars.create_bluejar(reward_pos)
		RewardType.GOLD_JAR:
			# Replace gold jar with default/yellow flyjar
			spawned_jar = await jars.create_flyjar(reward_pos)
		RewardType.GEM:
			# Handle gem spawning if needed
			_logger.info("BaseChallenge %s: Gem reward not yet implemented" % challenge_id)
		RewardType.CUSTOM:
			_spawn_custom_reward(reward_pos)

	# If the jar creator returned null (legacy void), find jar near position
	if spawned_jar == null:
		var candidates: Array[Node] = []
		candidates.append_array(get_tree().get_nodes_in_group("BlueJar"))
		candidates.append_array(get_tree().get_nodes_in_group("FlyJar"))
		for node in candidates:
			var j: FlyJar = node as FlyJar
			if j and j.global_position.distance_to(reward_pos) < 10.0:
				spawned_jar = j
				break

	# Kick off camera focus asynchronously to avoid delaying signal connections
	if not (skip_jar_focus or _config.get_setting("skip_jar_reveal") == true) and focus:
		_async_focus_on_reward(reward_pos, spawned_jar)

	return spawned_jar

func _async_focus_on_reward(reward_pos: Vector2, jar: FlyJar) -> void:
	await get_tree().process_frame
	await _focus_camera_on_reward(reward_pos, jar)

func _get_reward_position() -> Vector2:
	if reward_spawn:
		return reward_spawn.global_position
	return global_position

func _spawn_custom_reward(_pos: Vector2) -> void:
	# Override in subclasses for custom reward types
	printerr("BaseChallenge %s: Custom reward spawn not implemented" % challenge_id)

func _focus_camera_on_reward(reward_pos: Vector2, target_jar: FlyJar = null) -> void:
	# If a jar reference is not provided, find a spawned jar near the reward position
	if not target_jar:
		var blue_jars: Array[Node] = get_tree().get_nodes_in_group("BlueJar")
		for jar_node in blue_jars:
			var jar: FlyJar = jar_node as FlyJar
			if jar and jar.global_position.distance_to(reward_pos) < 10.0:
				target_jar = jar
				break
	
	if target_jar:
		var camera_target: Area2D = _create_camera_target()
		target_jar.add_child(camera_target)
		
		await get_tree().create_timer(camera_focus_duration).timeout
		
		if is_instance_valid(camera_target):
			camera_target.queue_free()

func _create_camera_target() -> Area2D:
	var camera_target: Area2D = Area2D.new()
	camera_target.name = "ChallengeCameraTarget"
	
	var collision_shape: CollisionShape2D = CollisionShape2D.new()
	var circle_shape: CircleShape2D = CircleShape2D.new()
	circle_shape.radius = camera_focus_radius
	collision_shape.shape = circle_shape
	camera_target.add_child(collision_shape)
	
	# Apply camera target script if available
	var camera_target_script: Script = load("res://Scenes/Camera/CameraTriggers/CameraTarget.gd")
	if camera_target_script:
		camera_target.set_script(camera_target_script)
		camera_target.blend_priority = camera_blend_priority
		camera_target.blend_override = camera_blend_override
		camera_target.pull_strength = camera_pull_strength
		camera_target.OnDistant = INF
		camera_target.target_snap = true
		camera_target.collision_layer = 0
		camera_target.collision_mask = 0
		
		if camera_target.has_method("enable_target"):
			camera_target.enable_target()
	
	return camera_target

# ——— Persistence System ———

func register_persistence() -> void:
	var save_callable: Callable = Callable(self, "save_challenge_data")
	var load_callable: Callable = Callable(self, "load_challenge_data")
	_persist.register_persistent_class(challenge_id, save_callable, load_callable)

func save_challenge_data() -> Dictionary:
	var save_data: Dictionary = {
		"completed": cleared,
		"challenge_id": challenge_id,
		"state": state,
		"reward_pending": reward_pending
	}
	
	# Allow subclasses to add custom save data
	var custom_data: Dictionary = _get_custom_save_data()
	save_data.merge(custom_data)
	
	return save_data

func load_challenge_data(save_data: Dictionary) -> void:
	if save_data.has("completed"):
		cleared = save_data["completed"]

	if save_data.has("state"):
		var saved_state = save_data["state"]
		if saved_state == BaseChallenge.ChallengeState.COMPLETED:
			state = BaseChallenge.ChallengeState.COMPLETED

	if save_data.has("reward_pending"):
		reward_pending = save_data["reward_pending"]

	# Allow subclasses to load custom save data
	_load_custom_save_data(save_data)

	# Apply completion side-effects if loaded as completed
	if cleared or state == BaseChallenge.ChallengeState.COMPLETED:
		state = BaseChallenge.ChallengeState.COMPLETED
		_disable_all_triggers()
		_logger.info("BaseChallenge %s: Loaded completion state from save" % challenge_id)

		# If a reward is pending (challenge succeeded earlier but jar not collected), respawn it without focus
		if reward_pending and not cleared:
			# Avoid double-connecting if a previous jar reference exists
			if not is_instance_valid(_spawned_reward):
				_spawned_reward = await _spawn_reward_and_focus(false)
			if _spawned_reward and not _spawned_reward.collected.is_connected(_on_reward_collected):
				_spawned_reward.connect("collected", Callable(self, "_on_reward_collected"))

	# Notify listeners that status has been loaded/initialized
	emit_signal("challenge_status_loaded", challenge_id, state, cleared)

func load_completion_status() -> void:
	if cleared:
		state = BaseChallenge.ChallengeState.COMPLETED
		_disable_all_triggers()
		_logger.info("BaseChallenge %s: Loaded as completed" % challenge_id)

func mark_as_completed() -> void:
	cleared = true
	_persist.save_values()

func _on_reward_collected(_jar: FlyJar) -> void:
	# Finalize completion on reward pickup
	reward_pending = false
	mark_as_completed()
	emit_signal("cleared_challenge", challenge_id) # Legacy compatibility
	_logger.info("BaseChallenge %s: Reward collected, challenge fully cleared" % challenge_id)

func unregister_persistence() -> void:
	_persist.unregister_persistent_class(challenge_id)

# ——— Custom Save Data (Override in subclasses) ———

func _get_custom_save_data() -> Dictionary:
	return {}

func _load_custom_save_data(_save_data: Dictionary) -> void:
	pass

# ——— Signal Emission Helpers ———

func emit_challenge_started(context: Dictionary = {}) -> void:
	var full_context: Dictionary = challenge_context.duplicate()
	full_context.merge(context)
	emit_signal("challenge_started", challenge_id, full_context)

func emit_challenge_succeeded(context: Dictionary = {}) -> void:
	var full_context: Dictionary = challenge_context.duplicate()
	full_context.merge(context)
	emit_signal("challenge_succeeded", challenge_id, full_context)

func emit_challenge_failed(reason: String, context: Dictionary = {}) -> void:
	var full_context: Dictionary = challenge_context.duplicate()
	full_context.merge(context)
	emit_signal("challenge_failed", challenge_id, reason, full_context)

# ——— Setup and Utility ———

func _setup_challenge() -> void:
	# Override in subclasses for challenge-specific setup
	pass

func get_challenge_info() -> Dictionary:
	return {
		"id": challenge_id,
		"name": challenge_name if challenge_name != "" else challenge_id,
		"description": challenge_description,
		"state": state,
		"cleared": cleared,
		"reward_type": reward_type
	}
