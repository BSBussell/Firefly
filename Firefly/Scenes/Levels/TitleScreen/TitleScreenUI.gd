extends UiComponent
class_name TitleScreenUI

@export var start_level: PackedScene
@export var File_Select: FileSelectScene

@onready var animation_player = $AnimationPlayer
@onready var settings = $ItemsContainer/Settings
@onready var resume = $ItemsContainer/Start
@onready var quit = $ItemsContainer/Quit

# Called when the node enters the scene tree for the first time.
func _ready():
	
	
	resume.release_focus()
	animation_player.play("RESET")
	
	# Show Mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if _loader.connect("finished_loading", Callable(self, "on_load")) != OK:
		print("Error Failed to Connect On Load Signal. IDEK what to do in this case")
		
	
	


func _on_settings_pressed():
	animation_player.play("settings_in")


func _on_settings_sub_menu_settings_closed():
	animation_player.play("settings_out")
	
	await animation_player.animation_finished
	settings.grab_focus()


func _on_start_pressed():
	resume.disabled = true
	animation_player.play("StartGame")
	resume.release_focus()
	await animation_player.animation_finished
	resume.disabled = false
	File_Select.load_in()


func _on_quit_pressed():
	animation_player.play("StartGame")
	await animation_player.animation_finished
	
	# Ik, it just feels better with a pause
	await get_tree().create_timer(1.0).timeout  
	get_tree().quit()

func on_load():
	await get_tree().create_timer(1).timeout
	animation_player.play("on_load")
	
	# Grab its focus
	await animation_player.animation_finished
	resume.silence()
	resume.grab_focus()
	


func _on_file_select_closing():
	animation_player.play("FileSelectCancel")
	await animation_player.animation_finished
	resume.grab_focus()

