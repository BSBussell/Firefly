extends Node2D
class_name GameViewer

## The default resolution for the game
const BASE_RENDER: Vector2i = Vector2i(320, 180)

const BASE_UI_RENDER: Vector2i = Vector2i(1920, 1080)

@export var start_level: PackedScene

# Our loaders
@onready var level_loader: LevelLoader = $GameContainer
@onready var ui_loader: UiLoader = $UI

# Our ViewPorts
@onready var game_view_port = $GameContainer/GameViewPort
@onready var ui_view_port = $UI/UIViewPort

## The default resolution in the monitor's aspect ratio
var base_aspect_ratio: Vector2i = Vector2i(320, 180)

## The Resolution of the game scaled up from aspect ratio
var game_res: Vector2i = Vector2i(320, 180)

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
	_loader.load_level(start_level.resource_path)

	# Set the window size to be windowed
	set_windowed_scale()

	# Get zoom from config
	res_scale = _config.get_setting("game_zoom")

	# Smoothly zoom the render to the current scale
	smoothly_zoom_render(res_scale)
	
	# Let us process input even when game beat
	set_process_input(true)


func _input(_event: InputEvent) -> void:
	
	# Handle Resets
	if Input.is_action_just_pressed("reset") and not _loader.loading:
		
		_stats.DEATHS = 0
		_stats.reset_timer()
		_stats.INVALID_RUN = false
		
		_jar_tracker.reset_jars()
		
		# Reload the scene
		get_tree().paused = false
		
		_loader.load_level(start_level.resource_path)
			

	## All these handle is the zooming in and out of gam
	if Input.is_action_just_pressed("scale_inc"):
		
		res_scale = move_toward(res_scale, 1.4, 0.1)

		# Set Config
		_config.set_setting("game_zoom", res_scale)
		_config.save_settings()
		print("inc: ", res_scale)
		smoothly_zoom_render(res_scale)
	
	elif Input.is_action_just_pressed("scale_dec"):
		
		res_scale = move_toward(res_scale, 0.5, 0.1)
		# Set Config
		_config.set_setting("game_zoom", res_scale)
		_config.save_settings()
		print("dec:", res_scale)
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
func update_window_size() -> void:

	# Convert the base_ui_render to the aspect ratio of the screen
	window_scale = ceil(BASE_UI_RENDER.x / BASE_RENDER.x)

	# Multiply the aspect ratio by the default scale
	window_size = base_aspect_ratio * window_scale

	# Set the window size
	DisplayServer.window_set_size(window_size)

func set_windowed_scale() -> void:

	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)	

	# Recheck/set the aspect ratio
	update_aspect_ratio()

	# Updates the window size based on the aspect ratio
	update_window_size()

	# zoom_render in order to set the render resolution
	zoom_render(res_scale)

	# If the player has zoomed in then update the resolution accordingly
	update_gameview_res()

	# Update the viewports using the window scale
	set_viewports_scale(window_scale)

	# Set the window size to the target window size
	DisplayServer.window_set_size(window_size)
		
func set_fullscreen_scale():
	
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

	## Update Render Scaling
	var screen_size = get_usable_screen_size()
	
	window_size = screen_size

	# Update Rendering size for various aspect ratios
	update_aspect_ratio()
	
	window_scale = int(screen_size.x / base_aspect_ratio.x)

	# Resize the games viewport scaling
	# set_viewports_scale(window_scale)
	rescale_game_viewport(window_scale)
	rescale_ui_viewport(screen_size)

	zoom_render(res_scale)

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

	_logger.info(str(screen_size))
	_logger.info(str(base_aspect_ratio))
	

## Resizes the game to the aspect ratio of the screen
func resize_to_aspect_ratio():

	# Recalculate the aspect ratio, just in case
	update_aspect_ratio()

	# Then rescale the game, by the current res_scale
	zoom_render(res_scale)
	update_gameview_res()
	

## Matches the game viewports to the current game resolution
func update_gameview_res():
	
	game_view_port.size = game_res
	game_view_port.size_2d_override = game_res


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

		# Interpolate the goal resolution
		var float_res: Vector2 = Vector2(game_res).lerp(target_res, t)
		
		# Round up to the nearest integer
		game_res = ceil(float_res)
		_globals.RENDER_SIZE = game_res

		window_scale = lerp(window_scale, target_scale, t)

		update_gameview_res()
		rescale_game_viewport(window_scale)

		if t >= 1.0:
			interpolating_res = false  # Stop interpolating_res

func _process(delta):
	
	res_interpolate(delta)


## Smoothly Zooms in and out the game render using interpolation
func smoothly_zoom_render(new_scale: float) :
	
	# Set our target res and scale
	target_res = base_aspect_ratio * new_scale
	target_scale = snappedf(float(window_size.x) / float(target_res.x), 0.01)
	
	# Add Extra Padding to the target scale
	target_scale += 0.15
	
	

	# Setup the interpolation
	interpolating_res = true
	scale_progress = 0.0
	

## Zooms the game render to a new scale immediately
func zoom_render(new_scale: float) :
	
	# New pixel art, rendering size
	game_res = base_aspect_ratio * new_scale
	_globals.RENDER_SIZE = game_res
	
	window_scale = snappedf(float(window_size.x) / float(game_res.x), 0.01)
	
	# Extra Padding
	window_scale += 0.15
	
	
	
	# Take the scale and game res and resize viewports
	update_gameview_res()
	rescale_game_viewport(window_scale)



## Works on Apple Silicon Macbooks :/ (this is kinda bad idk how else id do this tbh)
func get_usable_screen_size() -> Vector2i:


	# Find the screen size and then aspect ratio of the screen
	var screen_size = DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
	var aspect_ratio: float = float(screen_size.x) / float(screen_size.y)

	# If the aspect ratio matches a silicon mac laptop
	if aspect_ratio == (3456.0 / 2234.0):
		screen_size.y -= 74
	
	return screen_size
