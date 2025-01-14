extends UiComponent
class_name PauseMenu

## Called when the user pauses the game
signal Paused

## Emitted when the user unpauses the game
signal Unpaused

# AnimationPlayer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Settings Container
@onready var settings_submenu = $SettingsSubMenu

# Buttons
@onready var resume_button = $VBoxContainer/Items/Top/ResumeButton


# Sliders
@onready var menu = $"."

var paused: bool = false

var base_counter: JarCounter = null
var counter: TotalJarCounter = null
var game_timer: GameTimer = null
var result_screen: VictoryScreen = null

func _ready():
	
	self.visible = false

	base_counter = get_dependency("JarCounter", false)
	counter = get_dependency("TotalJarCounter", false)
	result_screen = get_dependency("VictoryScreen", false)
	game_timer = get_dependency("GameTimer", true)

	# Calculate screen size
	var render_size = DisplayServer.window_get_size()

	# Divide Screen size by 15
	var triangle_size: int = render_size.x 


	# Get the shader material attached to the ColorRect
	var color_rect: ColorRect = $"."
	color_rect.material.set("shader_parameter/diamondPixelSize", triangle_size)
	
	animation_player.play("RESET")
	


func define_dependencies() -> void:
	
	define_dependency("JarCounter", base_counter)
	define_dependency("TotalJarCounter", counter)
	define_dependency("VictoryScreen", result_screen)
	define_dependency("GameTimer", game_timer)



func _input(_event):
	
	# Handle Pausing
	if Input.is_action_just_pressed("Pause"):
		toggle_pause()

func toggle_pause():
	
	# If there is another ui element up
	if conflict():
		print("Error, missing component can't pause")
		return
	
	# Hide settings
	if settings_submenu.settings_on_screen:
		settings_submenu.close_settings()
		return

	if paused:
		unpause()
	else:
		pause()
		

func pause():
	
	# Show mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Make the menu visible
	animation_player.play("load_in")
	
	
	# Set paused to true
	get_tree().paused = true
	
	# Set flag
	paused = true
	
	if base_counter:
		base_counter.hide_counter(0.1)
	
	# If there is a counter to display, display it:
	if counter:
		counter.show_counter()
		
	
	
	# Waiting for the animaiton to finish feels laggier 
	await get_tree().create_timer(0.1).timeout
	
	resume_button.silence()
	resume_button.grab_focus()
	
	#_audio.enable_underwater_fx()
	
	
func unpause():
	
	# Hide mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	# Hide menu
	animation_player.play("load_out")

	
	
	# Unpause engine
	get_tree().paused = false
	
	# Remove focus from pause menu
	resume_button.silence()
	resume_button.grab_focus()
	resume_button.release_focus()

	# Set flag
	paused = false
	
	# If there is a counter to display, hide it:
	if counter:
		counter.hide_counter(0.1)
		
	#if not _globals.ACTIVE_PLAYER.underWater:
		#_audio.disable_underwater_fx()

# Returns true if another ui element is up
func conflict() -> bool:
	
	if result_screen and result_screen.displayed:
		return true
	
	return false





func _on_resume_button_pressed():
	unpause()



func _on_settings_sub_menu_settings_closed():
	resume_button.grab_focus()
	animation_player.play("hide_settings")



func _on_settings_pressed():
	animation_player.play("show_settings")
	
	


func _on_quit_pressed():
	_config.save_settings()
	animation_player.play("quit")
	await animation_player.animation_finished
	_loader.return_to_title()    


func _on_title_screen_pressed():
	pass
