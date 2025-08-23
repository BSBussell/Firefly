extends BaseChallenge
class_name SlimeRoom

# ——— SlimeRoom-Specific Exports ———
@export_group("Slime Challenge")
@export var goober_group_name: String = "SlimeRoomGoobers"  # Group name for goobers to track
@export var target_player: Flyph                           # The player to track (export for easy assignment)
@export var require_all_goobers: bool = true               # If false, just need to bounce on any goober
@export var allow_repeat_bounces: bool = false             # If true, can bounce on same goober multiple times

@export_group("Ground Detection")
@export var ground_grace_period: float = 0.3          # Time on ground before resetting
@export var reset_on_ground: bool = true              # Whether touching ground resets progress

@export_group("Visual Feedback")
@export var highlight_completed_goobers: bool = true  # Visual feedback for completed goobers
@export var completed_modulate: Color = Color.GREEN   # Color for completed goobers
@export var pending_modulate: Color = Color.WHITE     # Color for pending goobers

# ——— SlimeRoom State ———
var bounced_goobers: Array[goober] = []               # Goobers that have been bounced on
var ground_timer: float = 0.0                        # Time spent on ground
var is_on_ground: bool = false                       # Current ground state
var challenge_active: bool = false                    # Whether we're actively tracking

# Internal tracking
var _goober_connections: Dictionary = {}              # Track signal connections
var _original_modulates: Dictionary = {}              # Store original goober colors

# ——— Group Helper Methods ———

func _get_goobers_from_group() -> Array[goober]:
	var group_goobers: Array[goober] = []
	var nodes: Array[Node] = get_tree().get_nodes_in_group(goober_group_name)
	
	for node in nodes:
		var goober_instance: goober = node as goober
		if goober_instance:
			group_goobers.append(goober_instance)
	
	return group_goobers

func _get_goober_count() -> int:
	return get_tree().get_nodes_in_group(goober_group_name).size()

# ——— BaseChallenge Overrides ———

func _setup_challenge() -> void:
	if target_player == null:
		target_player = _globals.ACTIVE_PLAYER
		_logger.warn("SlimeRoom %s: No target_player set, using ACTIVE_PLAYER" % challenge_id)
	
	_connect_goobers()
	_store_original_colors()
	_update_visual_feedback()
	
	_logger.info("SlimeRoom %s: Setup complete, tracking %d goobers" % [challenge_id, _get_goober_count()])

func _on_challenge_start() -> void:
	challenge_active = true
	bounced_goobers.clear()
	ground_timer = 0.0
	is_on_ground = false
	
	_update_visual_feedback()
	
	var context: Dictionary = {
		"total_goobers": _get_goober_count(),
		"require_all": require_all_goobers,
		"allow_repeats": allow_repeat_bounces
	}
	update_challenge_progress(context)

func _process_challenge_logic(delta: float) -> void:
	if not challenge_active or not is_instance_valid(target_player):
		return
	
	# Track ground state
	var currently_on_ground: bool = target_player.is_on_floor()
	
	if currently_on_ground:
		if not is_on_ground:
			# Just landed
			is_on_ground = true
			ground_timer = 0.0
		else:
			# Still on ground, increment timer
			ground_timer += delta
			
			# Check if we've exceeded grace period
			if reset_on_ground and ground_timer >= ground_grace_period:
				_reset_progress("Ground contact exceeded grace period")
	else:
		# In air
		if is_on_ground:
			# Just left ground
			is_on_ground = false
			ground_timer = 0.0
	
	# Send progress updates
	var progress_data: Dictionary = {
		"bounced_count": bounced_goobers.size(),
		"total_goobers": _get_goober_count(),
		"progress_percent": _get_progress_percentage(),
		"is_on_ground": is_on_ground,
		"ground_timer": ground_timer,
		"remaining_goobers": _get_remaining_goobers().size()
	}
	update_challenge_progress(progress_data)

func _on_challenge_succeed() -> Dictionary:
	challenge_active = false
	
	return {
		"bounced_goobers": bounced_goobers.size(),
		"total_goobers": _get_goober_count(),
		"completion_type": "all_goobers" if require_all_goobers else "any_goober",
		"final_sequence": _get_bounce_sequence()
	}

func _on_challenge_fail(reason: String) -> Dictionary:
	challenge_active = false
	
	return {
		"reason": reason,
		"bounced_count": bounced_goobers.size(),
		"total_goobers": _get_goober_count(),
		"progress_percent": _get_progress_percentage()
	}

func _on_challenge_reset() -> void:
	challenge_active = false
	bounced_goobers.clear()
	ground_timer = 0.0
	is_on_ground = false
	_update_visual_feedback()

func _validate_player_requirements() -> bool:
	return is_instance_valid(target_player) and _get_goober_count() > 0

# ——— Goober Management ———

func _connect_goobers() -> void:
	_disconnect_all_goobers()
	
	var group_goobers: Array[goober] = _get_goobers_from_group()
	for i in range(group_goobers.size()):
		var goober_instance: goober = group_goobers[i]
		if is_instance_valid(goober_instance):
			if not goober_instance.Bounce.is_connected(_on_goober_bounced):
				goober_instance.Bounce.connect(_on_goober_bounced.bind(goober_instance))
				_goober_connections[goober_instance] = true
				_logger.info("SlimeRoom %s: Connected to goober %d" % [challenge_id, i])

func _disconnect_all_goobers() -> void:
	for goober_instance in _goober_connections.keys():
		if is_instance_valid(goober_instance) and goober_instance.Bounce.is_connected(_on_goober_bounced):
			goober_instance.Bounce.disconnect(_on_goober_bounced)
	_goober_connections.clear()

func _store_original_colors() -> void:
	_original_modulates.clear()
	var group_goobers: Array[goober] = _get_goobers_from_group()
	for goober_instance in group_goobers:
		if is_instance_valid(goober_instance):
			_original_modulates[goober_instance] = goober_instance.modulate

func _update_visual_feedback() -> void:
	if not highlight_completed_goobers:
		return
	
	var group_goobers: Array[goober] = _get_goobers_from_group()
	for goober_instance in group_goobers:
		if not is_instance_valid(goober_instance):
			continue
		
		if goober_instance in bounced_goobers:
			goober_instance.modulate = completed_modulate
		else:
			goober_instance.modulate = pending_modulate

func _restore_original_colors() -> void:
	for goober_instance in _original_modulates.keys():
		if is_instance_valid(goober_instance):
			goober_instance.modulate = _original_modulates[goober_instance]

# ——— Signal Handlers ———

func _on_goober_bounced(bounced_goober: goober) -> void:
	if not challenge_active:
		# Auto-start challenge on first bounce if not started
		if state == BaseChallenge.ChallengeState.IDLE:
			if not start_challenge(target_player):
				return
		else:
			return
	
	# Check if this goober should count
	if not allow_repeat_bounces and bounced_goober in bounced_goobers:
		_logger.info("SlimeRoom %s: Repeat bounce ignored on goober" % challenge_id)
		return
	
	# Add to bounced list
	if not bounced_goober in bounced_goobers:
		bounced_goobers.append(bounced_goober)
	
	_update_visual_feedback()
	
	_logger.info("SlimeRoom %s: Bounced on goober (%d/%d)" % [challenge_id, bounced_goobers.size(), _get_goober_count()])
	
	# Check if challenge is complete
	if _is_challenge_complete():
		succeed_challenge()
	else:
		# Send progress update
		var goober_name: String = str(bounced_goober.name) if bounced_goober.name != "" else "goober"
		var progress_data: Dictionary = {
			"latest_bounce": goober_name,
			"bounced_count": bounced_goobers.size(),
			"remaining_count": _get_remaining_goobers().size()
		}
		update_challenge_progress(progress_data)

# ——— Challenge Logic ———

func _is_challenge_complete() -> bool:
	if require_all_goobers:
		return bounced_goobers.size() >= _get_goober_count()
	else:
		return bounced_goobers.size() > 0

func _reset_progress(reason: String) -> void:
	if bounced_goobers.size() == 0:
		return  # Nothing to reset
	
	_logger.info("SlimeRoom %s: Progress reset - %s" % [challenge_id, reason])
	
	bounced_goobers.clear()
	_update_visual_feedback()
	
	# Emit progress reset (not a full challenge fail)
	var reset_data: Dictionary = {
		"reason": reason,
		"was_progress": true
	}
	update_challenge_progress(reset_data)

func _get_progress_percentage() -> float:
	var total_count: int = _get_goober_count()
	if total_count == 0:
		return 0.0
	return (float(bounced_goobers.size()) / float(total_count)) * 100.0

func _get_remaining_goobers() -> Array[goober]:
	var remaining: Array[goober] = []
	var group_goobers: Array[goober] = _get_goobers_from_group()
	for goober_instance in group_goobers:
		if not goober_instance in bounced_goobers:
			remaining.append(goober_instance)
	return remaining

func _get_bounce_sequence() -> Array[String]:
	var sequence: Array[String] = []
	for goober_instance in bounced_goobers:
		var goober_name: String = str(goober_instance.name) if goober_instance.name != "" else "goober"
		sequence.append(goober_name)
	return sequence

# ——— Custom Save Data ———

func _get_custom_save_data() -> Dictionary:
	return {
		"require_all_goobers": require_all_goobers,
		"allow_repeat_bounces": allow_repeat_bounces,
		"ground_grace_period": ground_grace_period,
		"goober_count": _get_goober_count(),
		"goober_group_name": goober_group_name
	}

func _load_custom_save_data(save_data: Dictionary) -> void:
	if save_data.has("require_all_goobers"):
		require_all_goobers = save_data["require_all_goobers"]
	if save_data.has("allow_repeat_bounces"):
		allow_repeat_bounces = save_data["allow_repeat_bounces"]
	if save_data.has("ground_grace_period"):
		ground_grace_period = save_data["ground_grace_period"]
	
	# Reset challenge state on load
	challenge_active = false
	bounced_goobers.clear()

# ——— Cleanup ———

func _exit_tree() -> void:
	_disconnect_all_goobers()
	_restore_original_colors()
	super._exit_tree()

# ——— Public API ———

func add_goober(new_goober: goober) -> void:
	var group_goobers: Array[goober] = _get_goobers_from_group()
	if new_goober in group_goobers:
		return
	
	# Add to the group
	new_goober.add_to_group(goober_group_name)
	_store_original_colors()
	
	# Connect if challenge is already set up
	if is_inside_tree():
		if not new_goober.Bounce.is_connected(_on_goober_bounced):
			new_goober.Bounce.connect(_on_goober_bounced.bind(new_goober))
			_goober_connections[new_goober] = true
	
	_update_visual_feedback()
	_logger.info("SlimeRoom %s: Added goober to group, total count: %d" % [challenge_id, _get_goober_count()])

func remove_goober(goober_to_remove: goober) -> void:
	var group_goobers: Array[goober] = _get_goobers_from_group()
	if not goober_to_remove in group_goobers:
		return
	
	# Disconnect signal
	if goober_to_remove in _goober_connections:
		if is_instance_valid(goober_to_remove) and goober_to_remove.Bounce.is_connected(_on_goober_bounced):
			goober_to_remove.Bounce.disconnect(_on_goober_bounced)
		_goober_connections.erase(goober_to_remove)
	
	# Remove from group and arrays
	goober_to_remove.remove_from_group(goober_group_name)
	bounced_goobers.erase(goober_to_remove)
	_original_modulates.erase(goober_to_remove)
	
	_update_visual_feedback()
	_logger.info("SlimeRoom %s: Removed goober from group, total count: %d" % [challenge_id, _get_goober_count()])

func get_bounced_count() -> int:
	return bounced_goobers.size()

func get_remaining_count() -> int:
	return _get_goober_count() - bounced_goobers.size()

func is_goober_bounced(goober_instance: goober) -> bool:
	return goober_instance in bounced_goobers

func force_start_challenge() -> bool:
	return start_challenge(target_player)
