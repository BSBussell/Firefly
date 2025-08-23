extends DialogueArea2D
class_name ChallengeMeister

@export_category("Challenge")
@export var challenge: BaseChallenge

@export_category("Dialogs")
@export_file("*.json") var initial_challenge: String
@export_file("*.json") var challenge_fail: String
@export_file("*.json") var challenge_complete: String

# Track challenge state
var challenge_started: bool = false
var challenge_completed: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	# Call parent _ready first to set up dialogue system
	super._ready()
	
	# Connect to challenge signals if challenge is assigned
	if challenge:
		challenge.challenge_started.connect(_on_challenge_started)
		challenge.challenge_succeeded.connect(_on_challenge_succeeded)
		challenge.challenge_failed.connect(_on_challenge_failed)
		challenge.challenge_reset.connect(_on_challenge_reset)
		
		# Check initial challenge state
		challenge_completed = challenge.cleared
		_update_dialogue_file()
	else:
		_logger.warn("ChallengeMeister: No challenge assigned!")

func _update_dialogue_file() -> void:
	var new_file: String = ""
	
	if challenge_completed:
		new_file = challenge_complete
	elif challenge_started:
		new_file = challenge_fail  # Show fail dialogue when challenge is active/failed
	else:
		new_file = initial_challenge
	
	if new_file != "" and new_file != dialogue_file:
		dialogue_file = new_file
		load_file()
		_logger.info("ChallengeMeister: Updated dialogue to %s" % dialogue_file)

# Challenge event handlers
func _on_challenge_started(challenge_id: String, _context: Dictionary) -> void:
	challenge_started = true
	_update_dialogue_file()
	_logger.info("ChallengeMeister: Challenge %s started" % challenge_id)

func _on_challenge_succeeded(challenge_id: String, _context: Dictionary) -> void:
	challenge_completed = true
	challenge_started = false
	_update_dialogue_file()
	_logger.info("ChallengeMeister: Challenge %s completed!" % challenge_id)

func _on_challenge_failed(challenge_id: String, reason: String, _context: Dictionary) -> void:
	challenge_started = false  # Reset to show initial dialogue again
	_update_dialogue_file()
	_logger.info("ChallengeMeister: Challenge %s failed: %s" % [challenge_id, reason])

func _on_challenge_reset(challenge_id: String) -> void:
	challenge_started = false
	_update_dialogue_file()
	_logger.info("ChallengeMeister: Challenge %s reset" % challenge_id)
