extends Node2D

@onready var game_container = $GameContainer
@onready var label = $UI/UIViewPort/Results/ColorRect/VBoxContainer/CenterContainer2/Label
@onready var color_rect = $UI/UIViewPort/Results/ColorRect


@onready var pause_menu = $UI/UIViewPort/Pause

# Called when the node enters the scene tree for the first time.
func _ready():
	
	
	#Engine.time_scale = 0.25
	
	# Set our global viewports
	_viewports.game_viewport_container = $GameContainer
	_viewports.game_viewport = $GameContainer/GameViewPort

	_viewports.ui_viewport_container = $UI
	_viewports.ui_viewport = $UI/UIViewPort
	
	# Global UI Elements
	_ui.COUNTER = $UI/UIViewPort/Results/Label
	_ui.COUNTER_ANIMATOR = $UI/UIViewPort/Results/AnimationPlayer
	_ui.ANIMATION_TIMER = $UI/UIViewPort/Results/HideTimer
	_ui.connect_timer()
	
	_ui.Victory = $UI/UIViewPort/Results/ColorRect
	
	# Let us process input even when game beat
	set_process_input(true)

func _input(_event: InputEvent) -> void:
	var scale_factors = {
		KEY_1: 0.16,
		KEY_2: 0.5,
		KEY_3: 0.75,
		KEY_4: 1,
		KEY_5: 1.25,
		KEY_6: 1.5,
		KEY_7: 1.75,
		KEY_8: 2,
		KEY_9: 2.5,
		KEY_0: 3
	}

	for key in scale_factors.keys():
		if Input.is_key_pressed(key) and Engine.time_scale != scale_factors[key]:
			var scale_factor = scale_factors[key]
			Engine.time_scale = scale_factor
			#game_container.scale = Vector2(scale_factor, scale_factor)
			#get_window().content_scale_size = base_resolution * scale_factor
			break  # Exit the loop after the first match

	
		
	if Input.is_action_just_pressed("Pause") and not color_rect.visible:
		_ui.show_counter()
		pause_menu.toggle_pause()
		
	if Input.is_action_just_pressed("reset"):
		

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

			
