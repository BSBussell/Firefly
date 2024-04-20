extends Node2D
class_name GameViewer

# Our loaders
@onready var level_loader: LevelLoader = $GameContainer
@onready var ui_loader: UiLoader = $UI

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# Set our global viewports
	_viewports.game_viewport_container = $GameContainer
	_viewports.game_viewport = $GameContainer/GameViewPort

	_viewports.ui_viewport_container = $UI
	_viewports.ui_viewport = $UI/UIViewPort
	
	_loader.connect_loaders(level_loader, ui_loader)
	# Load our level
	_loader.load_level("res://Scenes/Levels/tutorial.tscn")
	
	# Let us process input even when game beat
	set_process_input(true)

func _input(_event: InputEvent) -> void:
	
	# Handle Resets
	if Input.is_action_just_pressed("reset"):
		
		_stats.DEATHS = 0
		_stats.TIME = 0

		# Reload the scene
		get_tree().paused = false
		
		_loader.reload_level()
		

# Stuff Game View Handles
func swap_fullscreen_mode():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)




			
