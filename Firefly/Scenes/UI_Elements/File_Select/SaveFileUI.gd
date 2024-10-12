extends PanelContainer
class_name FILE_UI
# I deserve to be bullied for this. i am sorry

@export var file_label: Label

@export_category("Save Details")
@export var save_info: HBoxContainer
@export var jar_counter: Label
@export var time_string: Label

@export_category("New Save Details")
@export var name_entry: HBoxContainer
@export var name_field: LineEdit

@export_category("FileOptions")
@export var file_buttons: PanelContainer
@export var file_buttons_spacer: PanelContainer
@export var start_button: Button
@export var erase_button: Button

@export_category("SFXs")
@export var focused_audio: AudioStreamPlayer
@export var opened_audio: AudioStreamPlayer
@export var start_audio: AudioStreamPlayer

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var save_file: String
var assist_file : bool = false

var new_file: bool = false

var focused: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	set_process(false)
	set_pivot()
	connect_child_focus()
	
	start_button.focus_neighbor_top = focus_neighbor_top
	erase_button.focus_neighbor_bottom = focus_neighbor_bottom
	
var selected: bool = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if user_pressed() and not selected:
		open_file()
			
		
		
	
func open_file():
	
	selected = true
		
	opened_audio.play()
	
	if not new_file:
		show_buttons()
	else:
		show_name_entry()
		
func close_file():
	
	set_process(false)
		
	# If the user has selected the file deselect it and remove visuals
	if selected:
		selected = false
		
		if new_file:
			hide_name_entry()
		else:
			hide_buttons()
			
	remove_hover_stylebox()

func set_pivot() -> void:
	
	pivot_offset = size / 2.0	
	
func reset_pivot() -> void:
	
	pivot_offset = Vector2.ZERO		
		

func set_file(path: String) -> void:
	
	# Meta Info
	save_file = path
	
	# Load in save info
	_persist.get_save_values(path)
	
	assist_file = _stats.INVALID_RUN

	# Visual Setup
	animation_player.play("set_file")
	
	# Set Label Text
	file_label.text = path.left(path.length() - 5)
	
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
	
	print("Panel Focus Entered")
	
	set_label_focus()
	
	if not selected:
		
		set_hover_stylebox()
		focused_audio.play()
		
		set_process(true)
		
	
func _on_child_focus_entered() -> void:
	print("Child Focus Entered")
	return
	
func _on_focus_exited() -> void:
	
	await get_tree().create_timer(0.1).timeout
	print("Panel Focus Exited")
	
	
	remove_label_focus()
	
	
	# Otherwise check if any of the children are focused
	if not any_has_focus():
		
		
		# Fold the file back up hide buttons, etc
		close_file()
		
	
func _on_child_focus_exited() -> void:
	
	await get_tree().create_timer(0.1).timeout
	print("Child Focus Exited")
	
	
	# Check if any nodes are focused
	if not any_has_focus():
		
		# Fold the file back up hide buttons, etc if none are
		close_file()
		
	
	return	
	
func user_pressed() -> bool:
	var accept = Input.is_action_pressed("ui_accept")
	if accept:
		print(accept)
	return accept


func show_buttons() -> void:
	
	var reference_size: float = file_buttons_spacer.size.x
	if animation_player:
		animation_player.get_animation("showButtons").track_set_key_value(2, 1, reference_size)
	
	animation_player.play("showButtons")
	
	#start_button.grab_focus()
	
func hide_buttons() -> void:
	
	var reference_size: float = file_buttons_spacer.size.x
	
	if animation_player:
		animation_player.get_animation("hideButtons").track_set_key_value(2, 0, reference_size)
	
	# Show Buttons
	animation_player.play("hideButtons")

func show_name_entry() -> void:
	
	var reference_size = name_entry.size
	animation_player.get_animation("show_name").track_set_key_value(0,1, reference_size)
	
	animation_player.play("show_name")
	
	#name_field.grab_focus()
	
	
	
	
func hide_name_entry() -> void:
	var reference_size = name_entry.size
	animation_player.get_animation("hide_name").track_set_key_value(0,0, reference_size)
	
	animation_player.play("hide_name")


func _on_start_button_pressed():
	
	_persist.load_save(save_file)
	var container = get_parent() as SaveContainer
	container.start_game(_stats.CURRENT_LEVEL)
	
	start_audio.play()



## When the confim name button is pressed make a new file
func _on_confirm_name_pressed():
	
	var file_name = name_field.text
	set_file(_persist.new_file(file_name))
	new_file = false
	
	await animation_player.animation_finished
	grab_focus()
	open_file()
	



# When the erase button is pressed make it need to be double pressed to delete
var erase_check: bool = true
func _on_erase_button_pressed():
	
	if erase_check:
		
		erase_button.text = "Really?"
		erase_check = false
		
		await get_tree().create_timer(3.0).timeout
		
		erase_check = true
		erase_button.text = "Erase"
	else:
		animation_player.play("delete")
		_persist.delete_file(save_file)


	
# Ties all the childrens focus' to the main focus node
func connect_child_focus() -> void:
	
	var entered: Callable = Callable(self, "_on_child_focus_entered")
	var exited: Callable = Callable(self, "_on_child_focus_exited")
	
	for child in recur_get_children():
		child.connect("focus_entered", entered)
		child.connect("focus_exited", exited)
	
## Returns True if any child has focus
func any_has_focus() -> bool:
	
	if has_focus():
		return true
		
	return children_have_focus()

## Returns true if any children have focus		
func children_have_focus() -> bool:
	for child in recur_get_children():
		if child.has_focus():
			return true
	return false

# Recursively Grab all the children!
func recur_get_children(node: Control = self) -> Array:
	
	var children: Array = []
	for child in node.get_children():
		if child as Control:
			children.append(child)
			
			if child.get_child_count() > 0:
				children.append_array(recur_get_children(child))
	
	return children
	


func set_hover_stylebox():
	
	# Sets the theme stylebox
	var hover_stylebox: StyleBoxFlat 
	
	
	
	# Check if its a valid run
	if assist_file:
		hover_stylebox = get_theme_stylebox("debug_panel", "PanelContainer")
	else:
		hover_stylebox = get_theme_stylebox("focus_panel", "PanelContainer")
		
	add_theme_stylebox_override("panel", hover_stylebox)
	
	
func remove_hover_stylebox():
	
	# Remove the panel st
	remove_theme_stylebox_override("panel")
	
	

func set_label_focus():
	
	# Set Label Color on hover
	var label_hover: Color = Color("#d59d29")
	file_label.add_theme_color_override("font_color", label_hover)

func remove_label_focus():
	
	# Remove label color on hover
	file_label.remove_theme_color_override("font_color")
