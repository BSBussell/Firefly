extends Node

var level_loader: LevelLoader
var ui_loader: UiLoader

var current_path: String

func connect_loaders(ll: LevelLoader, ui: UiLoader):
	level_loader = ll
	ui_loader = ui

	
	

func load_level(path: String):
	

	current_path = path

	# Free the level
	level_loader.clear_current_level()
	# Free the Ui
	ui_loader.reset_ui()
	
	# Wait one frame, ensure its all free'd
	await get_tree().process_frame
	
	# Load new level
	var level = level_loader.load_level(current_path)
	# Load new ui
	ui_loader.setup(level)

func reload_level():
	load_level(current_path)


