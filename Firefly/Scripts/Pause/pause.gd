extends UiComponent
class_name PauseMenu

# AnimationPlayer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Settings Container
@onready var settings_container = $VBoxContainer/Items/Top/Settings/SettingsContainer

# Buttons
@onready var resume_button = $VBoxContainer/Items/Top/ResumeButton
@onready var mixer_setting = $VBoxContainer/Items/Top/Settings/SettingsContainer/AudioSettingContainer/MixerSetting

# Toggle
@onready var fullScreen_toggle: AnimatedToggle = $VBoxContainer/Items/Top/Settings/SettingsContainer/FullScreenContainer/FullScreenToggle
@onready var speedometer_toggle: AnimatedToggle = $VBoxContainer/Items/Top/Settings/SettingsContainer/Speedometer/speedometerToggle
@onready var glow_mode_toggle: AnimatedToggle = $VBoxContainer/Items/Top/Settings/SettingsContainer/GlowModeContainer/GlowModeToggle
@onready var timer_toggle: AnimatedToggle = $VBoxContainer/Items/Top/Settings/SettingsContainer/ShowTimer/timerToggle

# Sliders
@onready var music_slider = $VBoxContainer/Items/Top/Settings/SettingsContainer/AudioSettingContainer/MixerSetting/Music/MusicSlider
@onready var sfx_slider = $VBoxContainer/Items/Top/Settings/SettingsContainer/AudioSettingContainer/MixerSetting/SFX/SFXSlider
@onready var ambience_slider = $VBoxContainer/Items/Top/Settings/SettingsContainer/AudioSettingContainer/MixerSetting/Ambience/AmbienceSlider

@onready var menu = $"."

var paused: bool = false

var counter: JarCounter = null
var game_timer: GameTimer = null
var result_screen: VictoryScreen = null

func _ready():
	
	self.visible = false

	counter = get_dependency("JarCounter", false)
	result_screen = get_dependency("VictoryScreen", false)
	game_timer = get_dependency("GameTimer", true)

	load_configs()

	# Calculate screen size
	var render_size = DisplayServer.window_get_size()

	# Divide Screen size by 15
	var triangle_size: int = render_size.x 


	# Get the shader material attached to the ColorRect
	print(triangle_size)
	var color_rect: ColorRect = $"."
	color_rect.material.set("shader_parameter/diamondPixelSize", triangle_size)


func define_dependencies() -> void:
	
	define_dependency("JarCounter", counter)
	define_dependency("VictoryScreen", result_screen)
	define_dependency("GameTimer", game_timer)


func load_configs():

	# Full Screen Check
	if _config.get_setting("fullscreen"):
		fullScreen_toggle.toggle_on()
	else:
		fullScreen_toggle.toggle_off()

	# Speedometer Check
	if _config.get_setting("show_speedometer"):
		speedometer_toggle.toggle_on()
	else:
		speedometer_toggle.toggle_off()
	
	# Glow Mode Check
	if _config.get_setting("auto_glow"):
		glow_mode_toggle.toggle_on()
	else:
		glow_mode_toggle.toggle_off()


	# Speedrun timer check
	if _config.get_setting("show_timer"):

		timer_toggle.toggle_on()
		game_timer.show_timer()
	else:
		timer_toggle.toggle_off()
		game_timer.hide_timer()


	# Music Slider
	var mixer_settings: Dictionary = _config.get_setting("mixer_settings")

	if mixer_settings:
		music_slider.value = (mixer_settings["music"] + 10) / 20
		sfx_slider.value = (mixer_settings["sfx"] + 10) / 20
		ambience_slider.value = (mixer_settings["ambience"] + 10) / 20

		# Set the volume
		AudioServer.set_bus_volume_db(1, mixer_settings["music"])
		AudioServer.set_bus_volume_db(2, mixer_settings["ambience"])
		AudioServer.set_bus_volume_db(3, mixer_settings["sfx"])

		# Mute if appropriate
		if mixer_settings["music"] == -10:
			AudioServer.set_bus_mute(1, true)
		if mixer_settings["ambience"] == -10:
			AudioServer.set_bus_mute(2, true)
		if mixer_settings["sfx"] == -10:
			AudioServer.set_bus_mute(3, true)


func _input(event):
	
	# Handle Pausing
	if Input.is_action_just_pressed("Pause"):
		toggle_pause()

func toggle_pause():
	
	# If there is another ui element up
	if conflict():
		print("can't pause")
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
	
	# Set resume button to be out focus
	resume_button.grab_focus()
	
	# Set paused to true
	get_tree().paused = true
	
	# Set flag
	paused = true
	
	# If there is a counter to display, display it:
	if counter:
		counter.show_counter()
	
	
	
func unpause():
	
	# Hide mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	# Hide menu
	animation_player.play("load_out")
	
	# Unpause engine
	get_tree().paused = false
	
	# Remove focus from pause menu
	resume_button.grab_focus()
	resume_button.release_focus()

	# Set flag
	paused = false
	
	# If there is a counter to display, hide it:
	if counter:
		counter.hide_counter(0.1)

# Returns true if another ui element is up
func conflict() -> bool:
	
	if result_screen and result_screen.displayed:
		return true
	
	return false

#Expands a VBoxContainer vertically from a minimal height to its full height
func expand_container(container: VBoxContainer, final_height: float = 0, duration: float = 1.0, easing = Tween.EASE_OUT):
	# Ensure the container is visible
	container.visible = true

	# Set the initial minimal height (you can adjust this according to your needs)
	container.size.y = 0

	# Calculate the final height based on the container's content or an explicitly given value
	final_height = final_height if final_height != 0 else container.get_combined_minimum_size().y

	# Create a new tween
	var tween = get_tree().create_tween()

	# Tween the 'margin_bottom' to animate the height change
	var initial_margin_bottom = container.margin_bottom
	var target_margin_bottom = initial_margin_bottom - final_height

	# Setup the tween animation
	tween.tween_property(container, "margin_bottom", target_margin_bottom, duration).set_ease(easing)

	# Start the tween
	tween.play()




func _on_resume_button_pressed():
	unpause()

# Reveal Settings Hierarchy
func _on_settings_button_pressed():
	print("settings")
	animation_player.play("show_settings")
	# if not settings_container.visible:
	# 	settings_container.visible = true
		
	# else:
	# 	settings_container.visible = false



	

## Fullscreen Enabled
func _on_full_screen_toggle_switched_on():
	_config.set_setting("fullscreen", true)
	_config.save_settings()
	_viewports.viewer.set_fullscreen_scale()
	
	

## Fullscreen disabled
func _on_full_screen_toggle_switched_off():
	_config.set_setting("fullscreen", false)
	_config.save_settings()
	_viewports.viewer.set_windowed_scale()
	
	
	
# Reveal Audio Hierarchy
func _on_audio_pressed():
	mixer_setting.visible = not mixer_setting.visible





func _on_quit_button_pressed():
	_config.save_settings()
	get_tree().quit()


var min_vol = -10
var max_vol = 10
func set_bus_vol(bus: int, volume: float):
	
	var adjusted_val = min_vol + ((max_vol - min_vol ) * volume)
	
	# Let them mute it lol
	if adjusted_val == min_vol:
		AudioServer.set_bus_mute(bus, true)
	else:
		AudioServer.set_bus_mute(bus, false)
		
	AudioServer.set_bus_volume_db(bus, adjusted_val)
	
	# Save the settings
	var mixer_settings: Dictionary = _config.get_setting("mixer_settings")
	
	if not mixer_settings:
		mixer_settings = {
			"music": 0,
			"ambience": 0,
			"sfx": 0
		}
	
	mixer_settings["music"] = AudioServer.get_bus_volume_db(1)
	mixer_settings["ambience"] = AudioServer.get_bus_volume_db(2)
	mixer_settings["sfx"] = AudioServer.get_bus_volume_db(3)
	
	_config.set_setting("mixer_settings", mixer_settings)
	_config.save_settings()






func _on_music_slider_focus_entered():
	if not mixer_setting.visible:
		mixer_setting.visible = true
		


func _on_ambience_slider_focus_entered():
	if not mixer_setting.visible:
		mixer_setting.visible = true


func _on_glow_mode_toggle_switched_on():
	
	_config.set_setting("auto_glow", true)
	_config.save_settings()

	if _globals.ACTIVE_PLAYER:
		_globals.ACTIVE_PLAYER.enable_auto_glow()


func _on_glow_mode_toggle_switched_off():

	_config.set_setting("auto_glow", false)
	_config.save_settings()

	if _globals.ACTIVE_PLAYER:
		_globals.ACTIVE_PLAYER.disable_auto_glow()


func _on_speedometer_toggle_switched_off():
	
	_config.set_setting("show_speedometer", false)
	_config.save_settings()

	if _globals.ACTIVE_PLAYER:

		

		_globals.ACTIVE_PLAYER.hide_speedometer()


func _on_speedometer_toggle_switched_on():

	_config.set_setting("show_speedometer", true)
	_config.save_settings()

	if _globals.ACTIVE_PLAYER:

		

		_globals.ACTIVE_PLAYER.show_speedometer()


func _on_music_slider_value_changed(value):
	set_bus_vol(1, value)


func _on_sfx_slider_value_changed(value):
	set_bus_vol(3, value)


func _on_ambience_slider_value_changed(value):
	set_bus_vol(2, value)



func _on_timer_toggle_switched_on():
	game_timer.show_timer()
	_config.set_setting("show_timer", true)
	_config.save_settings()

func _on_timer_toggle_switched_off():
	game_timer.hide_timer()
	_config.set_setting("show_timer", false)
	_config.save_settings()
