extends Node


@onready var resume_button = $VBoxContainer/Items/Top/ResumeButton

@onready var settings_container = $VBoxContainer/Items/Top/Settings/SettingsContainer

@onready var mixer_setting = $VBoxContainer/Items/Top/Settings/SettingsContainer/AudioSettingContainer/MixerSetting

# Sliders
@onready var music_slider = $VBoxContainer/Items/Top/Settings/SettingsContainer/AudioSettingContainer/MixerSetting/Music/MusicSlider
@onready var sfx_slider = $VBoxContainer/Items/Top/Settings/SettingsContainer/AudioSettingContainer/MixerSetting/SFX/SFXSlider
@onready var ambience_slider = $VBoxContainer/Items/Top/Settings/SettingsContainer/AudioSettingContainer/MixerSetting/Ambience/AmbienceSlider


@onready var menu = $"."

var paused: bool = false

func _ready():
	$VBoxContainer/Items/Top/ResumeButton.grab_focus()

func toggle_pause():
	if paused:
		unpause()
	else:
		pause()

func pause():
	
	# Make the menu visible
	menu.visible = true
	
	# Set resume button to be out focus
	resume_button.grab_focus()
	
	# Set paused to true
	get_tree().paused = true
	
	# Set flag
	paused = true
	
	
	
func unpause():
	
	
	# Hide menu
	menu.visible = false
	
	# Unpause engine
	get_tree().paused = false
	
	# Set flag
	paused = false

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
	if not settings_container.visible:
		settings_container.visible = true
		#expand_container(settings_container)
	else:
		settings_container.visible = false
	#settings_container.visible = not settings_container.visible



	

## Fullscreen Enabled
func _on_full_screen_toggle_switched_on():
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	

## Fullscreen disabled
func _on_full_screen_toggle_switched_off():
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	
	
# Reveal Audio Hierarchy
func _on_audio_pressed():
	mixer_setting.visible = not mixer_setting.visible





func _on_quit_button_pressed():
	get_tree().quit()


var min_vol = -10
var max_vol = 10
func _on_music_slider_drag_ended(value_changed):
	if value_changed:
		var adjusted_val = min_vol + ((max_vol - min_vol ) * music_slider.value)
		
		# Let them mute it lol
		if adjusted_val == min_vol:
			AudioServer.set_bus_mute(1, true)
		else:
			AudioServer.set_bus_mute(1, false)
		AudioServer.set_bus_volume_db(1, adjusted_val)
		
	
func _on_ambience_slider_drag_ended(value_changed):
	if value_changed:
		var adjusted_val = min_vol + ((max_vol - min_vol ) * ambience_slider.value)
		
		# Let them mute it lol
		if adjusted_val == min_vol:
			AudioServer.set_bus_mute(2, true)
		else:
			AudioServer.set_bus_mute(2, false)
		AudioServer.set_bus_volume_db(2, adjusted_val)

func _on_sfx_slider_drag_ended(value_changed):
	if value_changed:
		var adjusted_val = min_vol + ((max_vol - min_vol ) * sfx_slider.value)
		
		# Let them mute it lol
		if adjusted_val == min_vol:
			AudioServer.set_bus_mute(3, true)
		else:
			AudioServer.set_bus_mute(3, false)
			
		AudioServer.set_bus_volume_db(3, adjusted_val)





func _on_music_slider_focus_entered():
	if not mixer_setting.visible:
		mixer_setting.visible = true
		


func _on_ambience_slider_focus_entered():
	if not mixer_setting.visible:
		mixer_setting.visible = true


func _on_glow_mode_toggle_switched_on():
	
	if _globals.ACTIVE_PLAYER:
		_globals.ACTIVE_PLAYER.enable_auto_glow()


func _on_glow_mode_toggle_switched_off():
	if _globals.ACTIVE_PLAYER:
		_globals.ACTIVE_PLAYER.disable_auto_glow()


func _on_speedometer_toggle_switched_off():
	
	if _globals.ACTIVE_PLAYER:
		_globals.ACTIVE_PLAYER.hide_speedometer()


func _on_speedometer_toggle_switched_on():
	if _globals.ACTIVE_PLAYER:
		_globals.ACTIVE_PLAYER.show_speedometer()
