extends BaseChallenge
class_name TimeTrial

# ——— TimeTrial-Specific Exports ———
@export_group("Trial Areas")
@export var entry_area: Area2D
@export var exit_area: Area2D

@export_group("Timing Settings")
@export var trial_duration: float = 10.0  # How long the player has to complete the trial
@export var grace_period: float = 0.5     # Extra time after timer expires before failure

@export_group("Guide/Pace System")
@export var guide_path: Path2D                    # Path the guide follows
@export var guide_visual: PackedScene             # Visual for the guide (firefly/particle scene)
@export var guide_fade_time: float = 0.4          # Fade in/out duration
@export var guide_finish_time: float = 0.6        # Rush to end duration on success/fail
@export var use_smooth_movement: bool = true       # Use bezier curve smoothing for guide movement
@export var smooth_curve_strength: float = 0.3     # How pronounced the smoothing curve is (0.1-1.0)
@export var restart_cooldown: float = 0.5          # Prevents instant restart spam

# ——— TimeTrial State ———
enum TrialState { WAITING, RUNNING, TIME_UP }
var trial_state: TimeTrial.TrialState = TimeTrial.TrialState.WAITING
var time_remaining: float = 0.0
var grace_timer: float = 0.0

# Guide system
var _guide_follow: PathFollow2D = null
var _path_length: float = 0.0
var _guide_tween: Tween = null
var _cooldown_until: float = 0.0

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
	
	_logger.info("TimeTrial %s: Setup complete, trial_duration=%.1fs" % [challenge_id, trial_duration])

func _on_challenge_start() -> void:
	trial_state = TimeTrial.TrialState.RUNNING
	time_remaining = trial_duration
	grace_timer = 0.0
	
	_init_guide()
	_start_guide_movement()
	
	var context: Dictionary = {
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
				fail_challenge("Time expired")

func _on_challenge_succeed() -> Dictionary:
	var completion_time: float = trial_duration - time_remaining
	var time_bonus: float = max(0.0, time_remaining)
	
	_guide_finish_and_fade(true)
	_cooldown_until = _now() + restart_cooldown
	
	return {
		"completion_time": completion_time,
		"time_bonus": time_bonus,
		"trial_duration": trial_duration,
		"entry_gate": "entry",
		"exit_gate": "exit"
	}

func _on_challenge_fail(reason: String) -> Dictionary:
	_guide_finish_and_fade(false)
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

	# If already running, fade out and restart guide from the beginning
	if state == BaseChallenge.ChallengeState.ACTIVE and trial_state == TimeTrial.TrialState.RUNNING:
		#_restart_mid_run_with_fade()
		#_cooldown_until = _now() + restart_cooldown
		return

	# Start the challenge fresh
	if not start_challenge(body as Flyph):
		_logger.warn("TimeTrial %s: Failed to start challenge" % challenge_id)

func _on_exit_entered(body: Node) -> void:
	if not is_valid_player(body):
		return
	
	if state != BaseChallenge.ChallengeState.ACTIVE:
		return
	
	if trial_state != TimeTrial.TrialState.RUNNING:
		return
	
	# Player reached the exit in time!
	succeed_challenge()

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
			_guide_follow.add_child(visual_instance)
			
			# Prepare visual to fade in on start
			var canvas_item: CanvasItem = visual_instance as CanvasItem
			if canvas_item:
				canvas_item.modulate.a = 0.0

func _start_guide_movement(start_fade_in: bool = true) -> void:
	if _guide_follow == null or _path_length <= 0.0:
		return
	
	# Move the guide with smooth bezier curve interpolation
	_kill_guide_tween()
	_guide_tween = create_tween()
	
	# Movement tween
	if use_smooth_movement:
		# Use a smooth ease curve for more natural movement
		_guide_tween.tween_property(_guide_follow, "progress", _path_length, trial_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		# Linear movement (original behavior)
		_guide_tween.tween_property(_guide_follow, "progress", _path_length, trial_duration).set_trans(Tween.TRANS_LINEAR)

	# Optional fade in at the start (in parallel with movement)
	if start_fade_in:
		var visual_node: CanvasItem = _get_visual()
		if visual_node:
			_guide_tween.parallel().tween_property(visual_node, "modulate:a", 1.0, guide_fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

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
	
	# Rush to the end
	if _path_length > 0.0:
		_guide_tween.tween_property(_guide_follow, "progress", _path_length, guide_finish_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Fade out the visual
	var visual_node: CanvasItem = _get_visual()
	if visual_node:
		_guide_tween.parallel().tween_property(visual_node, "modulate:a", 0.0, guide_fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
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
	# Fade out, teleport to start, fade in, then restart movement
	var visual_node: CanvasItem = _get_visual()
	if visual_node == null:
		_guide_follow.progress = 0.0
		_start_guide_movement()
		return
	_kill_guide_tween()
	var t: Tween = create_tween()
	t.tween_property(visual_node, "modulate:a", 0.0, guide_fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.finished.connect(func() -> void:
		_guide_follow.progress = 0.0
		visual_node.modulate.a = 0.0
		_clear_visual_trails()
		var t2: Tween = create_tween()
		t2.tween_property(visual_node, "modulate:a", 1.0, guide_fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_start_guide_movement(false)
	)

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

func _get_custom_save_data() -> Dictionary:
	return {
		"trial_duration": trial_duration,
		"trial_state": trial_state
	}

func _load_custom_save_data(save_data: Dictionary) -> void:
	if save_data.has("trial_duration"):
		trial_duration = save_data["trial_duration"]
	
	# Reset trial state on load (don't restore mid-trial state)
	trial_state = TimeTrial.TrialState.WAITING

# ——— Public API ———

func get_time_remaining() -> float:
	return time_remaining

func get_completion_percentage() -> float:
	if trial_duration <= 0.0:
		return 0.0
	return ((trial_duration - time_remaining) / trial_duration) * 100.0

func is_trial_running() -> bool:
	return state == BaseChallenge.ChallengeState.ACTIVE and trial_state == TimeTrial.TrialState.RUNNING
