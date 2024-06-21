extends Node


var current_level_fx: Array

func _ready():
	update_sliders()
	
	# Update sliders when config is changed
	_config.connect_to_config_changed(Callable(self, "update_sliders"))

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


func update_sliders():
	# Music Slider
	var master: float = _config.get_setting("master_vol")
	var music: float = _config.get_setting("music")
	var sfx: float = _config.get_setting("sfx")
	var ambience: float = _config.get_setting("ambience")

	
		
	# Set the volume
	AudioServer.set_bus_volume_db(0, master)
	AudioServer.set_bus_volume_db(1, music)
	AudioServer.set_bus_volume_db(2, ambience)
	AudioServer.set_bus_volume_db(3, sfx)

	# Mute if appropriate
	if master == -15  :
		AudioServer.set_bus_mute(0, true)
	else:
		AudioServer.set_bus_mute(0, false)
	
	if music == -15:
		AudioServer.set_bus_mute(1, true)
	else:
		AudioServer.set_bus_mute(1, false)
		
	if ambience == -15:
		AudioServer.set_bus_mute(2, true)
	else:
		AudioServer.set_bus_mute(2, false)
		
	if sfx == -15:
		AudioServer.set_bus_mute(3, true)
	else:
		AudioServer.set_bus_mute(3, false)
