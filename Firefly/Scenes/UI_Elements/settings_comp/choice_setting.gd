extends BaseSetting
class_name ChoiceSetting

@onready var label: Label = $SettingName

@onready var left = $Control/Left
@onready var select: Button = $Control/Selected
@onready var right = $Control/Right


@onready var focus = $Focus

var selected: int = 0
var options: Array = []
var option_text: String = "options[option_select]"


#"Resolution Scale": {
#     "label": "Resolution",
#     "description": "Select your resolution",
#     "type": "Choice",
#     "config_key": "resolution",
#	  "options": ["1x", "2x", "3x", "4x", "5x", "6x"]
# },

func setup_element():
	
	label.text = setting_json["label"]
	
	# Set the toggle tooltip
	self.set_tooltip_text(setting_json["description"])
	#h_slider.set_tooltip_text(setting_json["description"])
	
	# Set the values
	selected = _config.get_setting(setting_json["config_key"])
	options = setting_json["options"]
	option_text = options[selected]


	# Set the toggle state
	select.text = option_text
	
	update_display()
	
		

func set_above_focus(above: Control):
	if select:
		select.focus_neighbor_top = above.get_path()
	

func set_below_focus(below: Control):
	if below:
		select.focus_neighbor_bottom = below.get_path()
	else:
		select.focus_neighbor_bottom = " "
	


func set_left_focus(left: Control):
	select.focus_neighbor_left = select.get_path()
	

func set_right_focus(right: Control):
	select.focus_neighbor_right = select.get_path()
	

func get_focus_obj() -> Control:
	return select


var focused: bool = false
func _on_selected_focus_entered():
	focused = true
	
	focus_effects()
	
	
func _on_selected_focus_exited():
	focused = false
	
func _input(event):
	
	# Only parse inputs if we're focused
	if not focused:
		return
	if event.is_action_pressed("ui_left"):
		move_left()
		save()
	elif event.is_action_pressed("ui_right"):
		move_right()
		save()


func move_left():
	
	selected = max(selected - 1, 0)
	update_display()
	
	focus_effects()

func move_right():
	
	selected = min(selected + 1, options.size()-1)
	update_display()
	
	focus_effects()
	
		
## Updates the visuals using selected index
func update_display():
	if selected == 0:
		left.text = " "
		left.disabled = true
		
		right.text = ">"
		right.disabled = false
	elif selected >= options.size()-1:
		left.text = "<"
		left.disabled = false
		
		right.text = " "
		right.disabled = true
	else:
		left.text = "<"
		left.disabled = false
		
		right.text = ">"
		right.disabled = false
		
	select.text = options[selected]
	
	
## Save the config
func save():
	_config.set_setting(setting_json["config_key"], selected)  


func _on_right_pressed():
	move_right()
	save()
	
	select.grab_focus()


func _on_left_pressed():
	move_left()
	save()
	
	select.grab_focus()


## SFX and VFX on focus
func focus_effects():
	focus.play()

## SFX and VFX on press	
func press_effects():
	focus.play()
