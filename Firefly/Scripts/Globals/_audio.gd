extends Node


var current_level_fx: Array

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


