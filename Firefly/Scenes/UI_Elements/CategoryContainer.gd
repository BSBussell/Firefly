extends Control

var CAT_BUTTON: PackedScene = preload("res://Scenes/UI_Elements/settings_comp/cat_text.tscn")
var DIVIDE: PackedScene = preload("res://Scenes/UI_Elements/settings_comp/divider.tscn")

@export var setting_list: SettingsMenu
@onready var back_button = $"../../BackButton"

var layout: Dictionary = {}
var base_category: SettingCategory

# Called when the node enters the scene tree for the first time.
func _ready():
	# Open json file
	var file: FileAccess = FileAccess.open("res://Assets/UI/settings_layout.json", FileAccess.READ)
	if file:
		var setting_layout: String = file.get_as_text()
		var json: JSON = JSON.new()
		var error: Error = json.parse(setting_layout)
		if error == OK:
			layout = json.data
		file.close()
	else:
		printerr("Your JSON IS BROKEN")
		
	populate_cats()


func populate_cats():
	
	var prev: Button = back_button
	
	for categories in layout:
		
		var category: SettingCategory = CAT_BUTTON.instantiate()
		var divider: Label = DIVIDE.instantiate()
		
		category.setup_category(layout[categories], setting_list)
		
		add_child(category)
		add_child(divider)
		
		if layout[categories]["id"] == 0:
			base_category = category
		
		category.prev = prev
		if prev as SettingCategory:
			prev.next = category
		
		prev.focus_neighbor_right = category.get_path()
		category.focus_neighbor_left = prev.get_path()
		
		prev = category
		
	
	  
