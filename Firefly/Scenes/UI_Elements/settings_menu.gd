extends Control

# Create settings close signal
# signal settings_opened
signal settings_closed

@onready var animationPlayer = $AnimationPlayer
@onready var backButton = $TopBar/BackButton
@onready var category_container = $TopBar/SettingCategories/CategoryContainer
@onready var setting_categories = $TopBar/SettingCategories



var settings_on_screen: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func show_settings():
	print("show settings")
	settings_on_screen = true
	animationPlayer.play("settings_in")

	category_container.base_category.grab_focus()
	setting_categories.scroll_horizontal = 0
	
  
func close_settings():
	print("close settings")
	settings_on_screen = false
	emit_signal("settings_closed")
	animationPlayer.play("settings_out")

# Back Button
func _on_button_pressed():
	close_settings()
