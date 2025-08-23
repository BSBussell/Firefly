extends UiComponent
class_name DialogueUiComponent

# Child node for displaying the dialogue text
@onready var text_box: RichTextLabel = $Label
@onready var animation_player = $AnimationPlayer
@onready var animated_sprite_2d = $SpriteAnchor/AnimatedSprite2D
@onready var hoverAnim = $SpriteAnchor/hoverAnim

var current_dialogue
var current_dialogue_arr: Array
var current_loc: int = 0
var dialogue_up: bool = false

# Called when the node enters the scene tree
func _ready() -> void:
	
	# Initially hide the dialogue box
	animation_player.play("hide_bubble")
	
	# Disable process loop while hidden
	set_process(false)
	

## Connect Dialogue Signals to the Components Functions
func connect_to_func(init_sig: Signal, end_sig: Signal):
	
	# Connect the provided signals to their functions
	init_sig.connect(Callable(self, "initiate_dialogue"))
	end_sig.connect(Callable(self, "finish_dialogue"))

# Only enabled while the textbox is visible
func _process(_delta):
	if text_box.visible and (Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("Jump")):
		
		current_loc += 1
		if current_loc >= current_dialogue_arr.size():
			finish_dialogue()
		else:
			next_dialogue()




# Initiates Dialogue by setting text_bo
func initiate_dialogue(text: Dictionary, repeat: bool) -> void:
	
	dialogue_up = true
	
	current_dialogue = text
	current_dialogue_arr = text["dialogue"]
	current_loc = 0
	
	if _config.get_setting("pause_on_interact"):
		get_tree().paused = true
	
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
	
	get_tree().paused = false
	
	# For smoother visuals replace with animation
	hoverAnim.stop()
	animation_player.play("wipe_text")
	
	# Disable Process Loop for efficiency
	set_process(false)
	
	animation_player.play("hide_bubble")
	
	if current_dialogue["victory_dialogue"]:
		context.emit_win_signal()


# Just a wrapper to make adding the centers ez
func set_text(text: String):
	
	text = "[center]" + text + "[/center]"
	text_box.text = text
