extends Node

var level_loader: LevelLoader
var ui_loader: UiLoader

var current_path: String

signal finished_loading

## If the game is currently loading a level
var loading: bool = true

#@onready var loading_screen = preload("res://Core/loading_screen.tscn").instantiate()


func show_loading():
	var loading_screen = preload("res://Core/loading_screen.tscn").instantiate()
	if ui_loader:
		ui_loader.add_child(loading_screen)
		loading_screen.play_animation("load_in")
		
		# Wait for the animation to finish before continuing 
		await loading_screen.animation_player.animation_finished
	return loading_screen  # Return the instance to manage it later

func hide_loading(loading_screen):
	loading_screen.play_animation("load_out")
	await loading_screen.animation_player.animation_finished

func connect_loaders(ll: LevelLoader, ui: UiLoader):
	level_loader = ll
	ui_loader = ui

	

func load_level(path: String, spawn_id: String = ""):

	loading = true

	current_path = path

	# Begin loading the level in the background
	level_loader.begin_threaded_loading(path)

	# Saving the player level before we unload them
	var player_level = 0
	if _globals.ACTIVE_PLAYER:
		player_level = _globals.ACTIVE_PLAYER.get_glow_level()

	# Stop the timer while the loading screen is being displayed
	_stats.stop_timer()
	var loading_screen = await show_loading()

	

	# Free the level
	level_loader.clear_current_level()

	
	# Free the Ui
	ui_loader.reset_ui()
	
	# Wait until level loaders "level_free" signal is emitted, if it hasn't already
	if not level_loader.finished_cleaning():
		await level_loader.level_free

	# Load new level
	var level = await level_loader.load_level(current_path, spawn_id)

	# Load new ui
	ui_loader.setup(level)

	# Unpause 
	get_tree().paused = false

	# Restoring the players level
	if _globals.ACTIVE_PLAYER:
		_globals.ACTIVE_PLAYER.glow_manager.change_state(player_level)

	loading = false

	emit_signal("finished_loading")

	await hide_loading(loading_screen)

	

	

	# Once we've finished loading start the timer
	_stats.start_timer()


func reload_level():
	load_level(current_path)

func reset_game(level_path: String):

	_stats.DEATHS = 0
	_stats.reset_timer()
	_stats.INVALID_RUN = false
	_jar_tracker.reset_jars()
	
	_globals.ACTIVE_PLAYER.glow_manager.change_state(0)

	load_level(level_path)

	# Await finished loading signal
	await finished_loading
	
	print("Game Reset")
	_jar_tracker.reset_jars()
	
	


	

