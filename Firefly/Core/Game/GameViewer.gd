extends Node2D
class_name GameViewer

const target_rendering: Vector2i = Vector2i(320, 180)

@export var start_level: PackedScene

# Our loaders
@onready var level_loader: LevelLoader = $GameContainer
@onready var ui_loader: UiLoader = $UI

# Our ViewPorts
@onready var game_view_port = $GameContainer/GameViewPort
@onready var ui_view_port = $UI/UIViewPort


var current_scale: int

# Called when the node enters the scene tree for the first time.
func _ready():
	
	_viewports.viewer = self
	
	# Set our global viewports
	_viewports.game_viewport_container = level_loader
	_viewports.game_viewport = game_view_port

	_viewports.ui_viewport_container = ui_loader
	_viewports.ui_viewport = ui_view_port
	
	_loader.connect_loaders(level_loader, ui_loader)
	
	# Load our level
	_loader.load_level(start_level.resource_path)
	
	var window_size = DisplayServer.window_get_size()
	current_scale = int(window_size.x / target_rendering.x)
	set_render_scale(current_scale)

	# Let us process input even when game beat
	set_process_input(true)

func _input(event: InputEvent) -> void:
	
	# Handle Resets
	if Input.is_action_just_pressed("reset"):
		
		_stats.DEATHS = 0
		_stats.TIME = 0

		# Reload the scene
		get_tree().paused = false
		
		_loader.reload_level()
		
	if Input.is_action_just_pressed("scale_inc"):
		current_scale += 1
		set_render_scale(current_scale)
	
	if Input.is_action_just_pressed("scale_dec"):
		current_scale -= 1
		set_render_scale(current_scale)


#func _process(_delta):
	#if last_size != DisplayServer.window_get_size():
		#last_size = DisplayServer.window_get_size()
		#resize_viewport(last_size)
	

# Stuff Game View Handles
func swap_fullscreen_mode():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		
		# Update Render Scaling
		#var window_size = DisplayServer.window_get_size()
		#print(window_size)
		#current_scale = int(window_size.x / target_rendering.x)
		set_render_scale(current_scale)
		
		
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		
		## Update Render Scaling
		#OS.get_screen_size().
		var window_size = DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
		resize_game_viewport(int(window_size.x / target_rendering.x))
		ui_view_port.size = window_size


func set_render_scale(scale_factor: int):
	
	
	
	# Resize the Ui Renderer
	resize_ui_viewport(scale_factor * target_rendering)
	
	# Resizes the Game renderer
	resize_game_viewport(scale_factor)

func resize_ui_viewport(screen_size):
	ui_view_port.size = screen_size
	
	

# Resize the games
func resize_game_viewport(scale_factor):
	
	
	level_loader.scale = Vector2i(scale_factor, scale_factor)


			
