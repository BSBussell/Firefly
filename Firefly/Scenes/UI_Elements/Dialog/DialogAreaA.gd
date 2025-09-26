extends CameraTarget
class_name DialogueArea2D

# Export variable for the Level node
@export var level: Level
@export_file("*.json") var dialogue_file: String
@export var talk_target: Marker2D

@onready var hover = $hover
@onready var sprite_center = $SpriteCenter



# Signal to send display text to the DialogueUiComponent
signal initiate_dialogue(text: DialogueData, repeat: bool)
signal finish_dialogue()

var dialogue_data: Dictionary = {}
var in_dialogue: bool = false
var dialogue_ui: DialogueUiComponent

func _ready():
	super._ready()
	
	# Included to fix the context  I did not provide
	await _loader.finished_loading
	
	if talk_target:
		sprite_center.position = talk_target.position
	else:
		sprite_center.position = self.position
	
	# Get the dialogue_ui
	if level:
		dialogue_ui = level.get_ui_component("DialogueUiComponent")
	else:
		printerr("YOU FORGOT TO ASSIGN A LEVEL TO THE DIALOG THING NERRDDD")
		return
	
	
	if dialogue_ui:
		dialogue_ui.connect_to_func(initiate_dialogue, finish_dialogue)
		# Also listen for when the UI fully closes so we can finish immediately
		if not dialogue_ui.dialogue_closed.is_connected(Callable(self, "_on_ui_dialogue_closed")):
			dialogue_ui.dialogue_closed.connect(Callable(self, "_on_ui_dialogue_closed"))
	else:
		printerr("DialogueUiComponent not found in Level!")
		
	level.PLAYER.dead.connect(Callable(self, "_stop_dialogue"))
	
	load_file()
		
	# Disable the Process Loop until Player Enters the Area
	set_process(false)
	
	
func load_file() -> void:
	if dialogue_file:
		var file = FileAccess.open(dialogue_file, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			
			# Parsing the STR
			dialogue_data = JSON.parse_string(json_string)
			if not dialogue_data:
				printerr("Error: Could not read " + str(json_string) + " as JSON")
		else:
			printerr("Error: Could not open file: " + str(dialogue_file))
	
## Event Function when Body Enters DialogueArea
func _on_body_entered(body: Node2D) -> void:
	if body as Flyph:
		
		if body.is_actor:
			return
		
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
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"interact"):
		
		if dialogue_ui.dialogue_up: return
		
		# Start Displaying Dialogue
		_start_dialogue()

##Emits the Stop Dialogue signal to be listened to by the Dialogue Component
func _start_dialogue() -> void:
	
	in_dialogue = true
	
	# Get the DialogueUiComponent from the Level
	emit_signal("initiate_dialogue", dialogue_data, false)
	
	
	
## Emits the Stop Dialogue signal to be listened to by the Dialogue Component
func _stop_dialogue() -> void:
	
	if in_dialogue:
		# Signal to the DialogueUiComponent to end Dialogue
		emit_signal("finish_dialogue")
		
		in_dialogue = false

	
		
	

## Called when the Dialogue UI reports it has closed naturally
func _on_ui_dialogue_closed() -> void:
	
	# Only care for the signal if we're in this dialogue
	if in_dialogue == false:
		return

	# If "sequsequential_dialogue" isn't an empty string, load that file now
	if dialogue_data.has("sequential_dialogue"):
		var next_file: String = dialogue_data["sequential_dialogue"]
		if next_file != "":
			dialogue_file = next_file
			load_file()

	# Mirror the same behavior as exiting the area: end dialogue once
	_stop_dialogue()
