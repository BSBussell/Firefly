extends BaseSetting
class_name BoolSetting

@onready var label: Label = $SettingName
@onready var h_slider: HSlider = $HSlider


@onready var focus = $Focus


#"Volume": {
#     "label": "Volume",
#     "description": "Control the Volume of the game",
#     "type": "Slider",
#     "config_key": "master_vol",
#	  "min": 0,
#	  "max": 10,
#	  "step": 1
# },

func setup_element():
	
	set_thickness(h_slider.get_theme_constant("thickness", "HSlider"))
	
	label.text = setting_json["label"]
	
	# Set the toggle tooltip
	self.set_tooltip_text(setting_json["description"])
	h_slider.set_tooltip_text(setting_json["description"])
	
	var slider_val: Variant = _config.get_setting(setting_json["config_key"])

	h_slider.min_value = setting_json["min"]
	h_slider.max_value = setting_json["max"]
	h_slider.step = setting_json["step"]

	# Set the toggle state
	h_slider.value = slider_val
	print(h_slider.value)
	
	


# Handle the setting being toggled on
func _on_animated_toggle_switched_on():

	if setting_json:
		_config.set_setting(setting_json["config_key"], true)



func set_above_focus(above: Control):
	if h_slider:
		h_slider.focus_neighbor_top = above.get_path()
	

func set_below_focus(below: Control):
	if below:
		h_slider.focus_neighbor_bottom = below.get_path()
	else:
		h_slider.focus_neighbor_bottom = " "
	

func set_left_focus(left: Control):
	h_slider.focus_neighbor_left = left.get_path()
	

func set_right_focus(right: Control):
	h_slider.focus_neighbor_right = right.get_path()
	

func get_focus_obj() -> Control:
	return h_slider

func _on_h_slider_value_changed(value):
	if setting_json:
		_config.set_setting(setting_json["config_key"], value)


func _on_h_slider_focus_entered():
	focus.play(0.0)
	set_thickness(h_slider.get_theme_constant("focused_thickness", "HSlider"))


func _on_h_slider_focus_exited():
	set_thickness(h_slider.get_theme_constant("thickness", "HSlider"))
	
func set_thickness(thickness: int):
	h_slider.remove_theme_stylebox_override("slider")
	var style_box: StyleBoxLine = h_slider.get_theme_stylebox("slider").duplicate()
	style_box.set("thickness", thickness)
	h_slider.add_theme_stylebox_override("slider", style_box)
	
