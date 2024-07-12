extends UiComponent
class_name DialogueUiComponent

# Child node for displaying the dialogue text
@onready var text_box: Label = $Label

# Called when the node enters the scene tree
func _ready() -> void:
	
	# Initially hide the dialogue box
	text_box.hide()
	
	# Disable process loop while hidden
	set_process(false)

# Only enabled while the textbox is visible
func _process(delta):
	if text_box.visible and Input.is_action_just_pressed("interact"):
		finish_dialogue()

## Connect Dialogue Signals to the Components Functions
func connect_to_func(init_sig: Signal, end_sig: Signal):
	
	# Connect the provided signals to their functions
	init_sig.connect(Callable(self, "initiate_dialogue"))
	end_sig.connect(Callable(self, "finish_dialogue"))



# Initiates Dialogue by setting text_bo
func initiate_dialogue(text: String) -> void:
	
	
	# Set the dialogue text, for smoother visuals replace with animation
	text_box.text = text
	
	# Show the dialogue box
	text_box.show()
	
	# Enable Process Loop to look for button Presses
	set_process(true)


func finish_dialogue() -> void:
	
	# For smoother visuals replace with animation
	text_box.hide()
	
	# Disable Process Loop for efficiency
	set_process(false)
