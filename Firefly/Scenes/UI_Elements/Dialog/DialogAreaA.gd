extends CameraTarget
class_name DialogueArea2D

# Export variable for the Level node
@export var level: Level
@export var dialogue: DialogueData
@export var talk_target: Marker2D

@onready var hover = $hover
@onready var sprite_center = $SpriteCenter



# Signal to send display text to the DialogueUiComponent
signal initiate_dialogue(text: DialogueData, repeat: bool)
signal finish_dialogue()

var in_dialogue: bool = false

var dialogue_ui: DialogueUiComponent

func _ready():
	
	# Included to fix the context  I did not provide
	await _loader.finished_loading
	
	if talk_target:
		sprite_center.position = talk_target.position
	
	# Get the dialogue_ui
	dialogue_ui = level.get_ui_component("DialogueUiComponent")
	
	
	if dialogue_ui:
		dialogue_ui.connect_to_func(initiate_dialogue, finish_dialogue)
	else:
		printerr("DialogueUiComponent not found in Level!")
		
	level.PLAYER.dead.connect(Callable(self, "_stop_dialogue"))
		
	# Disable the Process Loop until Player Enters the Area
	set_process(false)
	
## Event Function when Body Enters DialogueArea
func _on_body_entered(body: Node2D) -> void:
	if body as Flyph:
		
		# Enable the Process Loop
		set_process(true)
		
		hover.play("reveal")
		await hover.animation_finished
		hover.play("hover")

## Event Function when Body Exits DialogueArea
func _on_body_exited(body: Node2D) -> void:
	if body as Flyph:
		
		# Disable the Process Loop
		set_process(false)
		
		# Call the Stop Dialogue Method
		_stop_dialogue()
		
		hover.play("hide")

## The Process Loop, only running when the player enters
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
		
		if dialogue_ui.dialogue_up: return
		
		# Start Displaying Dialogue
		_start_dialogue()

##Emits the Stop Dialogue signal to be listened to by the Dialogue Component
func _start_dialogue() -> void:
	
	in_dialogue = true
	
	# Get the DialogueUiComponent from the Level
	emit_signal("initiate_dialogue", dialogue, false)
	
	
	
## Emits the Stop Dialogue signal to be listened to by the Dialogue Component
func _stop_dialogue() -> void:
	
	in_dialogue = false
	
	# Signal to the DialogueUiComponent to end Dialogue
	emit_signal("finish_dialogue")
