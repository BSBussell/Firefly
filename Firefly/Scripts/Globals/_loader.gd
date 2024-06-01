extends Node

var level_loader: LevelLoader
var ui_loader: UiLoader

var current_path: String

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
	
	var loading_screen = await show_loading()

	current_path = path

	# Free the level
	level_loader.clear_current_level()
	# Free the Ui
	ui_loader.reset_ui()
	
	# Wait one frame, ensure its all free'd
	await get_tree().process_frame
	
	# Load new level
	var level = level_loader.load_level(current_path, spawn_id)
	# Load new ui
	ui_loader.setup(level)
	
	# Unpause 
	get_tree().paused = false

	await hide_loading(loading_screen)

func reload_level():
	load_level(current_path)


