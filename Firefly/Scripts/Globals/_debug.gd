extends Node

func _input(_event: InputEvent) -> void:
	
	var scale_factors = {
		KEY_1: 0.16,
		KEY_2: 0.5,
		KEY_3: 0.75,
		KEY_4: 1,
		KEY_5: 1.25,
		KEY_6: 1.5,
		KEY_7: 1.75,
		KEY_8: 2
	}

	for key in scale_factors.keys():
		if Input.is_key_pressed(key) and Engine.time_scale != scale_factors[key]:
			var scale_factor = scale_factors[key]
			Engine.time_scale = scale_factor
			break

	# Load Tutorial
	if Input.is_key_pressed(KEY_9):
		_viewports.game_viewport_container.clear_current_level()
		_viewports.game_viewport_container.load_level("res://Scenes/Levels/tutorial.tscn")
		
	if Input.is_key_pressed(KEY_0):
		_viewports.game_viewport_container.clear_current_level()
		_viewports.game_viewport_container.load_level("res://Scenes/Levels/debug.tscn")
		
		
