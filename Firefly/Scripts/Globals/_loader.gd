extends Node

var level_loader: LevelLoader
var ui_loader: UiLoader

## Local path of the currently loaded level
var current_path: String

signal finished_loading

## If the game is currently loading a level
var loading: bool = true

var title_screen: NodePath = NodePath("res://Scenes/Levels/TitleScreen/title_screen.tscn")

## Loads and displays the loading screen
func show_loading() -> Control:
	var loading_screen = preload("res://Core/loading_screen.tscn").instantiate()
	if _viewports.ui_viewport:
		_viewports.ui_viewport.add_child(loading_screen)
		loading_screen.play_animation("load_in")
		
		# Wait for the animation to finish before continuing 
		await loading_screen.animation_player.animation_finished
	return loading_screen  # Return the instance to manage it later

## Hides and unloads the loading screen
func hide_loading(loading_screen) -> void:
	loading_screen.play_animation("load_out")
	await loading_screen.animation_player.animation_finished

## Connects the level loader and ui loader to the global loader so it can synchronize them
func connect_loaders(ll: LevelLoader, ui: UiLoader):
	level_loader = ll
	ui_loader = ui

	
## Loads a level using a given path
func load_level(path: String, spawn_id: String = "", disp_loading: bool = true):

	loading = true

	# Save the current level path
	current_path = path

	# Begin loading the level in the background
	level_loader.begin_threaded_loading(path)

	## Save all data before unloading the level
	_persist.save_values()

	# Stop the timer while the loading screen is being displayed
	_stats.stop_timer()
	
	var loading_screen: Control
	if disp_loading:
		loading_screen = await show_loading()

	# Free the level
	level_loader.clear_current_level()
	_globals.ACTIVE_PLAYER = null
	_globals.ACTIVE_LEVEL = null

	# Free the Ui
	ui_loader.reset_ui()
	
	# Wait until level loaders "level_free" signal is emitted, if it hasn't already
	if not level_loader.finished_cleaning():
		await level_loader.level_free

	# Load new level
	var level = level_loader.load_level(current_path, spawn_id)

	# Load new ui
	ui_loader.setup(level)

	# Unpause the game if it was paused for some reason
	get_tree().paused = false

	# Load all data after loading the level
	_persist.load_values()

	# Set loading to false
	loading = false

	# Emit signal to notify that the level has finished loading to any listeners
	emit_signal("finished_loading")
	
	# Once the screen is uncovered, resume the timer
	_stats.start_timer()
	
	# Hide the loading screen
	if disp_loading:
		await hide_loading(loading_screen)



func reload_level(spawn_id: String = ""):
	load_level(current_path, spawn_id)
	
func return_to_title():
	await load_level(title_screen)
	
	# Don't run clock on title screen
	_stats.stop_timer()

func reset_game(level_path: String):

	_stats.reset_stats()
	_jar_tracker.reset_jars()
	
	_persist.reset()

	load_level(level_path)

	# Await finished loading signal
	await finished_loading
	
	print("Game Reset")
	_jar_tracker.reset_jars()
	
	


	

