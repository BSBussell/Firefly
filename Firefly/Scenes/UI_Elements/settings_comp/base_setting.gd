extends Control
class_name BaseSetting


## The dictionary of information for this setting
var setting_json = {}



# Called when the node enters the scene tree for the first time.
func _ready():
	if setting_json:
		setup_element()



## Pass the JSON to the component
func pass_json(json):
	setting_json = json

## At this point we assume you have setting_json to work with
func setup_element():
	pass

## Connects the components above focus to the control
func set_above_focus(_above: Control):
	pass

## Connects the components below focus to the control
func set_below_focus(_below: Control):
	pass

## Connects the components left focus to the control
func set_left_focus(_left: Control):
	pass

## Connects the components right focus to the control
func set_right_focus(_right: Control):
	pass

## Returns the object that would be focused on
func get_focus_obj() -> Control:
	return self
