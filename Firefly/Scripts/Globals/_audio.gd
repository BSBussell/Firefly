extends Node


var current_level_fx: Array

func _ready():
	# Music Slider
	var mixer_settings: Dictionary = _config.get_setting("mixer_settings")

	if mixer_settings:
		
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

## Set the fx_id's for the active effects for this level
func set_level_effects(fx_idx: Array):
	disable_level_effects()
	current_level_fx = fx_idx
	enable_level_effects()
	
## Enables the levels audio effects
func enable_level_effects():
	
	var bus_idx = AudioServer.get_bus_index("Master")
	for fx_idx in current_level_fx:
		AudioServer.set_bus_effect_enabled(bus_idx, fx_idx, true)
	
## Disables the levels audio effects
func disable_level_effects():
	var bus_idx = AudioServer.get_bus_index("Master")
	for fx_idx in current_level_fx:
		AudioServer.set_bus_effect_enabled(bus_idx, fx_idx, false)
	
	
func enable_underwater_fx():
	var bus_idx = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_effect_enabled(bus_idx, 1, true)
	AudioServer.set_bus_effect_enabled(bus_idx, 2, true)
	disable_level_effects()

	
func disable_underwater_fx():
	var bus_idx = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_effect_enabled(bus_idx, 1, false)
	AudioServer.set_bus_effect_enabled(bus_idx, 2, false)
	enable_level_effects()


