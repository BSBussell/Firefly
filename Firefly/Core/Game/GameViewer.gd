extends Node2D

@onready var game_container = $GameContainer
@onready var label = $UI/UIViewPort/Results/ColorRect/VBoxContainer/CenterContainer2/Label
@onready var color_rect = $UI/UIViewPort/Results/ColorRect


@onready var pause_menu = $UI/UIViewPort/Pause

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# Set our global viewports
	_viewports.game_viewport_container = $GameContainer
	_viewports.game_viewport = $GameContainer/GameViewPort

	_viewports.ui_viewport_container = $UI
	_viewports.ui_viewport = $UI/UIViewPort
	
	
	# Load our level
	_viewports.game_viewport_container.load_level("res://Scenes/Levels/tutorial.tscn")
	
	# Let us process input even when game beat
	set_process_input(true)

func _input(_event: InputEvent) -> void:
	
	# Handle Pausing
	if Input.is_action_just_pressed("Pause") and not color_rect.visible:
		_ui.show_counter()
		pause_menu.toggle_pause()
		
	# Handle Resets
	if Input.is_action_just_pressed("reset"):
		
		_stats.DEATHS = 0
		_stats.TIME = 0

		_ui.COLLECTED = 0

		# Reload the scene
		get_tree().paused = false
		
		_viewports.game_viewport_container.reload_level()
		color_rect.hide()
		


func swap_fullscreen_mode():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)




			
