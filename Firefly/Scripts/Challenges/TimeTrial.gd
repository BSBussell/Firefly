extends BaseChallenge
class_name TimeTrial

# ——— TimeTrial-Specific Exports ———
@export_group("Trial Areas")
@export var entry_area: Area2D
@export var exit_area: Area2D

@export_group("Stage Thresholds")
@export var easy_duration: float = 12.0   # Time allowed to earn the easy reward
@export var hard_duration: float = 8.0    # Time allowed to earn the hard reward
@export var grace_period: float = 0.5     # Extra time after timer expires before failure

@export_group("Stage Rewards")
@export var easy_reward_type: BaseChallenge.RewardType = BaseChallenge.RewardType.BLUE_JAR
@export var hard_reward_type: BaseChallenge.RewardType = BaseChallenge.RewardType.GOLD_JAR
@export var easy_reward_spawn: Marker2D
@export var hard_reward_spawn: Marker2D

@export_group("Safety")
# If enabled, only arm the trial when the player is moving toward the exit gate
@export var gate_direction_enabled: bool = false
@export var min_forward_speed: float = 0.0  # Optional: require at least this x-speed toward exit

@export_group("Guide/Pace System")
@export var guide_path: Path2D                    # Path the guide follows
@export var guide_visual: PackedScene             # Visual for the guide (firefly/particle scene)
@export var guide_fade_time: float = 0.4          # Fade in/out duration
@export var guide_finish_time: float = 0.6        # Rush to end duration on success/fail
@export var use_smooth_movement: bool = false       # Use bezier curve smoothing for guide movement
@export var smooth_curve_strength: float = 0.3     # How pronounced the smoothing curve is (0.1-1.0)
@export var restart_cooldown: float = 0.5          # Prevents instant restart spam

# ——— TimeTrial State ———
enum TrialState { WAITING, RUNNING, TIME_UP }
var trial_state: TimeTrial.TrialState = TimeTrial.TrialState.WAITING
var time_remaining: float = 0.0
var grace_timer: float = 0.0
var trial_duration: float = 0.0  # Internal: current stage duration

# Two-stage flow
enum Stage { EASY, HARD }
var current_stage: TimeTrial.Stage = TimeTrial.Stage.EASY
var easy_cleared: bool = false
var hard_cleared: bool = false
var easy_reward_pending: bool = false

# Guide system
var _guide_follow: PathFollow2D = null
var _path_length: float = 0.0
var _guide_tween: Tween = null
var _cooldown_until: float = 0.0
var _easy_spawned_reward: FlyJar = null

func _now() -> float:
	# Seconds since engine start; used for cooldown comparisons
	return float(Time.get_ticks_msec()) / 1000.0

# ——— BaseChallenge Overrides ———

func _setup_challenge() -> void:
	# Set up area monitoring using BaseChallenge helper
	if entry_area:
		setup_area_monitoring(entry_area, _on_entry_entered)
	if exit_area:
		setup_area_monitoring(exit_area, _on_exit_entered)
	
	# Initialize guide path
	if guide_path and guide_path.curve:
		_path_length = guide_path.curve.get_baked_length()

	# Ensure durations are sane
	if hard_duration >= easy_duration:
		# Keep hard strictly harder by capping to slightly below easy if misconfigured
		hard_duration = max(0.1, easy_duration - 0.1)

	# Default tablet state: Off unless hard already cleared (permanent on)
	_set_tablets_powered(hard_cleared)

	printerr("TimeTrial %s: Setup complete, easy=%.1fs hard=%.1fs" % [challenge_id, easy_duration, hard_duration])
	
	# Debug the guide system setup
	#debug_guide_state()

func _on_challenge_start() -> void:
	# Decide which stage to run
	if not easy_cleared:
		current_stage = TimeTrial.Stage.EASY
		trial_duration = easy_duration
	else:
		current_stage = TimeTrial.Stage.HARD
		trial_duration = hard_duration

	trial_state = TimeTrial.TrialState.RUNNING
	time_remaining = trial_duration
	grace_timer = 0.0
	# Power tablets on while the challenge is active
	_set_tablets_powered(true)
	
	_init_guide()  # Wait for guide initialization
	_start_guide_movement()
	
	# Debug guide state after start
	#debug_guide_state()
	
	var context: Dictionary = {
		"stage": ("easy" if current_stage == TimeTrial.Stage.EASY else "hard"),
		"trial_duration": trial_duration,
		"entry_position": entry_area.global_position if entry_area else Vector2.ZERO
	}
	update_challenge_progress(context)

func _process_challenge_logic(delta: float) -> void:
	match trial_state:
		TimeTrial.TrialState.RUNNING:
			time_remaining -= delta
			
			# Update guide progress based on remaining time
			_update_guide_progress()
			
			# Send progress updates
			var progress_data: Dictionary = {
				"time_remaining": time_remaining,
				"progress_percent": (trial_duration - time_remaining) / trial_duration * 100.0
			}
			update_challenge_progress(progress_data)
			
			# Check if time is up
			if time_remaining <= 0.0:
				trial_state = TimeTrial.TrialState.TIME_UP
				time_remaining = 0.0
		
		TimeTrial.TrialState.TIME_UP:
			grace_timer += delta
			if grace_timer >= grace_period:
				var stg = ("easy" if current_stage == TimeTrial.Stage.EASY else "hard")
				fail_challenge("Time expired (%s)" % stg)

func _on_challenge_succeed() -> Dictionary:
	var completion_time: float = trial_duration - time_remaining
	var time_bonus: float = max(0.0, time_remaining)
	var stage_str = ("easy" if current_stage == TimeTrial.Stage.EASY else "hard")

	_cooldown_until = _now() + restart_cooldown

	# Tablet power rules:
	# - Easy success: turn off (run ended)
	# - Hard success: leave on permanently to indicate cleared state
	if current_stage == TimeTrial.Stage.EASY:
		_set_tablets_powered(false)
	else:
		_set_tablets_powered(true)

	return {
		"stage": stage_str,
		"completion_time": completion_time,
		"time_bonus": time_bonus,
		"trial_duration": trial_duration,
		"entry_gate": "entry",
		"exit_gate": "exit"
	}

func _on_challenge_fail(reason: String) -> Dictionary:
	# Turn tablets off on failure
	_set_tablets_powered(false)
	_cooldown_until = _now() + restart_cooldown
	
	return {
		"reason": reason,
		"time_elapsed": trial_duration - time_remaining,
		"trial_duration": trial_duration
	}

func _on_challenge_reset() -> void:
	trial_state = TimeTrial.TrialState.WAITING
	time_remaining = 0.0
	grace_timer = 0.0
	_dispose_guide()

func _disable_challenge_specific_triggers() -> void:
	if entry_area:
		entry_area.set_deferred("monitoring", false)
	if exit_area:
		exit_area.set_deferred("monitoring", false)

# ——— Area Event Handlers ———

func _on_entry_entered(body: Node) -> void:
	if not is_valid_player(body):
		return
	
	if state == BaseChallenge.ChallengeState.COMPLETED:
		return
	# Cooldown guard
	if _now() < _cooldown_until:
		return

	# Optional safety: only start when moving toward exit
	if gate_direction_enabled and not _is_player_moving_toward_exit(body as Flyph):
		return

	# If already running, fade out and restart guide from the beginning
	if state == BaseChallenge.ChallengeState.ACTIVE and trial_state == TimeTrial.TrialState.RUNNING:
		#_restart_mid_run_with_fade()
		#_cooldown_until = _now() + restart_cooldown
		return

	# Start the challenge fresh
	if not start_challenge(body as Flyph):
		printerr("TimeTrial %s: Failed to start challenge" % challenge_id)

func _is_player_moving_toward_exit(player_ref: Flyph) -> bool:
	if not player_ref:
		return true
	if not exit_area or not entry_area:
		return true
	# Determine horizontal direction from entry to exit
	var delta: Vector2 = exit_area.global_position - entry_area.global_position
	# If gates are vertically aligned, fall back to always allow
	if abs(delta.x) < 0.001:
		return true
	var dir_sign: float = sign(delta.x) # +1 if exit is to the right, -1 if to the left
	var vx: float = player_ref.velocity.x
	# Moving toward exit if velocity.x sign matches dir_sign and exceeds minimum forward speed
	return (vx * dir_sign) > max(0.0, min_forward_speed)

func _on_exit_entered(body: Node) -> void:
	if not is_valid_player(body):
		return
	
	if state != BaseChallenge.ChallengeState.ACTIVE:
		return
	
	if trial_state != TimeTrial.TrialState.RUNNING:
		return
	
	# Player reached the exit in time!
	if current_stage == TimeTrial.Stage.EASY:
		# Grant easy reward and keep challenge available for hard stage
		easy_cleared = true
		easy_reward_pending = true
		_easy_spawned_reward = await _spawn_stage_reward(TimeTrial.Stage.EASY, true)
		if _easy_spawned_reward and not _easy_spawned_reward.collected.is_connected(_on_easy_reward_collected):
			_easy_spawned_reward.connect("collected", Callable(self, "_on_easy_reward_collected"))
		_persist.save_values()
		_guide_finish_and_fade(true)
		_cooldown_until = _now() + restart_cooldown
		# Turn tablets off at the end of an easy success run
		_set_tablets_powered(false)
		# Reset back to idle to let player re-arm for hard attempt
		reset_challenge()
	else:
		# Hard stage completion finishes the challenge and grants hard reward via BaseChallenge
		var prev_reward_type = reward_type
		var prev_reward_spawn = reward_spawn
		reward_type = hard_reward_type
		reward_spawn = (hard_reward_spawn if hard_reward_spawn else reward_spawn)
		hard_cleared = true
		_persist.save_values()
		# Fade out and dispose of the guide visual now that both stages are complete
		_guide_finish_and_fade(true)
		succeed_challenge({"stage": "hard"})
		# Restore configured reward defaults for safety
		reward_type = prev_reward_type
		reward_spawn = prev_reward_spawn

# ——— Guide System ———

func _init_guide() -> void:
	if _guide_follow != null or guide_path == null:
		return
	
	if _path_length <= 0.0 and guide_path.curve:
		_path_length = guide_path.curve.get_baked_length()
	
	_guide_follow = PathFollow2D.new()
	_guide_follow.rotates = false
	_guide_follow.loop = false
	_guide_follow.h_offset = 0.0
	_guide_follow.v_offset = 0.0
	_guide_follow.progress = 0.0
	
	guide_path.add_child(_guide_follow)
	
	if guide_visual:
		var visual_instance: Node2D = guide_visual.instantiate() as Node2D
		if visual_instance:
			# If the visual supports pre-fade preparation, set it BEFORE adding to the scene
			if visual_instance.has_method("prepare_for_fade_in"):
				visual_instance.prepare_for_fade_in(0.0, 0.0)
			# Proactively set trails alpha to 0.0 before first draw if available
			if visual_instance.has_method("set_trails_alpha"):
				visual_instance.set_trails_alpha(0.0)
			# Also set initial alpha directly for non-SpeedFly visuals
			var canvas_item: CanvasItem = visual_instance as CanvasItem
			if canvas_item:
				canvas_item.modulate.a = 0.0
			_guide_follow.add_child(visual_instance)

func _start_guide_movement(start_fade_in: bool = true) -> void:
	if _guide_follow == null or _path_length <= 0.0:
		return
	
	# Kill any existing tweens to prevent conflicts
	_kill_guide_tween()
	_guide_tween = create_tween()
	
	# Movement tween
	if use_smooth_movement:
		_guide_tween.tween_property(_guide_follow, "progress", _path_length, trial_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		_guide_tween.tween_property(_guide_follow, "progress", _path_length, trial_duration).set_trans(Tween.TRANS_LINEAR)
	
	# Optional fade in at the start (in parallel with movement)
	var visual_node: CanvasItem = _get_visual()
	if start_fade_in and visual_node:
		_guide_tween.parallel().tween_property(visual_node, "modulate:a", 1.0, guide_fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		# If the visual supports trail fading, fade trails in too
		var v: Node = visual_node as Node
		if v and v.has_method("fade_trails_to"):
			v.fade_trails_to(1.0, guide_fade_time)
	
	# Fade out the visual over the last segment of the guide time
	if visual_node and guide_fade_time > 0.0:
		var out_tween = _guide_tween.parallel().tween_property(visual_node, "modulate:a", 0.0, guide_fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		out_tween.set_delay(max(0.0, trial_duration - guide_fade_time))
		# Also schedule trail fade out if supported
		var v2: Node = visual_node as Node
		if v2 and v2.has_method("fade_trails_to"):
			_guide_tween.parallel().tween_callback(func(): v2.fade_trails_to(0.0, guide_fade_time)).set_delay(max(0.0, trial_duration - guide_fade_time))

func _update_guide_progress() -> void:
	if _guide_follow == null or _path_length <= 0.0:
		return
	
	if use_smooth_movement:
		# For smooth movement, let the tween handle the progress naturally
		# Only correct for major drifts (larger threshold)
		var expected_progress: float = ((trial_duration - time_remaining) / trial_duration) * _path_length
		var current_progress: float = _guide_follow.progress
		
		# Apply smooth curve interpolation for expected progress
		var time_ratio: float = (trial_duration - time_remaining) / trial_duration
		var smooth_ratio: float = _apply_smooth_curve(time_ratio)
		expected_progress = smooth_ratio * _path_length
		
		# Only adjust if there's a significant drift (higher threshold for smooth movement)
		if abs(expected_progress - current_progress) > 15.0:
			_guide_follow.progress = lerp(current_progress, expected_progress, 0.1)
	else:
		# Linear movement - ensure exact sync
		var expected_progress: float = ((trial_duration - time_remaining) / trial_duration) * _path_length
		var current_progress: float = _guide_follow.progress
		
		# Only adjust if there's a significant drift
		if abs(expected_progress - current_progress) > 5.0:
			_guide_follow.progress = expected_progress

func _guide_finish_and_fade(_success: bool) -> void:
	_kill_guide_tween()
	if _guide_follow == null:
		return
	_guide_tween = create_tween()
	if _path_length > 0.0:
		_guide_tween.tween_property(_guide_follow, "progress", _path_length, guide_finish_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var visual_node: CanvasItem = _get_visual()
	if visual_node:
		_guide_tween.parallel().tween_property(visual_node, "modulate:a", 0.0, guide_fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		# Also fade trails if supported
		var v3: Node = visual_node as Node
		if v3 and v3.has_method("fade_trails_to"):
			v3.fade_trails_to(0.0, guide_fade_time)
	_guide_tween.finished.connect(func() -> void:
		_dispose_guide()
	)

func _restart_mid_run_with_fade() -> void:
	# Reset timers
	trial_state = TimeTrial.TrialState.RUNNING
	time_remaining = trial_duration
	grace_timer = 0.0
	
	# Ensure guide exists
	_init_guide()
	if _guide_follow == null:
		return
	
	# Check if we have visual elements
	if not _guide_follow or _guide_follow.get_child_count() == 0:
		printerr("TimeTrial %s: No visual elements for mid-run restart, starting movement directly" % challenge_id)
		_guide_follow.progress = 0.0
		_start_guide_movement()
		return

	# Get the visual node to animate
	var visual_node: CanvasItem = _get_visual()
	if visual_node == null:
		# No visual to fade; just restart movement
		_guide_follow.progress = 0.0
		_start_guide_movement()
		return

	# Fade out, teleport to start, fade in, then restart movement
	_kill_guide_tween()
	var fade_out_tween: Tween = create_tween()
	fade_out_tween.tween_property(visual_node, "modulate:a", 0.0, guide_fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	fade_out_tween.finished.connect(func() -> void:
		# Reset position and clear trails
		_guide_follow.progress = 0.0
		_clear_visual_trails()
		
		# Fade back in and restart movement
		var fade_in_tween: Tween = create_tween()
		fade_in_tween.tween_property(visual_node, "modulate:a", 1.0, guide_fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_start_guide_movement(false)  # Don't fade in again since we just did
	)

## Removed group/trail fading helpers to restore original behavior

func _get_visual() -> CanvasItem:
	if _guide_follow and _guide_follow.get_child_count() > 0:
		return _guide_follow.get_child(0) as CanvasItem
	return null

func _clear_visual_trails() -> void:
	# Clear any Line2D trails under the visual to avoid long jump segments after teleport
	if _guide_follow == null or _guide_follow.get_child_count() == 0:
		return
	var root: Node = _guide_follow.get_child(0)
	var stack: Array = [root]
	while stack.size() > 0:
		var n: Node = stack.pop_back()
		if n is Line2D:
			var l: Line2D = n as Line2D
			l.clear_points()
		for c in n.get_children():
			stack.push_back(c)

func _dispose_guide() -> void:
	_kill_guide_tween()
	if is_instance_valid(_guide_follow):
		_guide_follow.queue_free()
	_guide_follow = null

# ——— Tablets ———
func _set_tablets_powered(on: bool) -> void:
	for child in get_children():
		if child and child.has_method("On") and child.has_method("Off"):
			if on:
				child.On()
			else:
				child.Off()

func _kill_guide_tween() -> void:
	if _guide_tween != null and is_instance_valid(_guide_tween):
		_guide_tween.kill()
	_guide_tween = null

# ——— Smooth Movement Helpers ———

func _apply_smooth_curve(time_ratio: float) -> float:
	# Apply a custom bezier-like curve for smooth movement
	# This creates a gentle ease-in, constant middle, ease-out pattern
	time_ratio = clamp(time_ratio, 0.0, 1.0)
	
	var curve_strength: float = clamp(smooth_curve_strength, 0.1, 1.0)
	
	# Use a cubic bezier-like interpolation
	# Start slow, accelerate to middle, then decelerate to end
	if time_ratio < 0.5:
		# First half: ease in
		var t: float = time_ratio * 2.0
		var ease_factor: float = curve_strength
		return (1.0 - ease_factor) * t + ease_factor * t * t * t
	else:
		# Second half: ease out  
		var t: float = (time_ratio - 0.5) * 2.0
		var ease_factor: float = curve_strength
		var base: float = 0.5 * ((1.0 - ease_factor) + ease_factor)
		var remaining: float = 1.0 - base
		return base + remaining * (1.0 - (1.0 - t) * (1.0 - t) * (1.0 - t))

# ——— Custom Save Data ———

func _find_existing_jar_near(pos: Vector2, radius: float = 12.0) -> FlyJar:
	var candidates: Array[Node] = []
	candidates.append_array(get_tree().get_nodes_in_group("BlueJar"))
	candidates.append_array(get_tree().get_nodes_in_group("FlyJar"))
	for node in candidates:
		var j: FlyJar = node as FlyJar
		if j and j.global_position.distance_to(pos) <= radius:
			return j
	return null

func _get_custom_save_data() -> Dictionary:
	return {
		"trial_duration": trial_duration,
		"trial_state": trial_state,
		"easy_cleared": easy_cleared,
		"hard_cleared": hard_cleared,
		"easy_reward_pending": easy_reward_pending
	}

func _load_custom_save_data(save_data: Dictionary) -> void:
	if save_data.has("trial_duration"):
		trial_duration = save_data["trial_duration"]
	
	# Reset trial state on load (don't restore mid-trial state)
	trial_state = TimeTrial.TrialState.WAITING
	if save_data.has("easy_cleared"):
		easy_cleared = bool(save_data["easy_cleared"]) 
	if save_data.has("hard_cleared"):
		hard_cleared = bool(save_data["hard_cleared"]) 
	if save_data.has("easy_reward_pending"):
		easy_reward_pending = bool(save_data["easy_reward_pending"]) 

	# If we have an outstanding easy reward, respawn it quietly after load
	if easy_reward_pending:
		_respawn_easy_reward_pending()

	# Apply tablet state based on persisted completion: default off unless hard cleared
	_set_tablets_powered(hard_cleared)

	# If completely cleared previously, ensure we won't re-arm
	if hard_cleared:
		state = BaseChallenge.ChallengeState.COMPLETED
		_disable_all_triggers()
		printerr("TimeTrial %s: Loaded as fully cleared (hard)" % challenge_id)

func _respawn_easy_reward_pending() -> void:
	# Defer to make sure the scene tree is ready and JarManager is available
	await get_tree().process_frame
	var spawn_pos = (easy_reward_spawn.global_position if easy_reward_spawn else _get_reward_position())
	# If an easy jar already exists near the spawn, reuse it
	var existing = _find_existing_jar_near(spawn_pos)
	if existing:
		_easy_spawned_reward = existing
		if not _easy_spawned_reward.collected.is_connected(_on_easy_reward_collected):
			_easy_spawned_reward.connect("collected", Callable(self, "_on_easy_reward_collected"))
		return
	
		_easy_spawned_reward = await _spawn_stage_reward(TimeTrial.Stage.EASY, false)
	if _easy_spawned_reward and not _easy_spawned_reward.collected.is_connected(_on_easy_reward_collected):
		_easy_spawned_reward.connect("collected", Callable(self, "_on_easy_reward_collected"))

func _on_easy_reward_collected(_jar: FlyJar) -> void:
	easy_reward_pending = false
	_persist.save_values()

# ——— Stage Reward Helpers ———

func _spawn_stage_reward(stage: TimeTrial.Stage, focus: bool = true) -> FlyJar:
	# Temporarily swap reward settings to reuse BaseChallenge spawn+focus
	var prev_type = reward_type
	var prev_spawn = reward_spawn
	if stage == TimeTrial.Stage.EASY:
		reward_type = easy_reward_type
		reward_spawn = (easy_reward_spawn if easy_reward_spawn else reward_spawn)
	else:
		reward_type = hard_reward_type
		reward_spawn = (hard_reward_spawn if hard_reward_spawn else reward_spawn)

	var jar: FlyJar = await _spawn_reward_and_focus(focus)

	# Restore defaults
	reward_type = prev_type
	reward_spawn = prev_spawn

	return jar

# ——— Public API ———

func get_time_remaining() -> float:
	return time_remaining

func get_completion_percentage() -> float:
	if trial_duration <= 0.0:
		return 0.0
	return ((trial_duration - time_remaining) / trial_duration) * 100.0

func is_trial_running() -> bool:
	return state == BaseChallenge.ChallengeState.ACTIVE and trial_state == TimeTrial.TrialState.RUNNING

# ——— Debug Functions ———

func debug_guide_state() -> void:
	printerr("=== TimeTrial %s Guide Debug ===" % challenge_id)
	printerr("  guide_fade_time: %.2f" % guide_fade_time)
	printerr("  trial_duration: %.2f" % trial_duration)
	printerr("  guide_path: %s" % ("valid" if guide_path else "null"))
	printerr("  guide_visual: %s" % ("valid" if guide_visual else "null"))
	printerr("  _guide_follow: %s" % ("valid" if _guide_follow else "null"))
	if _guide_follow:
		printerr("  _guide_follow alpha: %.2f" % _guide_follow.modulate.a)
	printerr("  _path_length: %.2f" % _path_length)
	
	if _guide_tween:
		printerr("  tween: %s (valid: %s)" % [_guide_tween, is_instance_valid(_guide_tween)])
	else:
		printerr("  tween: null")
	printerr("=========================")

# Call this in your challenge to help debug the guide system
func test_fade_in_out() -> void:
	if not _guide_follow:
		_init_guide()
	
	var visual = _get_visual()
	if not visual:
		printerr("TimeTrial %s: Cannot test fade - no visual node" % challenge_id)
		return
	
	printerr("TimeTrial %s: Testing fade in/out" % challenge_id)
	
	# Test fade out then fade in
	visual.modulate.a = 1.0
	var test_tween = create_tween()
	test_tween.tween_property(visual, "modulate:a", 0.0, guide_fade_time)
	test_tween.tween_property(visual, "modulate:a", 1.0, guide_fade_time)
