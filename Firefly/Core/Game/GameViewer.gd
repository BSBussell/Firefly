extends Node2D

@onready var game_container = $GameContainer
@onready var collectible_counter: JarCounter
@onready var results: VictoryScreen

@onready var level_loader: LevelLoader = $GameContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# Set our global viewports
	_viewports.game_viewport_container = $GameContainer
	_viewports.game_viewport = $GameContainer/GameViewPort

	_viewports.ui_viewport_container = $UI
	_viewports.ui_viewport = $UI/UIViewPort
	
	
	# Load our level
	level_loader.load_level("res://Scenes/Levels/tutorial.tscn")
	
	if level_loader.victory_screen:
		results = level_loader.victory_screen
	
	if level_loader.counter:
		collectible_counter = level_loader.counter
	
	# Let us process input even when game beat
	set_process_input(true)

func _input(_event: InputEvent) -> void:
	
	# Handle Pausing
	if Input.is_action_just_pressed("Pause") and not results.displayed:
		level_loader.pause_menu.toggle_pause()
		
		if level_loader.pause_menu.paused:
			collectible_counter.show_counter()
		else:
			collectible_counter.hide_counter(0.01)
		
	# Handle Resets
	if Input.is_action_just_pressed("reset"):
		
		_stats.DEATHS = 0
		_stats.TIME = 0

		

		# Reload the scene
		get_tree().paused = false
		
		_viewports.game_viewport_container.reload_level()
		collectible_counter.setup(results)
		results.hide_Victory_Screen()
		


func swap_fullscreen_mode():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)




			
