extends BaseChallenge
class_name BounceTestV2

# ——— BounceTest-Specific Exports ———
@export_group("Bounce Gates")
@export var gate_1: Area2D
@export var gate_2: Area2D

@export_group("Airborne Requirements")
@export var grace_seconds: float = 0.1  # Seconds player can stay on ground before failing

# ——— BounceTest State ———
enum BounceState { IDLE, WAITING_FOR_AIR, AIRBORNE }
var bounce_state: BounceTestV2.BounceState = BounceTestV2.BounceState.IDLE

var _start_gate: Area2D = null
var _finish_gate: Area2D = null
var _ground_time: float = 0.0


# ——— BaseChallenge Overrides ———

func _setup_challenge() -> void:
	# Set up bidirectional gate monitoring
	if gate_1:
		setup_area_monitoring(gate_1, _on_gate_1_entered)
		gate_1.monitoring = true
	if gate_2:
		setup_area_monitoring(gate_2, _on_gate_2_entered)
		gate_2.monitoring = true
	
	_logger.info("BounceTestV2 %s: Setup complete, gates ready" % challenge_id)

func _on_challenge_start() -> void:
	bounce_state = BounceTestV2.BounceState.WAITING_FOR_AIR
	_ground_time = 0.0
	
	_logger.info("BounceTestV2 %s: Started, waiting for player to go airborne" % challenge_id)

func _process_challenge_logic(delta: float) -> void:
	if not is_instance_valid(player):
		fail_challenge("lost player reference")
		return
		
	match bounce_state:
		BounceTestV2.BounceState.WAITING_FOR_AIR:
			if not player.is_on_floor():
				bounce_state = BounceTestV2.BounceState.AIRBORNE
				_ground_time = 0.0
				_logger.info("BounceTestV2 %s: Player is now airborne" % challenge_id)
		
		BounceTestV2.BounceState.AIRBORNE:
			if player.is_on_floor():
				_ground_time += delta
				if _ground_time > grace_seconds:
					fail_challenge("touched ground too long (%.3fs > %.3fs)" % [_ground_time, grace_seconds])
			else:
				_ground_time = 0.0

func _on_challenge_succeed() -> Dictionary:
	return {
		"start_gate": _gate_name(_start_gate),
		"finish_gate": _gate_name(_finish_gate)
	}

func _on_challenge_fail(reason: String) -> Dictionary:
	return {
		"reason": reason,
		"start_gate": _gate_name(_start_gate),
		"finish_gate": _gate_name(_finish_gate)
	}

func _on_challenge_reset() -> void:
	bounce_state = BounceTestV2.BounceState.IDLE
	_ground_time = 0.0
	_start_gate = null
	_finish_gate = null
	
	# Restore gate monitoring
	if gate_1: 
		gate_1.monitoring = true
	if gate_2: 
		gate_2.monitoring = true

func _validate_player_requirements() -> bool:
	return gate_1 and gate_2

func _disable_challenge_specific_triggers() -> void:
	if gate_1:
		gate_1.monitoring = false
	if gate_2:
		gate_2.monitoring = false

# ——— Gate Event Handlers ———

func _on_gate_1_entered(body: Node) -> void:
	_gate_entered(body, gate_1)

func _on_gate_2_entered(body: Node) -> void:
	_gate_entered(body, gate_2)

func _gate_entered(body: Node, gate: Area2D) -> void:
	if not is_valid_player(body):
		return
	
	# Set player reference
	player = body as Flyph
	
	if state == BaseChallenge.ChallengeState.IDLE:
		# Start the challenge
		_start_gate = gate
		_finish_gate = (gate_2 if gate == gate_1 else gate_1)
		_logger.info("BounceTestV2 %s: Armed start=%s finish=%s" % [challenge_id, _gate_name(_start_gate), _gate_name(_finish_gate)])
		start_challenge(player)
		return
	
	if gate == _finish_gate and state == BaseChallenge.ChallengeState.ACTIVE:
		# Player reached finish gate - success!
		succeed_challenge()

# ——— Utility Methods ———

func _gate_name(gate: Area2D) -> String:
	if gate == null:
		return "None"
	if gate == gate_1:
		return "Gate1"
	if gate == gate_2:
		return "Gate2"
	return gate.name

# ——— Custom Save Data ———

func _get_custom_save_data() -> Dictionary:
	return {
		"grace_seconds": grace_seconds,
		"bounce_state": bounce_state
	}

func _load_custom_save_data(save_data: Dictionary) -> void:
	if save_data.has("grace_seconds"):
		grace_seconds = save_data["grace_seconds"]
	
	# Reset bounce state on load
	bounce_state = BounceTestV2.BounceState.IDLE

# ——— Public API ———

func get_current_bounce_state() -> BounceTestV2.BounceState:
	return bounce_state

func is_bounce_running() -> bool:
	return state == BaseChallenge.ChallengeState.ACTIVE and bounce_state == BounceTestV2.BounceState.AIRBORNE
