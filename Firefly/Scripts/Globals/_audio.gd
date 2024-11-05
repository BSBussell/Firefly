extends Node


var current_level_fx: Array

func _ready():
	
	
	# Update sliders when config is changed
	_config.connect_to_config_changed(Callable(self, "update_sliders"))
	_config.load_settings()
	update_sliders()

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


var prev_values: Array = [null, null, null, null]
var setting_bus_index: Array = [
	"master_vol",
	"music",
	"ambience",
	"sfx"
]

func update_sliders():
	# Iterate over all the buses
	for i in range(4):
		
		var mixer_val: float = _config.get_setting(setting_bus_index[i])

		# Only update if the value has changed
		if mixer_val != prev_values[i]:
			
			# Set bus volume and mute if volume == -15
			AudioServer.set_bus_volume_db(i, mixer_val)
			AudioServer.set_bus_mute(i, mixer_val == -15)
				
			# Update previous value
			prev_values[i] = mixer_val
			
			
		
