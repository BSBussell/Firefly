extends Node2D
class_name GameViewer

## The default resolution for the game
const BASE_RENDER: Vector2i = Vector2i(320, 180)

const BASE_UI_RENDER: Vector2i = Vector2i(1920, 1080)

const MIN_ZOOM: float = 0.5
const MAX_ZOOM: float = 1.4
const ZOOM_STEP: float = 0.05
const GAME_VIEWPORT_PADDING_SCALE: float = 1.4 
const LINUX_WINDOW_SERVERS: PackedStringArray = [
	"Linux",
	"FreeBSD",
	"NetBSD",
	"OpenBSD",
	"BSD"
]
const FPS_PRESETS: Array[int] = [30, 60, 90, 120, 144, 165, 240, 0]

signal res_changed

@export var start_level: PackedScene

# Our loaders
@onready var level_loader: LevelLoader = $LevelLoader
@onready var ui_loader: UiLoader = $UILoader

# Our ViewPorts
@onready var game_view_port: SubViewport = $LevelLoader/GameViewPort
@onready var ui_view_port: SubViewport = $UILoader/UIViewPort
@onready var _IM: InputManager = _input_manager

# Our Theme Node
@onready var global_themer: GlobalThemer = $UILoader/UIViewPort/GlobalThemer

## The default resolution in the monitor's aspect ratio
var base_aspect_ratio: Vector2i = BASE_RENDER

## The Resolution of the game scaled up from aspect ratio
var game_res: Vector2 = Vector2(BASE_RENDER)
 
## Window Size
var window_size: Vector2i = Vector2i(1920, 1080)

## Captures safe-area offsets reported by the platform (e.g. macOS notch top inset)
var fullscreen_safe_offset: Vector2i = Vector2i.ZERO

## The scale for the game res to the window size
var window_scale: float = 1.0

## The scale of the render resolution, up from the base resolution
var res_scale: float = 1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
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

	config_scale = -1
	config_changed()

	# Get zoom from config
	res_scale = clamp(float(_config.get_setting("game_zoom")), MIN_ZOOM, MAX_ZOOM)

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
	if _IM.is_down(&"scale_inc"):
		
		res_scale = move_toward(res_scale, MAX_ZOOM, ZOOM_STEP)
		smoothly_zoom_render(res_scale)	 

	elif _IM.is_down(&"scale_dec"):
		
		res_scale = move_toward(res_scale, MIN_ZOOM, ZOOM_STEP)
		smoothly_zoom_render(res_scale)





# Stuff Game View Handles
func swap_fullscreen_mode() -> void:

	# Swap to window mode
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			
		set_windowed_scale()

	# Swapping to fullscreen
	else:
		
		set_fullscreen_scale()
		

# Sets the window size to be the equilvant of 1080p in the current aspect ratio
func update_window_size(win_scale: float = -1.0) -> void:

	# If web build then return
	if OS.get_name() == "HTML5":
		return

	# Convert the base_ui_render to the aspect ratio of the screen
	if win_scale > 0.0:
		window_scale = win_scale
	else:
		window_scale = ceil(float(BASE_UI_RENDER.x) / float(BASE_RENDER.x))
	
	# Multiply the aspect ratio by the default scale
	var scaled_size: Vector2 = Vector2(base_aspect_ratio) * window_scale
	window_size = Vector2i(scaled_size.ceil())

	# Force Standardized Footage Recording Resolution
	if false:
		 # Yeah obs being weird but this gives me 1080p output so
		window_size = Vector2(1920,1098)
		base_aspect_ratio = Vector2(320,183)
		window_scale =  ceil(window_size.x / base_aspect_ratio.x)

	# Set the window size
	DisplayServer.window_set_size(window_size)

func set_windowed_scale(win_scale: float = -1.0) -> void:

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

	# Reset viewport offsets for windowed layout
	apply_viewport_offsets()

	# Update Theme
	update_brimblo()

	# Set the window size to the target window size
	DisplayServer.window_set_size(window_size)
		
	# Signal to ui to resize
	emit_signal("res_changed")
		
func set_fullscreen_scale() -> void:

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
	rescale_ui_viewport(Vector2(screen_size))

	zoom_render(res_scale)

	apply_viewport_offsets()

	# Signal to ui to resize
	emit_signal("res_changed")

func set_viewports_scale(scale_factor: float) -> void:

	# Resize the Ui Renderer
	rescale_ui_viewport(game_res * scale_factor)

	# Resizes the Game renderer
	rescale_game_viewport(scale_factor)

func rescale_ui_viewport(screen_size: Vector2) -> void:
	ui_view_port.size = Vector2i(screen_size.round())

## Resize the games viewport scaling.
func rescale_game_viewport(scale_factor: float) -> void:
	level_loader.scale = Vector2.ONE * scale_factor

## Sets the aspect ratio variable
func update_aspect_ratio() -> void:

	# Find the screen size and then aspect ratio of the screen
	var screen_size = get_usable_screen_size()
	var aspect_ratio: float = float(screen_size.x) / float(screen_size.y)

	# Set the base aspect ratio
	base_aspect_ratio = BASE_RENDER
	base_aspect_ratio.y = int(ceil(float(BASE_RENDER.x) / aspect_ratio))

## Resizes the game to the aspect ratio of the screen
func resize_to_aspect_ratio() -> void:

	# Recalculate the aspect ratio, just in case
	update_aspect_ratio()

	# Then rescale the game, by the current res_scale
	zoom_render(res_scale)
	update_gameview_res()
	

## Matches the game viewports to the current game resolution
func update_gameview_res() -> void:

	var padded_size: Vector2 = Vector2(base_aspect_ratio) * GAME_VIEWPORT_PADDING_SCALE
	var padded_size_i: Vector2i = Vector2i(padded_size.ceil())
	game_view_port.size = padded_size_i
	game_view_port.size_2d_override = padded_size_i

	# adjust the viewport container to have game_res centered
	var offset: Vector2 = (padded_size - game_res) * (window_scale / 2.0)
	level_loader.position = -offset


## Updates a themes font sizes for the window res
func update_brimblo() -> void:

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
var target_res: Vector2 = Vector2(BASE_RENDER)
var target_scale: float = 1.0

# Function for smoothly interpolate resolution scale increasing
func res_interpolate(delta: float) -> void:

	if not interpolating_res:
		return

	scale_progress += delta
	var t: float = min(scale_progress / scaling_duration, 1.0)

	game_res = game_res.lerp(target_res, t)
	_globals.RENDER_SIZE = game_res

	window_scale = lerp(window_scale, target_scale, t)

	update_gameview_res()
	rescale_game_viewport(window_scale)

	if t >= 1.0:
		interpolating_res = false
		_config.set_setting("game_zoom", res_scale)

func _process(delta: float) -> void:

	res_interpolate(delta)


## Smoothly Zooms in and out the game render using interpolation
func smoothly_zoom_render(new_scale: float) -> void:

	# Set our target res and scale
	target_res = Vector2(base_aspect_ratio) * new_scale
	target_scale = float(window_size.x) / float(target_res.x)
	
	# Add Extra Padding to the target scale
	# target_scale += 0.15
	
	# Setup the interpolation
	interpolating_res = true
	scale_progress = 0.0
	

## Zooms the game render to a new scale immediately
func zoom_render(new_scale: float) -> void:

	# New pixel art, rendering size
	game_res = Vector2(base_aspect_ratio) * new_scale
	_globals.RENDER_SIZE = game_res

	window_scale = float(window_size.x) / float(game_res.x)
	
	# Extra Padding
	# window_scale += 0.15
	
	
	
	# Take the scale and game res and resize viewports
	update_gameview_res()
	rescale_game_viewport(window_scale)

func connect_to_res_changed(function: Callable) -> void:

	connect("res_changed", function)


func apply_viewport_offsets() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		ui_loader.position = -Vector2(fullscreen_safe_offset)
	else:
		ui_loader.position = Vector2.ZERO


## Works on Apple Silicon Macbooks :/ (this is kinda bad idk how else id do this tbh)
func get_usable_screen_size() -> Vector2i:


	var current_screen: int = DisplayServer.window_get_current_screen()
	var screen_size: Vector2i = DisplayServer.screen_get_size(current_screen)
	fullscreen_safe_offset = Vector2i.ZERO

	if OS.get_name() == "macOS":
		var usable_rect: Rect2i = DisplayServer.screen_get_usable_rect(current_screen)
		if usable_rect.size != Vector2i.ZERO:
			fullscreen_safe_offset = usable_rect.position
			if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
				screen_size = usable_rect.size

	return screen_size
	
var config_scale: int = 3
# if you have a worse screen just get fucked ig
var win_scale_min: int = 3
	
func config_changed() -> void:



	var resolution_setting: int = _config.get_setting("resolution")
	var fullscreen_setting: bool = _config.get_setting("fullscreen")
	var fps_setting: int = _config.get_setting("fps_target")
	var vsync_setting: bool = _config.get_setting("vsync")
	var scale_changed: bool = config_scale != (resolution_setting + win_scale_min)
	var fullscreen_on: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

	# On fullscreen enabled
	if fullscreen_setting and not fullscreen_on:
		
		set_fullscreen_scale()
		
	# On Turning off fullscreen
	elif (not fullscreen_setting and fullscreen_on):
		
		
		config_scale = resolution_setting + win_scale_min
		set_windowed_scale(resolution_setting + win_scale_min)

	# On adjusting window scale
	elif (scale_changed) and not fullscreen_on: 
		
		# Linux window servers struggle to rescale the window without a "full screen flush"
		# All odds given how like hand-coded my window scaling shit is, I imagine this is my own fault.
		# However, this projects like 11 months in at this point and we goin for a summer release so :3
		if OS.get_name() in LINUX_WINDOW_SERVERS:
			set_fullscreen_scale()
			
		config_scale = resolution_setting + win_scale_min	
		set_windowed_scale(resolution_setting + win_scale_min)
		
		
	update_fps(fps_setting)
		
	
	# If we need to turn on or off vsync
	if vsync_setting and DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_DISABLED:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	elif DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_ENABLED:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)


var current_fps_val: int = -1
func update_fps(config_val: int) -> void:

	if current_fps_val == config_val:
		return

	if config_val < 0 or config_val >= FPS_PRESETS.size():
		return


	current_fps_val = config_val	
		
	Engine.set_max_fps(FPS_PRESETS[current_fps_val])
