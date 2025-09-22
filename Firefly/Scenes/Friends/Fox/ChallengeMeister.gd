extends DialogueArea2D
class_name ChallengeMeister

signal challenge_passed(challenge_id: String, context: Dictionary)

@export_category("Challenge")
@export var challenge: BaseChallenge

@export_category("Dialogs")
@export_file("*.json") var initial_challenge: String
@export_file("*.json") var challenge_fail: String
@export_file("*.json") var challenge_complete: String

# Track challenge state
var challenge_started: bool = false
var challenge_completed: bool = false
var _emitted_loaded_pass_once: bool = false

# Track first-time conversation behavior
var has_talked_before: bool = false
var talk_count: int = 0
var meister_id: String = ""

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
		if challenge.has_signal("challenge_status_loaded"):
			challenge.challenge_status_loaded.connect(_on_challenge_status_loaded)
		else:
			printerr("ChallengeMeister: Signal 'challenge_status_loaded' not found")

		# Check initial challenge state
		challenge_completed = challenge.cleared
		_update_dialogue_file()
	else:
		printerr("ChallengeMeister: No challenge assigned!")

	# Register persistence for first-talk state using a unique ID per instance
	meister_id = "challenge_meister_" + get_scene_file_path().get_file().get_basename() + "_" + str(global_position.x) + "_" + str(global_position.y)
	_persist.register_persistent_class(meister_id, Callable(self, "save_meister_data"), Callable(self, "load_meister_data"))

	# Also update after persistence finishes loading (covers legacy challenges)
	if _loader and not _loader.finished_loading.is_connected(_on_after_persist_loaded):
		_loader.finished_loading.connect(_on_after_persist_loaded)

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

# Challenge event handlers
func _on_challenge_started(challenge_id: String, _context: Dictionary) -> void:
	challenge_started = true
	_update_dialogue_file()

func _on_challenge_succeeded(challenge_id: String, context: Dictionary) -> void:
	challenge_completed = true
	challenge_started = false
	_update_dialogue_file()
	emit_signal("challenge_passed", challenge_id, context)

func _on_challenge_failed(challenge_id: String, reason: String, _context: Dictionary) -> void:
	challenge_started = false  # Reset to show initial dialogue again
	_update_dialogue_file()

func _on_challenge_reset(challenge_id: String) -> void:
	challenge_started = false
	_update_dialogue_file()

func _on_challenge_status_loaded(_challenge_id: String, state: int, cleared: bool) -> void:
	challenge_completed = cleared or state == BaseChallenge.ChallengeState.COMPLETED
	challenge_started = false
	_update_dialogue_file()
	# If the challenge was already completed when loading, emit pass once
	if challenge_completed and not _emitted_loaded_pass_once:
		_emitted_loaded_pass_once = true
		var ctx := {"source": "load", "pre_completed": true}
		emit_signal("challenge_passed", challenge.challenge_id, ctx)

func _on_after_persist_loaded() -> void:
	# Re-evaluate completion once persistence has loaded values
	if challenge:
		challenge_completed = challenge.cleared or challenge.state == BaseChallenge.ChallengeState.COMPLETED
		_update_dialogue_file()
		if challenge_completed and not _emitted_loaded_pass_once:
			_emitted_loaded_pass_once = true
			var ctx := {"source": "post_load", "pre_completed": true}
			emit_signal("challenge_passed", challenge.challenge_id, ctx)

func _exit_tree() -> void:
	# Prevent stale callable references in persistence system
	if meister_id != "":
		if _persist.save_funcs.has(meister_id):
			_persist.save_funcs.erase(meister_id)
		if _persist.load_funcs.has(meister_id):
			_persist.load_funcs.erase(meister_id)
	# Disconnect finished_loading if connected
	if _loader and _loader.finished_loading.is_connected(_on_after_persist_loaded):
		_loader.finished_loading.disconnect(_on_after_persist_loaded)

# Ensure first talk always uses the initial dialogue file
func _start_dialogue() -> void:
	in_dialogue = true

	var data_to_use: Dictionary = {}
	var used_initial: bool = false

	if not has_talked_before and initial_challenge != "":
		data_to_use = _load_dialogue_from_file(initial_challenge)
		used_initial = data_to_use != {}

	# Fallback to currently loaded dialogue if initial was missing or failed to load
	if data_to_use == {}:
		data_to_use = dialogue_data

	# Track interaction
	talk_count += 1
	has_talked_before = true


	# Emit the dialogue to the UI
	emit_signal("initiate_dialogue", data_to_use, false)

# Helper to load a dialogue JSON file into a Dictionary
func _load_dialogue_from_file(path: String) -> Dictionary:
	var result: Dictionary = {}
	if path == "":
		return result
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		var parsed = JSON.parse_string(json_string)
		if typeof(parsed) == TYPE_DICTIONARY:
			result = parsed
		else:
			printerr("ChallengeMeister: Error parsing initial dialogue JSON for ", path)
	else:
		printerr("ChallengeMeister: Could not open initial dialogue file: ", path)
	return result

# Persistence for first-talk state
func save_meister_data() -> Dictionary:
	return {
		"has_talked_before": has_talked_before,
		"talk_count": talk_count
	}

func load_meister_data(data: Dictionary) -> void:
	if data.has("has_talked_before"):
		has_talked_before = data["has_talked_before"]
	if data.has("talk_count"):
		talk_count = data["talk_count"]
