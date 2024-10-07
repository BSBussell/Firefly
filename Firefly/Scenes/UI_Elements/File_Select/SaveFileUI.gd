extends PanelContainer
class_name FILE_UI

@export var file_label: Label

@export var save_info: HBoxContainer
@export var jar_counter: Label
@export var time_string: Label

@export var file_buttons: PanelContainer

var save_file: String
var new_file: bool = false

var focused: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	set_process(false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if user_pressed():
		
		if not new_file:
			show_buttons()
		else:
			set_file(_persist.new_file())
			new_file = false
			
		

func set_file(path: String) -> void:
	
	# Meta Info
	save_file = path
	
	# Load in save info
	_persist.get_save_values(path)
	
	
	
	# Visual Setup
	
	# Make labels visible
	save_info.visible = true
	
	# Set Label Text
	file_label.text = "File " + path.left(path.length() - 5).capitalize()
	
	var nabbed_jars: int = _jar_tracker.num_found_jars()
	var regged_jars: int = _jar_tracker.num_known_jars()
	
	jar_counter.text = "%d/%d" % [nabbed_jars, regged_jars]
	time_string.text = _stats.get_timer_string("HH:MM:SS")
	
	
func set_new() -> void:
	
	# Meta Info
	save_file = ""
	new_file = true
	
	# Visual Setup
	file_label.text = "New File"
	save_info.visible = false
	


func _on_focus_entered() -> void:
	set_process(true)
	print("Focus Entered")
	
	


func _on_focus_exited() -> void:
	#pass
	set_process(false)
	
	hide_buttons()
	
func user_pressed() -> bool:
	return Input.is_action_pressed("ui_accept")


func show_buttons() -> void:
	
		
	file_buttons.visible = true
	
func hide_buttons() -> void:
	
	
	# Show Buttons
	file_buttons.visible = false


func _on_start_button_pressed():
	
	_persist.load_save(save_file)
	_loader.load_level(_stats.CURRENT_LEVEL)


