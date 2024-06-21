extends VBoxContainer
class_name SettingsMenu

# Preload individual components
var BOOL_TOGGLE: PackedScene = preload("res://Scenes/UI_Elements/settings_comp/bool_setting.tscn")
var SLIDER: PackedScene = preload("res://Scenes/UI_Elements/settings_comp/slider_setting.tscn")

@onready var animation_player = $"../../AnimationPlayer"

var current_setting: Control = null

# Called when the node enters the scene tree for the first time.
func _ready():
	
	
	## Open json file
	#var layout: Dictionary
	#var file: FileAccess = FileAccess.open("res://Assets/UI/settings_layout.json", FileAccess.READ)
	#if file:
		#var setting_layout: String = file.get_as_text()
		#var json: JSON = JSON.new()
		#var error: Error = json.parse(setting_layout)
		#if error == OK:
			#layout = json.data
		#file.close()
	pass

	#if layout:
		#populate_setting(layout["Game_Settings"])


# "auto_glow": {
#     "label": "Auto Glow",
#     "description": "Automatically trigger glow while playing",
#     "type": "boolean",
#     "config_key": "auto_glow",
# },

func clear_list():
	
	
	for children in get_children():
		children.queue_free()

func populate_setting(setting_list: Dictionary, current_cat: Button):

	if current_setting == current_cat:
		return

	# Free the
	var hide_settings: bool = false
	if get_child_count() > 0:
		
		hide_settings = true
		#animation_player.play("setting_hide")
		#await animation_player.animation_finished
		clear_list()
		
		
	if current_setting:
		current_setting.remove_theme_color_override("font_color")
		current_setting.remove_theme_font_size_override("font_size")
		
	current_setting = current_cat
	var prev: BaseSetting = null

	for setting in setting_list:

		var setting_node: BaseSetting

		if setting_list[setting]["type"] == "boolean":

			setting_node = BOOL_TOGGLE.instantiate()
			setting_node.pass_json(setting_list[setting])

			add_child(setting_node)
			print("Settting_Node")
			
		elif setting_list[setting]["type"] == "slider":
		
			setting_node = SLIDER.instantiate()
			setting_node.pass_json(setting_list[setting])

			add_child(setting_node)
			print("Settting_Node")
 
		# Configure up and down focus
		if prev:
			
			setting_node.set_above_focus(prev.get_focus_obj())
			prev.set_below_focus(setting_node.get_focus_obj())
			
		else:
			if setting_node:
				setting_node.set_above_focus(current_cat)
				current_cat.focus_neighbor_bottom = setting_node.get_focus_obj().get_path()
		
		# Configure left and right focus
		setting_node.set_left_focus(current_cat.prev)
		
		if current_cat.next:
			setting_node.set_right_focus(current_cat.next)
		
		prev = setting_node
		
	prev.set_below_focus(null)
		
	#if hide_settings:
		#animation_player.play("setting_reveal")
