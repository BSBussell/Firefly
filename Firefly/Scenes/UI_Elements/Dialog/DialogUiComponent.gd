extends UiComponent
class_name DialogueUiComponent

signal dialogue_closed()

# Child node for displaying the dialogue text
@onready var text_box: ButtonPromptLabel = $Label
@onready var animation_player = $AnimationPlayer
@onready var animated_sprite_2d = $SpriteAnchor/AnimatedSprite2D
@onready var hoverAnim = $SpriteAnchor/hoverAnim

var current_dialogue
var current_dialogue_arr: Array
var current_loc: int = 0
var dialogue_up: bool = false

# Track the player we temporarily actorize during dialogue
var _actorized_player: Flyph = null
var _actorized_prev_state: bool = false

# Called when the node enters the scene tree
func _ready() -> void:
	
	# Initially hide the dialogue box
	animation_player.play("RESET")
	
	# Disable process loop while hidden
	set_process(false)
	

## Connect Dialogue Signals to the Components Functions
func connect_to_func(init_sig: Signal, end_sig: Signal):
	
	# Connect the provided signals to their functions
	init_sig.connect(Callable(self, "initiate_dialogue"))
	end_sig.connect(Callable(self, "finish_dialogue"))

# Only enabled while the textbox is visible
func _process(_delta):
	if text_box.visible and (Input.is_action_just_pressed(&"interact") or Input.is_action_just_pressed(&"Jump")):
		
		current_loc += 1
		if current_loc >= current_dialogue_arr.size():
			finish_dialogue()
		else:
			next_dialogue()
	
	if text_box.visible and Input.is_action_just_released("ui_cancel"):
		finish_dialogue()
	
	var font_size: int = text_box.theme.get_font_size("normal_font_size", "RichTextLabel")
	text_box.PROMPT_SCALE = font_size / 9




# Initiates Dialogue by setting text_bo
func initiate_dialogue(text: Dictionary, repeat: bool) -> void:

	dialogue_up = true

	current_dialogue = text
	# Preprocess dialogue to enforce bubble length limits
	current_dialogue_arr = _preprocess_dialogue_array(text["dialogue"], 84)
	current_loc = 0

	# Instead of pausing the game, temporarily set the active player
	# to actor mode so they don't accept input during dialogue.
	if _globals.ACTIVE_PLAYER:
		_actorized_player = _globals.ACTIVE_PLAYER
		_actorized_prev_state = _actorized_player.is_actor
		_actorized_player.is_actor = true
		# Nudge input to neutral to avoid lingering movement
		if _actorized_player.has_method("lock_h_dir"):
			_actorized_player.lock_h_dir(0, 0.1)
		_actorized_player.horizontal_axis = 0
	
	# Set the dialogue text, for smoother visuals replace with animation
	set_text(current_dialogue_arr[current_loc])
	
	# Play Animations
	hoverAnim.play("hover")
	animation_player.play("show_bubble")
	await animation_player.animation_finished
	animation_player.play("show_text")
	await animation_player.animation_finished
	
	
	# Enable Process Loop to look for button Presses
	set_process(true)
	
	


func next_dialogue():
	
	# Clear Text Animation
	animation_player.play("wipe_text")
	
	await animation_player.animation_finished
	
	
	if current_loc >= current_dialogue_arr.size():
		return
		
	# Set the dialogue text, for smoother visuals replace with animation
	set_text(current_dialogue_arr[current_loc])
	
	# Roate the diamond 
	animated_sprite_2d.play("rotate")
	
	
	# Show the text
	animation_player.play("show_text")
	
	# Wait for animation to finish
	#await animation_player.animation_finished
	

func finish_dialogue() -> void:

	if not dialogue_up:
		return
		
	dialogue_up = false

	# Restore player control if we toggled actor mode here
	if is_instance_valid(_actorized_player):
		# Softly unlock and neutralize inputs to prevent accidental drift
		if _actorized_player.has_method("lock_h_dir"):
			_actorized_player.lock_h_dir(0, 0.15, true)
		_actorized_player.horizontal_axis = 0
		# Only revert actor flag if we enabled it
		if not _actorized_prev_state:
			_actorized_player.is_actor = false
		_actorized_player = null
		_actorized_prev_state = false
	
	# For smoother visuals replace with animation
	hoverAnim.stop()
	animation_player.play("wipe_text")
	
	# Disable Process Loop for efficiency
	set_process(false)
	
	animation_player.play("hide_bubble")
	
	if current_dialogue["victory_dialogue"]:
		context.emit_win_signal()

	# Notify listeners that the dialogue UI has fully closed
	emit_signal("dialogue_closed")


# Just a wrapper to make adding the centers ez
func set_text(text: String):

	text = "[center]" + text + "[/center]"
	text_box.text = text
	text_box.rebuild_prompts()


# Splits long lines into multiple bubbles of <= max_len characters.
# Adds trailing ellipses ("...") to any bubble that is followed by another.
func _split_text_to_bubbles(line: String, max_len: int = 84) -> Array:
	var bubbles: Array = []
	var ell := "..."
	var remaining: String = line.strip_edges()

	# Safety for very small limits
	if max_len < ell.length():
		bubbles.append(remaining)
		return bubbles

	while remaining.length() > max_len:
		# 1) Prefer cutting at phrase breaks within the allowed width.
		#    We treat commas and periods (and common end punctuations) as breaks
		#    and do NOT append ellipses when cutting on these.
		var break_chars := [",", ".", "!", "?", ";", ":"]
		var best_punct_pos := -1
		for ch in break_chars:
			var pos := remaining.rfind(ch, max_len)
			if pos > best_punct_pos and pos > 0 and pos <= max_len:
				best_punct_pos = pos

		if best_punct_pos > 0:
			# Include the punctuation in this bubble; no ellipsis
			var part := remaining.substr(0, best_punct_pos + 1).strip_edges(false, true)
			if part.length() == 0:
				break
			bubbles.append(part)
			# Advance past punctuation and any following spaces
			var next_start := best_punct_pos + 1
			while next_start < remaining.length() and remaining[next_start] == " ":
				next_start += 1
			remaining = remaining.substr(next_start).strip_edges()
			continue

		# 2) Otherwise, fall back to word-boundary cut with ellipsis.
		var cut_limit: int = max_len - ell.length()
		if cut_limit <= 0:
			break

		var cut_pos: int = remaining.rfind(" ", cut_limit)
		if cut_pos == -1 or cut_pos == 0:
			# No space before limit; hard cut
			cut_pos = cut_limit

		var part2: String = remaining.substr(0, cut_pos).strip_edges(false, true)
		if part2.length() == 0:
			# Avoid empty segments; prevent infinite loop
			break

		bubbles.append(part2 + ell)
		# Advance past the cut (and the space, if any)
		var next_start2: int = cut_pos
		if cut_pos < remaining.length() and remaining[cut_pos] == " ":
			next_start2 += 1
		remaining = remaining.substr(next_start2).strip_edges()

	if remaining.length() > 0:
		bubbles.append(remaining)

	return bubbles


# Applies splitting to each dialogue line and flattens the result
func _preprocess_dialogue_array(dialogue_arr: Array, max_len: int = 84) -> Array:
	var result: Array = []
	for entry in dialogue_arr:
		if typeof(entry) == TYPE_STRING:
			var parts: Array = _split_text_to_bubbles(entry, max_len)
			for p in parts:
				result.append(p)
		else:
			# Preserve non-string entries as-is
			result.append(entry)
	return result
