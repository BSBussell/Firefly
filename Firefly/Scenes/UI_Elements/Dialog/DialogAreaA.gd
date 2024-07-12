extends Area2D
class_name DialogueArea2D

# Export variable for the Level node
@export var level: Level
@export var dialogue: String = "Text Goes Here!"

# Signal to send display text to the DialogueUiComponent
signal initiate_dialogue(text: String)
signal finish_dialogue()

func _ready():
	
	# Included to fix the context  I did not provide
	await _loader.finished_loading
	
	# Get the dialogue_ui
	var dialogue_ui: DialogueUiComponent = level.get_ui_component("DialogueUiComponent")
	
	if dialogue_ui:
		dialogue_ui.connect_to_func(initiate_dialogue, finish_dialogue)
	else:
		printerr("DialogueUiComponent not found in Level!")
		
	# Disable the Process Loop until Player Enters the Area
	set_process(false)
	
## Event Function when Body Enters DialogueArea
func _on_body_entered(body: Node2D) -> void:
	if body as Flyph:
		
		# Enable the Process Loop
		set_process(true)

## Event Function when Body Exits DialogueArea
func _on_body_exited(body: Node2D) -> void:
	if body as Flyph:
		
		# Disable the Process Loop
		set_process(false)
		
		# Call the Stop Dialogue Method
		_stop_dialogue()

## The Process Loop, only running when the player enters
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
		
		# Start Displaying Dialogue
		_start_dialogue()
		
		# Disable Double Calls, DialogueUiComponent handles from here
		set_process(false)

##Emits the Stop Dialogue signal to be listened to by the Dialogue Component
func _start_dialogue() -> void:
	
	# Get the DialogueUiComponent from the Level
	emit_signal("initiate_dialogue", dialogue)
	
## Emits the Stop Dialogue signal to be listened to by the Dialogue Component
func _stop_dialogue() -> void:
	
	# Signal to the DialogueUiComponent to end Dialogue
	emit_signal("finish_dialogue")
