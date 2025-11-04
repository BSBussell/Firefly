class_name GateGuardian
extends DialogueArea2D

# GG's Dialogue System follows a structured template for emotional continuity:
# 1. GREETING (initial for first meeting, return greeting for subsequent visits)
# 2. OTHER GUARDIAN COMMENTS (if applicable) - Responsive wonder about meeting other protectors
# 3. CORE FILE DIALOGUE - Main conversation content from JSON files
# 4. PROGRESS UPDATE (if relevant) - Brief enthusiasm about firefly progress (kept short for text bubbles)
#
# All dialogue maintains GG's voice: earnest, nerdy, socially rusty, but always kind

## The number of jars required to pass through this gate.
@export var required_jars: int = 20

## Dialogue for when the player can't pass. Ensure it fits within Greeting | Comments | <Dialogue_File> | Progress String | Closing Line
@export_file("*.json") var gate_dialog: String

## Dialogue for when the player can't pass. Ensure it fits within Greeting | Comments | <Dialogue_File> | Progress String | Closing Line
@export_file("*.json") var pass_dialog: String

# Jar count display option
@export var show_level_jars_only: bool = false

## Things that are added around the base dialogue. Built to fit around the core dialogue
@export_group("Flavor Permutations")

## Initial greetings for first-time meetings
@export var initial_greetings: Array[String] = [
	"Hi! This is my spot, kinda. You can call me GG. Nice to meet ya!"
]

## Greeting variants for returning players
@export var return_greetings: Array[String] = [
	"Oh hey! You're back! I mean of course you are.",
	"Oh! My favorite firefly! You're the only one I know, but it still means something!",
	"Hey again! I was just standing here thinking... ...well never mind.",
	"Oh! Hi! I was just thinking about fireflies and... well, you!",
	"Hello!! To help with my anxiety I decide what to say next by picking straws!"
]

## Progress comments to specify our jar count
@export var progress_comments: Array[String] = [
	"Hmm, so you saved {jar_count}!",
	"Ok so you found {jar_count}.",
	"Hmmm, it seems you're {remaining_jars} short.",
	"Ok, you say you've found {jar_count}."
]

@export var requirement_comments: Array[String] = [
	"You just need to find {required_jars} to trust you.",
	"To see what's behind me, you gotta save {required_jars}.",
	"To prove you can handle it show me you've free'd {required_jars}.",
	"I gotta see {required_jars} jars to responsibly let you through."
]

@export var pass_on_talk: Array[String] = [
	"Oh wow! Usually I ask for {required_jars} fireflies, but you already did that!",
	"Wow, you have {required_jars} jars! You can go through now.",
	"Hey, you already have {required_jars} jars! Have fun exploring my spot!",
	"Oh ya, you've already free'd {required_jars} fireflies! You can defintely handle what's ahead!"
]

## Comments for when the player has talked to other guardians || Leave empty to omit
@export var other_guardian_comments: Array[String] = [
	"Hello! I had to run really fast to beat you here!",
	"Hello! This is another one of my cozy spots! It's one of my favorites.",
	"Hi again! phew I just got here. Is my timing great or what.",
	"Hello, Yeah, This is another cool spot this ones cooler."
]

## Meta comments when player has met multiple guardians || Leave empty to omit
@export var multiple_guardian_comments: Array[String] = [
	"Yes yes, I know we've met I'm here too. I'm quantum.",
	"Hey! You found this spot too! You have a knack for finding my best spots!",
	"Hi!! I'm here too... Please don't tell the union.",
	"You know, you're starting to get faster? You're making me run for my money!"
]


#GG stands for many things.
# Just to be clear the classname isn't GG's name full name
# See, the classname is more about the script function and
# Results than about what GG stands for. 
# For the record, theres a silly form of clue in this comment block

# Custom signals that other objects can connect to
signal player_can_pass()
signal player_denied_passage()
signal guardian_talked_to(talk_count: int, jar_count: int)

# Persistence data
var guardian_id: String
var has_talked_before: bool = false
var talk_count: int = 0
var last_known_jar_count: int = 0

# Shared static data for tracking all guardians globally (persisted across levels)
static var shared_guardian_data: Dictionary = {}
static var shared_encounter_count: int = 0
static var global_persistence_registered: bool = false
static var first_gg_greeting_shown: bool = false

# Instance-specific guardian type/name for tracking
@export var guardian_type: String = "gate_guardian"

var player: Flyph

# Track whether we've already granted passage to avoid duplicate unlocks
var pass_granted: bool = false
# Pending greeting (computed at dialogue start, prepended in add_dynamic_content)
var next_greeting_line: String = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	# Set the dialogue_file property for the parent class to use one of our files
	# This ensures the parent class initializes properly even though we override its behavior
	if not dialogue_file and gate_dialog:
		dialogue_file = gate_dialog
	
	# Call parent ready first
	super._ready()
	
	# Generate unique ID for this guardian
	guardian_id = "guardian_" + get_scene_file_path().get_file().get_basename() + "_" + str(global_position.x)+ "_" + str(global_position.y)
	
	# Register individual guardian data (cleared on level change)
	_persist.register_persistent_class(guardian_id, save_guardian_data, load_guardian_data)
	
	# Register global guardian tracking data (persists across levels) - only register once
	if not GateGuardian.global_persistence_registered:
		_persist.register_global_class("SharedGuardianData", GateGuardian.save_shared_guardian_data, GateGuardian.load_shared_guardian_data)
		GateGuardian.global_persistence_registered = true
	
	# Connect to the base dialogue signals to intercept them
	initiate_dialogue.connect(_on_dialogue_initiated)
	finish_dialogue.connect(_on_dialogue_finished)

	# If player already meets requirement, allow passage immediately (no need to talk)
	if can_player_pass_now():
		pass_granted = true
		# Defer to end of current frame so other nodes can connect in their _ready
		call_deferred("emit_signal", "player_can_pass")
		
	await _loader.finished_loading
	player = _globals.ACTIVE_PLAYER

func _process(delta):
	# Auto-unlock as soon as requirement is met, even without talking
	if not pass_granted and can_player_pass_now():
		pass_granted = true
		player_can_pass.emit()
	
	# If the player is to the right of the sprite :p
	if player.global_position.x > self.global_position.x:
		self.scale.x = -1
	else:
		self.scale.x = 1

	super._process(delta)

# Clean up when guardian is removed from scene to prevent null callable errors
func _exit_tree():
	# Remove this guardian's save/load functions from _persist to prevent null callable errors
	if _persist.save_funcs.has(guardian_id):
		_persist.save_funcs.erase(guardian_id)
	if _persist.load_funcs.has(guardian_id):
		_persist.load_funcs.erase(guardian_id)

# Override the _start_dialogue to use our custom logic
func _start_dialogue() -> void:
	in_dialogue = true
	
	# Compute greeting BEFORE registering this guardian (so first-ever logic isn't invalidated)
	var met_others_excl_current = get_other_gg_count_excluding_current()
	var first_shown = GateGuardian.first_gg_greeting_shown
	next_greeting_line = pick_greeting_line(first_shown, met_others_excl_current, has_talked_before)
	if not first_shown and next_greeting_line != "":
		GateGuardian.first_gg_greeting_shown = true

	# Track this guardian globally if first time talking (after greeting selection)
	if not has_talked_before:
		GateGuardian.register_guardian_safely(guardian_id, guardian_type, global_position)
	
	# Get dynamic dialogue based on player state
	var dialogue_to_use = get_dynamic_dialogue()
	
	# Track this interaction
	talk_count += 1
	has_talked_before = true
	var current_jar_count = get_display_jar_count()
	last_known_jar_count = current_jar_count
	
	# Emit custom signal for other systems to listen to
	guardian_talked_to.emit(talk_count, current_jar_count)
	
	# Emit the dialogue signal with our custom dialogue
	emit_signal("initiate_dialogue", dialogue_to_use, false)


# Calls the global jar tracker to get the total number of jars found
func get_all_found_jars() -> int:
	return _jar_tracker.total_num_found_jars()

func get_level_found_jars() -> int:
	var current_level = level.id
	return _jar_tracker.filter(func (value): 
		return value["level_id"] == current_level and value["nabbed"] == true
	).size()

# Get jar count based on the export setting
func get_display_jar_count() -> int:
	if show_level_jars_only:
		return get_level_found_jars()
	else:
		return get_all_found_jars()

# Get jar count for requirements (always use appropriate count for this guardian)
func get_requirement_jar_count() -> int:
	# For total jar requirements, use total jars
	# For level jar requirements, use level jars
	# This can be customized per guardian type
	return get_all_found_jars()  # Default to total jars for requirements

# Utility: whether player currently meets the requirement
func can_player_pass_now() -> bool:
	return get_requirement_jar_count() >= required_jars

# Persistence functions
func save_guardian_data() -> Dictionary:
	return {
		"has_talked_before": has_talked_before,
		"talk_count": talk_count,
		"last_known_jar_count": last_known_jar_count
	}

func load_guardian_data(data: Dictionary) -> void:
	has_talked_before = data.get("has_talked_before", false)
	talk_count = data.get("talk_count", 0)
	last_known_jar_count = data.get("last_known_jar_count", 0)

# Thread-safe functions for accessing shared guardian data - simplified without mutexes since _persist handles this
static func register_guardian_safely(id: String, type: String, pos: Vector2) -> void:
	if not shared_guardian_data.has(id):
		shared_guardian_data[id] = {
			"guardian_type": type,
			"first_encountered": true,
			"position": pos
		}
		shared_encounter_count += 1

static func get_shared_guardian_data() -> Dictionary:
	return shared_guardian_data.duplicate(true)

static func get_shared_encounter_count() -> int:
	return shared_encounter_count

# Shared guardian persistence functions (static functions for _persist to call)
static func save_shared_guardian_data() -> Dictionary:
	var save_data: Dictionary = {}
	save_data["_comment"] = "Shared guardian tracking data - be careful modifying this!"
	save_data["shared_guardian_data"] = shared_guardian_data.duplicate(true)
	save_data["shared_encounter_count"] = shared_encounter_count
	save_data["first_gg_greeting_shown"] = first_gg_greeting_shown
	return save_data

static func load_shared_guardian_data(save_data: Dictionary) -> void:
	if save_data.has("shared_guardian_data"):
		shared_guardian_data = save_data["shared_guardian_data"]
	if save_data.has("shared_encounter_count"):
		shared_encounter_count = save_data["shared_encounter_count"]
	if save_data.has("first_gg_greeting_shown"):
		first_gg_greeting_shown = save_data["first_gg_greeting_shown"]

# Signal handlers for dialogue events
func _on_dialogue_initiated(_source_dialogue: Dictionary, _repeat: bool) -> void:
	# This fires when dialogue starts - you can add custom logic here
	var display_jars = get_display_jar_count()
	var total_jars = get_all_found_jars()
	var level_jars = get_level_found_jars()
	print("Guardian dialogue started - Display: ", display_jars, " jars (Total: ", total_jars, ", Level: ", level_jars, ")")

func _on_dialogue_finished() -> void:
	# This fires when dialogue ends - emit appropriate signals
	var current_jars = get_requirement_jar_count()
	
	if current_jars >= required_jars:
		# Player has enough jars - emit pass signal
		pass_granted = true
		player_can_pass.emit()
		print("Guardian allows passage! (", current_jars, "/", required_jars, " jars)")
	else:
		# Player doesn't have enough jars - emit denial signal
		player_denied_passage.emit()
		print("Guardian denies passage - need ", (required_jars - current_jars), " more jars (", current_jars, "/", required_jars, ")")

# Dynamic dialogue selection based on player state
func get_dynamic_dialogue() -> Dictionary:
	var player_jars = get_requirement_jar_count()
	
	# Special case: First time talking AND player has enough jars
	# Use gate dialogue + pass_on_talk + pass dialogue
	if not has_talked_before and player_jars >= required_jars:
		var gate_dialogue = load_dialogue_file(gate_dialog)
		var pass_dialogue = load_dialogue_file(pass_dialog)
		var combined_dialogue = combine_gate_and_pass_dialogues(gate_dialogue, pass_dialogue)
		return add_dynamic_content(combined_dialogue)
	
	# Normal cases: Use either gate or pass dialogue
	var base_dialogue_file: String
	if player_jars >= required_jars:
		base_dialogue_file = pass_dialog
	else:
		base_dialogue_file = gate_dialog
	
	# Load the dialogue
	var loaded_dialogue = load_dialogue_file(base_dialogue_file)
	
	# Modify dialogue if player has talked before or other conditions
	loaded_dialogue = add_dynamic_content(loaded_dialogue)
	
	return loaded_dialogue

# Load dialogue from file
func load_dialogue_file(file_path: String) -> Dictionary:
	if not file_path:
		printerr("No dialogue file specified!")
		return {}
		
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var parsed_data = JSON.parse_string(json_string)
		if parsed_data:
			return parsed_data
		else:
			printerr("Error: Could not parse JSON from " + file_path)
	else:
		printerr("Error: Could not open file: " + file_path)
	
	return {}

# Combine gate and pass dialogues for the special first-time case
func combine_gate_and_pass_dialogues(gate_dialogue: Dictionary, pass_dialogue: Dictionary) -> Dictionary:
	if not gate_dialogue.has("dialogue") or not pass_dialogue.has("dialogue"):
		return gate_dialogue  # Fallback to gate dialogue if something goes wrong
	
	# Create combined dialogue with gate dialogue first, then pass_on_talk, then pass dialogue
	var combined = gate_dialogue.duplicate(true)
	var combined_array: Array[String] = []
	
	# Add gate dialogue content
	combined_array.append_array(gate_dialogue["dialogue"])
	
	# Add pass_on_talk comment
	var pass_on_talk_comment = pass_on_talk[randi() % pass_on_talk.size()]
	# Replace template variables
	pass_on_talk_comment = pass_on_talk_comment.replace("{required_jars}", str(required_jars))
	combined_array.append(pass_on_talk_comment)
	
	# Add pass dialogue content
	combined_array.append_array(pass_dialogue["dialogue"])
	
	# Set the combined array
	combined["dialogue"] = combined_array
	
	return combined

# Add dynamic content following the structured template: Greeting -> Other Guardian Comments -> Core File Dialogue -> Progress Update
# This ensures dialogue flows naturally and maintains GG's authentic awkward-but-earnest personality throughout
func add_dynamic_content(source_dialogue: Dictionary) -> Dictionary:

	if not source_dialogue.has("dialogue") or source_dialogue["dialogue"].is_empty():
		return source_dialogue
	
	# Clone the dialogue data to avoid modifying the original
	var modified_dialogue = source_dialogue.duplicate(true)
	var core_dialogue_array = modified_dialogue["dialogue"]
	
	# Build dialogue segments in template order
	var dialogue_segments: Array[String] = []
	
	# Get jar counts for templating
	var display_jar_count = get_display_jar_count()
	var requirement_jar_count = get_requirement_jar_count()
	var remaining_jars = max(0, required_jars - requirement_jar_count)
	var jar_type_text = "level" if show_level_jars_only else "total"
	
	# 1. GREETING (prepend the single selected greeting, if any)
	if next_greeting_line != "":
		dialogue_segments.append(next_greeting_line)
		next_greeting_line = ""
	
	# 3. CORE FILE DIALOGUE - add the core dialogue content
	dialogue_segments.append_array(core_dialogue_array)
	
	# 4. PROGRESS UPDATE (add contextual jar status if relevant)
	
	# Only show progress if we have less jars than required
	# (The pass_on_talk case is now handled in combine_gate_and_pass_dialogues)
	if requirement_jar_count < required_jars:
		# Add progress and requirement comments as separate lines
		var progress_comment = progress_comments[randi() % progress_comments.size()]
		var requirement_comment = requirement_comments[randi() % requirement_comments.size()]

		# Replace template variables in each line separately
		progress_comment = progress_comment.replace("{jar_count}", str(display_jar_count))
		progress_comment = progress_comment.replace("{required_jars}", str(required_jars))
		progress_comment = progress_comment.replace("{remaining_jars}", str(remaining_jars))
		progress_comment = progress_comment.replace("{jar_type}", jar_type_text)

		requirement_comment = requirement_comment.replace("{jar_count}", str(display_jar_count))
		requirement_comment = requirement_comment.replace("{required_jars}", str(required_jars))
		requirement_comment = requirement_comment.replace("{remaining_jars}", str(remaining_jars))
		requirement_comment = requirement_comment.replace("{jar_type}", jar_type_text)

		dialogue_segments.append(progress_comment)
		dialogue_segments.append(requirement_comment)
	
	# Set the final dialogue array (no closing encouragement)
	modified_dialogue["dialogue"] = dialogue_segments
	
	return modified_dialogue

# Get count of other guardians the player has encountered (excluding this one)
func get_other_guardian_count() -> int:
	var shared_data = GateGuardian.get_shared_guardian_data()
	var encounter_count = GateGuardian.get_shared_encounter_count()
	
	var count = 0
	for guardian_data in shared_data.values():
		if guardian_data.has("guardian_type") and guardian_data["guardian_type"] != guardian_type:
			count += 1
		elif not guardian_data.has("guardian_type"):
			# Count guardians without explicit type as different
			count += 1
	
	# If this guardian hasn't been registered yet but others have, count them
	if not shared_data.has(guardian_id):
		count = encounter_count
	else:
		# Subtract 1 for this guardian if it's already counted
		count = max(0, encounter_count - 1)
	
	return count

# Count other distinct GGs previously encountered (same guardian_type), excluding this instance
func get_other_gg_count_excluding_current() -> int:
	var shared_data = GateGuardian.get_shared_guardian_data()
	var count = 0
	for id in shared_data.keys():
		if id == guardian_id:
			continue
		var gd = shared_data[id]
		if gd.has("guardian_type") and gd["guardian_type"] == guardian_type:
			count += 1
	return count

# Deterministic greeting selector based on brief
func pick_greeting_line(first_shown: bool, met_others_excl_current: int, has_talked_this: bool) -> String:
	# 1) First-ever GG encounter (absolute precedence to ensure one clear intro even if globals are stale)
	if not first_shown and initial_greetings.size() > 0:
		return initial_greetings[randi() % initial_greetings.size()]
	# 2) Met > 1 other GGs
	if met_others_excl_current > 1 and multiple_guardian_comments.size() > 0:
		return multiple_guardian_comments[randi() % multiple_guardian_comments.size()]
	# 3) Met exactly 1 other GG
	if met_others_excl_current == 1 and other_guardian_comments.size() > 0:
		return other_guardian_comments[randi() % other_guardian_comments.size()]
	# 4) Return to this same GG
	if has_talked_this and return_greetings.size() > 0:
		return return_greetings[randi() % return_greetings.size()]
	# 5) Otherwise, no special greeting
	return ""

# Utility functions to connect external objects to guardian signals
func connect_to_gate(gate_node: Node, unlock_method: String = "unlock") -> void:
	"""Connect the guardian to a gate that should unlock when player can pass"""
	if gate_node.has_method(unlock_method):
		player_can_pass.connect(Callable(gate_node, unlock_method))
		# If passage already granted, unlock immediately
		if pass_granted or can_player_pass_now():
			gate_node.call_deferred(unlock_method)
	else:
		printerr("Gate node doesn't have method: " + unlock_method)

func connect_to_collider(collider: CollisionShape2D) -> void:
	"""Connect to a collider that should disable when player can pass"""
	player_can_pass.connect(func(): collider.disabled = true)
	# If passage already granted, disable immediately
	if pass_granted or can_player_pass_now():
		collider.disabled = true

func connect_to_animation(animation_player: AnimationPlayer, pass_animation: String = "open") -> void:
	"""Connect to an animation that should play when player can pass"""
	if animation_player.has_animation(pass_animation):
		player_can_pass.connect(func(): animation_player.play(pass_animation))
		# If passage already granted, play immediately
		if pass_granted or can_player_pass_now():
			animation_player.call_deferred("play", pass_animation)
	else:
		printerr("Animation player doesn't have animation: " + pass_animation)
