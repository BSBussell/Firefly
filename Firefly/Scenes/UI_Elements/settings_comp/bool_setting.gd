extends BaseSetting
class_name SliderSetting

@onready var label: Label = $SettingName
@onready var animated_toggle: AnimatedToggle = $AnimatedToggle 



#"auto_glow": {
#     "label": "Auto Glow",
#     "description": "Automatically trigger glow while playing",
#     "type": "boolean",
#     "config_key": "auto_glow",
# },

func setup_element():
	
	label.text = setting_json["label"]
	
	# Set the toggle tooltip
	self.set_tooltip_text(setting_json["description"])
	animated_toggle.set_tooltip_text(setting_json["description"])

	# Set the toggle state
	if _config.get_setting(setting_json["config_key"]):
		animated_toggle.toggle_on()
	else:
		animated_toggle.toggle_off()

func pass_json(json):
	setting_json = json


# Handle the setting being toggled on
func _on_animated_toggle_switched_on():

	if setting_json:
		_config.set_setting(setting_json["config_key"], true)

# Handle the setting being toggled off
func _on_animated_toggle_switched_off():
	
	if setting_json:
		_config.set_setting(setting_json["config_key"], false)

func set_above_focus(above: Control):
	if animated_toggle:
		animated_toggle.focus_neighbor_top = above.get_path()
	

func set_below_focus(below: Control):
	if below:
		animated_toggle.focus_neighbor_bottom = below.get_path()
	else:
		animated_toggle.focus_neighbor_bottom = " "
	

func set_left_focus(left: Control):
	animated_toggle.focus_neighbor_left = left.get_path()
	

func set_right_focus(right: Control):
	animated_toggle.focus_neighbor_right = right.get_path()
	

func get_focus_obj() -> Control:
	return animated_toggle

	
