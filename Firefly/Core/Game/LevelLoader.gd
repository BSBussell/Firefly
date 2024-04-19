extends Node
class_name LevelLoader

const PAUSE_MENU: PackedScene = preload("res://Core/Game/pause.tscn")
const COLLECTIBLE_COUNTER: PackedScene = preload("res://Scenes/UI_Elements/collectible_counter.tscn")
const RESULTS: PackedScene = preload("res://Scenes/UI_Elements/results.tscn")

@onready var game_view_port = $GameViewPort

var current_level_path: String
var current_level_instance: Level = null

var pause_menu: PauseMenu
var victory_screen: VictoryScreen
var counter: JarCounter

func load_level(level_path: String):
	clear_current_level()
	current_level_path = level_path
	
	# Load the PackedScene from the specified path
	var level_scene = load(level_path) as PackedScene
	if level_scene:
		current_level_instance = level_scene.instantiate()
		game_view_port.add_child(current_level_instance)
		setup_ui()
	else:
		print("Failed to load level as a PackedScene at path:", level_path)

func reload_level() -> void:
	load_level(current_level_path)
	

func clear_current_level():
	if current_level_instance:
		current_level_instance.queue_free()
		current_level_instance = null


func setup_ui():
	
	if current_level_instance.Can_Pause:
		print("Setting Up Pause Instance")
		pause_menu = PAUSE_MENU.instantiate()
		_viewports.ui_viewport.add_child(pause_menu)
		pause_menu.visible = false
	
	# If there are jars to collect
	if current_level_instance.jar_manager:
		
	
		# Setup Victory Screen
		victory_screen = RESULTS.instantiate()
		_viewports.ui_viewport.add_child(pause_menu)
		# Setup Results Screen
		#pass
		
	pass
