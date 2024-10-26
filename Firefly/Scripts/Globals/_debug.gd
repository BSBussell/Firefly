extends Node


# quicksave location
var _quicksave_location = Vector2(0, 0)
var _quicksave_velocity = Vector2(0, 0)
var _quicksave_glow: int = 0
var _quicksave_points: float = 0

func _input(_event: InputEvent) -> void:
	
	if not Input.is_action_pressed("debug_mod"):
		return
		
		
	# Handle Resets
	if Input.is_action_just_pressed("reset") and not _loader.loading:
		
		# Reload the scene
		get_tree().paused = false
		await _loader.reset_game(NodePath("res://Scenes/Levels/TutorialLevel/tutorial.tscn"))

		
	var scale_factors = {
		KEY_1: 0.16,
		KEY_2: 0.5,
		KEY_3: 0.75,
		KEY_4: 1,
		KEY_5: 1.25,
		KEY_6: 1.5,
		KEY_7: 2.,
	}

	for key in scale_factors.keys():
		if Input.is_key_pressed(key) and Engine.time_scale != scale_factors[key]:
			var scale_factor = scale_factors[key]
			Engine.time_scale = scale_factor

			
			_stats.INVALID_RUN = true
			break

	# Load Tutorial
	if Input.is_key_pressed(KEY_8) and not _loader.loading:
		
		_stats.INVALID_RUN = true
		_loader.load_level("res://Scenes/Levels/TutorialLevel/tutorial.tscn")
		_stats.CURRENT_LEVEL = "res://Scenes/Levels/TutorialLevel/tutorial.tscn"
		
		
	# Load Debug Environment
	if Input.is_key_pressed(KEY_9) and not _loader.loading:
		_stats.INVALID_RUN = true
		_loader.load_level("res://Scenes/Levels/CaveLevel/cave_level.tscn")
		_stats.CURRENT_LEVEL = "res://Scenes/Levels/CaveLevel/cave_level.tscn"
		
		
	# Load Debug Environment
	if Input.is_key_pressed(KEY_0) and not _loader.loading:
		_stats.INVALID_RUN = true 
		_loader.load_level("res://Scenes/Levels/MountainLevel/mountain.tscn")
		_stats.CURRENT_LEVEL = "res://Scenes/Levels/MountainLevel/mountain.tscn"
		

	if Input.is_action_just_pressed("QuickSave"):
		_quicksave_location = _globals.ACTIVE_PLAYER.get_global_position()
		_quicksave_velocity = _globals.ACTIVE_PLAYER.velocity
		_quicksave_glow = _globals.ACTIVE_PLAYER.get_glow_level()
		_quicksave_points = _globals.ACTIVE_PLAYER.get_glow_score()
		_stats.INVALID_RUN = true

	if Input.is_action_just_pressed("QuickLoad"):
		_globals.ACTIVE_PLAYER.global_position = _quicksave_location
		_globals.ACTIVE_PLAYER.velocity = _quicksave_velocity
		_globals.ACTIVE_PLAYER.glow_manager.change_state(_quicksave_glow)
		_globals.ACTIVE_PLAYER.set_glow_score(_quicksave_points)
		_stats.INVALID_RUN = true
