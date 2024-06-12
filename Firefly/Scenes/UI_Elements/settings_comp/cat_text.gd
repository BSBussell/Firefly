extends Button
class_name SettingCategory

## The dictionary of settings
var setting_category: Dictionary = {}
var setting_list: SettingsMenu

## For use in focus
var prev: Button
var next: Button

# Called when the node enters the scene tree for the first time.
func _ready():
	#if setting_category["id"] == 0:
		#self.grab_focus()
	pass
	

func setup_category(dict: Dictionary, list: SettingsMenu):
	
	setting_category = dict
	setting_list = list
	
	text = setting_category["text"]

func _on_focus_entered():
	setting_list.populate_setting(setting_category["items"], self)
	
	add_theme_color_override("font_color", "deb53a")
	add_theme_font_size_override("font_size", 57)
