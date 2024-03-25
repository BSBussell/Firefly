extends Node2D

@onready var game_container = $GameContainer
@onready var label = $UI/UIViewPort/ColorRect/VBoxContainer/CenterContainer2/Label
@onready var color_rect = $UI/UIViewPort/ColorRect

# Called when the node enters the scene tree for the first time.
func _ready():
	
	#Engine.time_scale = 0.25
	
	# Set our global viewports
	_viewports.game_viewport_container = $GameContainer
	_viewports.game_viewport = $GameContainer/GameViewPort

	_viewports.ui_viewport_container = $UI
	_viewports.ui_viewport = $UI/UIViewPort
	
	# Global UI Elements
	_ui.COUNTER = $UI/UIViewPort/Label
	_ui.COUNTER_ANIMATOR = $UI/UIViewPort/AnimationPlayer
	_ui.ANIMATION_TIMER = $UI/UIViewPort/HideTimer
	_ui.connect_timer()
	
	_ui.Victory = $UI/UIViewPort/ColorRect
	
	# Let us process input even when game beat
	set_process_input(true)




func _input(event: InputEvent) -> void:
	var base_resolution = Vector2i(320, 180)
	var scale_factors = {
		KEY_1: 1,
		KEY_2: 2,
		KEY_3: 3,
		KEY_4: 4,
		KEY_5: 5,
		KEY_6: 6,
		KEY_7: 7,
		KEY_8: 8,
		KEY_9: 9,
		KEY_0: 12
	}

	for key in scale_factors.keys():
		if Input.is_key_pressed(key):
			var scale_factor = scale_factors[key]
			game_container.scale = Vector2(scale_factor, scale_factor)
			get_window().content_scale_size = base_resolution * scale_factor
			break  # Exit the loop after the first match

	
		
	if Input.is_action_just_pressed("Pause"):
		_ui.show_counter()
		swap_fullscreen_mode()
		
	if Input.is_action_just_pressed("reset"):
		# Get the current scene's root node
		var current_scene = get_tree().current_scene


		_stats.DEATHS = 0
		_stats.TIME = 0

		_ui.COLLECTED = 0

		# Reload the scene
		
		get_tree().paused = false
		get_tree().reload_current_scene()
		color_rect.hide()
		


func swap_fullscreen_mode():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _process(delta):
	
	if not get_tree().paused:
		_stats.TIME += delta
	
	var minutes: int = int(_stats.TIME) / 60
	var seconds: int = int(_stats.TIME) % 60
	var milliseconds: int = int((_stats.TIME - int(_stats.TIME)) * 1000)
	
	var display_time = "%02d:%02d:%03d" % [minutes, seconds, milliseconds]
	
	label.text = "Time: %s\n Total Deaths: %d" % [display_time, _stats.DEATHS]

			
