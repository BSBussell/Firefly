extends BaseChallenge
class_name DialogueChallenge

# ——— DialogueChallenge-Specific Exports ———
@export_group("Dialogue Integration")
@export var dialogue_area: DialogueArea2D
@export var trigger_on_dialogue_finish: bool = true
@export var auto_start_on_ready: bool = false

# ——— DialogueChallenge State ———
var dialogue_connected: bool = false

# ——— BaseChallenge Overrides ———

func _setup_challenge() -> void:
	# Connect to dialogue area if assigned
	if dialogue_area and trigger_on_dialogue_finish:
		_connect_dialogue_signals()
	
	# Auto-start if configured
	if auto_start_on_ready:
		# Wait a frame to ensure everything is ready
		await get_tree().process_frame
		start_challenge()
	
	_logger.info("DialogueChallenge %s: Setup complete, dialogue_area=%s" % [challenge_id, "assigned" if dialogue_area else "none"])

func _on_challenge_start() -> void:
	# Connect dialogue signals if not already connected
	if dialogue_area and trigger_on_dialogue_finish and not dialogue_connected:
		_connect_dialogue_signals()
	
	_logger.info("DialogueChallenge %s: Started, waiting for dialogue to finish" % challenge_id)

func _process_challenge_logic(_delta: float) -> void:
	# This challenge type is purely event-driven by dialogue completion
	# No ongoing logic needed during active state
	pass

func _on_challenge_reset() -> void:
	# Disconnect dialogue signals when resetting
	_disconnect_dialogue_signals()
	dialogue_connected = false

func _validate_player_requirements() -> bool:
	# For dialogue challenges, we just need the dialogue area to be valid
	return is_instance_valid(dialogue_area) if trigger_on_dialogue_finish else true

func _disable_challenge_specific_triggers() -> void:
	# Disconnect dialogue signals when challenge is completed
	_disconnect_dialogue_signals()

# ——— Dialogue Integration ———

func _connect_dialogue_signals() -> void:
	if not dialogue_area or dialogue_connected:
		return
	
	if not dialogue_area.finish_dialogue.is_connected(_on_dialogue_finished):
		dialogue_area.finish_dialogue.connect(_on_dialogue_finished)
		dialogue_connected = true
		_logger.info("DialogueChallenge %s: Connected to dialogue finish signal" % challenge_id)

func _disconnect_dialogue_signals() -> void:
	if not dialogue_area or not dialogue_connected:
		return
	
	if dialogue_area.finish_dialogue.is_connected(_on_dialogue_finished):
		dialogue_area.finish_dialogue.disconnect(_on_dialogue_finished)
		dialogue_connected = false
		_logger.info("DialogueChallenge %s: Disconnected from dialogue signals" % challenge_id)

func _on_dialogue_finished() -> void:
	if state == BaseChallenge.ChallengeState.COMPLETED:
		return
	
	_logger.info("DialogueChallenge %s: Dialogue finished, completing challenge" % challenge_id)
	
	# Complete the challenge with dialogue context
	var dialogue_name: String = ""
	if dialogue_area:
		dialogue_name = dialogue_area.name
	
	var context: Dictionary = {
		"triggered_by": "dialogue_finish",
		"dialogue_area": dialogue_name
	}
	
	succeed_challenge(context)

# ——— Lifecycle Override ———

func _exit_tree() -> void:
	_disconnect_dialogue_signals()
	super._exit_tree()

# ——— Custom Save Data ———

func _get_custom_save_data() -> Dictionary:
	return {
		"trigger_on_dialogue_finish": trigger_on_dialogue_finish,
		"auto_start_on_ready": auto_start_on_ready
	}

func _load_custom_save_data(save_data: Dictionary) -> void:
	if save_data.has("trigger_on_dialogue_finish"):
		trigger_on_dialogue_finish = save_data["trigger_on_dialogue_finish"]
	
	if save_data.has("auto_start_on_ready"):
		auto_start_on_ready = save_data["auto_start_on_ready"]

# ——— Public API ———

func set_dialogue_area(new_dialogue_area: DialogueArea2D) -> void:
	# Disconnect from old area
	_disconnect_dialogue_signals()
	
	# Set new area
	dialogue_area = new_dialogue_area
	
	# Connect to new area if challenge is active
	if state == BaseChallenge.ChallengeState.ACTIVE and trigger_on_dialogue_finish:
		_connect_dialogue_signals()

func is_dialogue_connected() -> bool:
	return dialogue_connected

func force_dialogue_completion() -> void:
	if state == BaseChallenge.ChallengeState.ACTIVE:
		_on_dialogue_finished()
