extends Button
class_name PauseButton

@export var disable_press_sfx: bool = false
@export var disable_focus_sfx: bool = false

@export var focus: AudioStreamPlayer
@export var press: AudioStreamPlayer

var silenced: bool = false



func silence():
	silenced = true

func _on_pressed():
	
	if disable_press_sfx:
		return
	
	if not silenced and press:
		press.play(0.0)
	else:
		silenced = false


func _on_focus_entered():
	
	if disable_focus_sfx:
		return
	
	if not silenced and focus:  
		focus.play(0)
	else:
		silenced = false

