extends Node2D
class_name GameViewer

## The default resolution for the game
const BASE_RENDER: Vector2i = Vector2i(320, 180)

const BASE_UI_RENDER: Vector2i = Vector2i(1920, 1080)

signal res_changed

@export var start_level: PackedScene

# Our loaders
@onready var level_loader: LevelLoader = $LevelLoader
@onready var ui_loader: UiLoader = $UILoader

# Our ViewPorts
@onready var game_view_port = $LevelLoader/GameViewPort
@onready var ui_view_port = $UILoader/UIViewPort

# Our Theme Node
@onready var global_themer = $UILoader/UIViewPort/GlobalThemer

## The default resolution in the monitor's aspect ratio
var base_aspect_ratio: Vector2i = Vector2i(320, 180)

## The Resolution of the game scaled up from aspect ratio
var game_res: Vector2 = Vector2(320, 180)
 
## Window Size
var window_size: Vector2i = Vector2i(1920, 1080)

## The scale for the game res to the window size
var window_scale: float

## The scale of the render resolution, up from the base resolution
var res_scale: float = 1.0

# Called when the node enters the scene tree for the first time.
func _ready():
	
	_viewports.viewer = self
	
	# Set our global viewports
	_viewports.game_viewport_container = level_loader
	_viewports.game_viewport = game_view_port

	_viewports.ui_viewport_container = ui_loader
	_viewports.ui_viewport = ui_view_port
	
	## Connects the loaders to the global loader
	_loader.connect_loaders(level_loader, ui_loader)
	
	# Load our level
	_loader.load_level(start_level.resource_path, "", false)
	
	# Connect Config change function
	_config.connect_to_config_changed(Callable(self, "config_changed"))

	config_changed()

	# Get zoom from config
	res_scale = _config.get_setting("game_zoom")

	# Smoothly zoom the render to the current scale
	smoothly_zoom_render(res_scale)
	
	# Hide mouse cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	# Set the window size to be windowed
	# Full Screen Check
	#if _config.get_setting("fullscreen"):
		#set_fullscreen_scale()


func _input(_event: InputEvent) -> void:
	
	
		
			

	## All these handle is the zooming in and out of gam
	if Input.is_action_pressed("scale_inc"):
		
		res_scale = move_toward(res_scale, 1.4, 0.05)
		smoothly_zoom_render(res_scale)     
	
	elif Input.is_action_pressed("scale_dec"):
		
		res_scale = move_toward(res_scale, 0.5, 0.05)
		smoothly_zoom_render(res_scale)





# Stuff Game View Handles
func swap_fullscreen_mode():
	
	# Swap to window mode
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			
		set_windowed_scale()
	
	# Swapping to fullscreen
	else:
		
		set_fullscreen_scale()
		

# Sets the window size to be the equilvant of 1080p in the current aspect ratio
func update_window_size(win_scale: float = -1) -> void:

	# If web build then return
	if OS.get_name() == "HTML5":
		return

	# Convert the base_ui_render to the aspect ratio of the screen
	if win_scale != -1: window_scale = win_scale
	else: window_scale = ceil(BASE_UI_RENDER.x / BASE_RENDER.x)
	

	# Multiply the aspect ratio by the default scale
	window_size = base_aspect_ratio * window_scale
	
	print(window_size)

	# Set the window size
	DisplayServer.window_set_size(window_size)

func set_windowed_scale(win_scale: float = -1) -> void:

	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)	

	# Recheck/set the aspect ratio
	update_aspect_ratio()

	# Updates the window size based on the aspect ratio
	update_window_size(win_scale)

	# zoom_render in order to set the render resolution
	zoom_render(res_scale)

	# If the player has zoomed in then update the resolution accordingly
	update_gameview_res()

	# Update the viewports using the window scale
	set_viewports_scale(window_scale)
	
	# Update Theme
	update_brimblo()

	# Set the window size to the target window size
	DisplayServer.window_set_size(window_size)
		
	# Signal to ui to resize
	emit_signal("res_changed")
		
func set_fullscreen_scale():
	
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

	## Update Render Scaling
	var screen_size = get_usable_screen_size()
	
	window_size = screen_size
	
	# Update Theme
	update_brimblo()

	# Update Rendering size for various aspect ratios
	update_aspect_ratio()
	
	window_scale = int(screen_size.x / base_aspect_ratio.x)

	# Resize the games viewport scaling
	# set_viewports_scale(window_scale)
	rescale_game_viewport(window_scale)
	rescale_ui_viewport(screen_size)

	zoom_render(res_scale)
	
	# Signal to ui to resize
	emit_signal("res_changed")

func set_viewports_scale(scale_factor: float):
	
	# Resize the Ui Renderer
	rescale_ui_viewport(scale_factor * Vector2(game_res))
	
	# Resizes the Game renderer
	rescale_game_viewport(scale_factor)

func rescale_ui_viewport(screen_size):
	ui_view_port.size = screen_size

## Resize the games viewport scaling.
func rescale_game_viewport(scale_factor):
	level_loader.scale = Vector2(scale_factor, scale_factor)

## Sets the aspect ratio variable
func update_aspect_ratio():
	
	# Find the screen size and then aspect ratio of the screen
	var screen_size = get_usable_screen_size()
	var aspect_ratio: float = float(screen_size.x) / float(screen_size.y)
	
	# Set the base aspect ratio
	base_aspect_ratio = BASE_RENDER
	base_aspect_ratio.y = ceil( float(BASE_RENDER.x) / aspect_ratio ) 

## Resizes the game to the aspect ratio of the screen
func resize_to_aspect_ratio():

	# Recalculate the aspect ratio, just in case
	update_aspect_ratio()

	# Then rescale the game, by the current res_scale
	zoom_render(res_scale)
	update_gameview_res()
	

## Matches the game viewports to the current game resolution
func update_gameview_res():
	
	game_view_port.size = base_aspect_ratio * 1.4
	game_view_port.size_2d_override = base_aspect_ratio * 1.4

	# adjust the viewport container to have game_res centered
	level_loader.position.x = -((base_aspect_ratio.x * 1.4) - (game_res.x)) * window_scale/2
	level_loader.position.y = -((base_aspect_ratio.y * 1.4) - (game_res.y)) * window_scale/2


## Updates a themes font sizes for the window res
func update_brimblo():
	
	global_themer.scale_theme(window_size)
	#if window_size.x < 1600:
		#global_themer.theme = preload("res://UI_Theme/Brimblo_Low_PPI.tres")
	#else:
		#global_themer.theme = preload("res://UI_Theme/Brimblo.tres")

	pass


var interpolating_res: bool = false

# Lerp Progress variables
var scaling_duration: float = 1.0
var scale_progress: float = 1.0

# Target values
var target_res: Vector2i = Vector2i(320, 180)
var target_scale: float = 1.0

# Function for smoothly interpolate resolution scale increasing
func res_interpolate(delta: float):
	
	if interpolating_res:

		scale_progress += delta
		var t = min(scale_progress / scaling_duration, 1.0)  # Clamp to [0, 1]
		
		game_res = game_res.lerp(target_res, t)
		_globals.RENDER_SIZE = game_res

		window_scale = lerp(window_scale, target_scale, t)

		update_gameview_res()
		rescale_game_viewport(window_scale)

		if t >= 1.0:
			interpolating_res = false  # Stop interpolating_res
			_config.set_setting("game_zoom", res_scale)

func _process(delta):
	
	res_interpolate(delta)


## Smoothly Zooms in and out the game render using interpolation
func smoothly_zoom_render(new_scale: float) :
	
	# Set our target res and scale
	target_res = base_aspect_ratio * new_scale
	target_scale = float(window_size.x) / float(target_res.x)
	
	# Add Extra Padding to the target scale
	# target_scale += 0.15
	
	# Setup the interpolation
	interpolating_res = true
	scale_progress = 0.0
	

## Zooms the game render to a new scale immediately
func zoom_render(new_scale: float) :
	
	# New pixel art, rendering size
	game_res = base_aspect_ratio * new_scale
	_globals.RENDER_SIZE = game_res
	
	window_scale = float(window_size.x) / float(game_res.x)
	
	# Extra Padding
	# window_scale += 0.15
	
	
	
	# Take the scale and game res and resize viewports
	update_gameview_res()
	rescale_game_viewport(window_scale)

func connect_to_res_changed(function: Callable):
	
	connect("res_changed", function)


## Works on Apple Silicon Macbooks :/ (this is kinda bad idk how else id do this tbh)
func get_usable_screen_size() -> Vector2i:


	# Find the screen size and then aspect ratio of the screen
	var screen_size = DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
	var aspect_ratio: float = float(screen_size.x) / float(screen_size.y)

	# If the aspect ratio matches a silicon mac laptop
	if aspect_ratio == (3456.0 / 2234.0):
		screen_size.y -= 74
	
	return screen_size
	
var config_scale: int = 3
# if you have a worse screen just get fucked ig
var win_scale_min: int = 3
	
func config_changed():
	
	
	
	var scale_changed: bool = config_scale != (_config.get_setting("resolution") + win_scale_min)
	var fullscreen_on: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	
	# On fullscreen enabled
	if _config.get_setting("fullscreen") and not fullscreen_on:
		
		set_fullscreen_scale()
		
	# On Turning off fullscreen
	elif (not _config.get_setting("fullscreen") and fullscreen_on):
		
		
		config_scale = _config.get_setting("resolution") + win_scale_min
		set_windowed_scale(_config.get_setting("resolution") + win_scale_min)
	
	# On adjusting window scale
	elif (scale_changed) and not fullscreen_on: 
		
		# Linux window servers struggle to rescale the window without a "full screen flush"
		if OS.get_name() in ["Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD"]:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			
		config_scale = _config.get_setting("resolution") + win_scale_min	
		set_windowed_scale(_config.get_setting("resolution") + win_scale_min)
		
		
	update_fps(_config.get_setting("fps_target"))
		
	
	# If we need to turn on or off vsync
	if _config.get_setting("vsync") and DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_DISABLED:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	elif DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_ENABLED:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)


var current_fps_val: int = -1
var fps_key_map: Array = [30, 60, 90, 120, 144, 165, 240, 0]
func update_fps(config_val: int) -> void:
	
	if current_fps_val == config_val:
		return
	
	
	current_fps_val = config_val	
		
	Engine.set_max_fps(fps_key_map[current_fps_val])
	print(current_fps_val)
	print("FPS updated to:", str(Engine.get_max_fps()))
