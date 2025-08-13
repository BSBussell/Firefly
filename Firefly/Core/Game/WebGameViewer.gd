extends GameViewer
class_name WebGameViewer

## Web-specific version of GameViewer that disables manual resolution handling
## and defers all scaling/resizing to Godot's web platform handling.
## 
## This version:
## - Disables manual zoom controls (scale_inc/scale_dec inputs)
## - Removes complex window/fullscreen management 
## - Uses fixed viewport sizes (BASE_RENDER for game, BASE_UI_RENDER for UI)
## - Lets the browser handle canvas scaling and aspect ratio
## - Maintains compatibility with the rest of the Firefly architecture

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
	
	# Connect Config change function for basic settings
	_config.connect_to_config_changed(Callable(self, "config_changed"))
	
	# Initialize basic configuration
	config_changed()
	
	# Set basic game resolution for web
	game_res = BASE_RENDER
	_globals.RENDER_SIZE = game_res
	
	# Initialize viewports with base resolution
	init_web_viewports()
	
	# Hide mouse cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

## Override input handling to disable manual zoom controls for web
func _input(_event: InputEvent) -> void:
	# Disable zoom controls on web - let browser handle scaling
	pass

## Initialize viewports for web platform - let Godot handle scaling
func init_web_viewports():
	# Calculate scale factor from base game res to UI res
	var scale_factor = float(BASE_UI_RENDER.x) / float(BASE_RENDER.x)
	
	# Set game viewport to base resolution
	game_view_port.size = BASE_RENDER
	game_view_port.size_2d_override = BASE_RENDER
	
	# Set UI viewport to base UI resolution
	ui_view_port.size = BASE_UI_RENDER
	
	# Scale the game viewport container to match UI scale
	level_loader.scale = Vector2(scale_factor, scale_factor)
	level_loader.position = Vector2.ZERO

## Override: No fullscreen handling on web
func swap_fullscreen_mode():
	# Web platform doesn't support manual fullscreen mode switching
	pass

## Override: No window resizing on web
func update_window_size(_win_scale: float = -1) -> void:
	# Web platform defers window sizing to browser
	pass

## Override: No windowed scaling on web
func set_windowed_scale(_win_scale: float = -1) -> void:
	# Web platform doesn't support windowed mode
	pass

## Override: No fullscreen scaling on web  
func set_fullscreen_scale():
	# Web platform handles fullscreen automatically
	pass

## Override: No manual viewport scaling on web
func set_viewports_scale(_scale_factor: float):
	# Web platform uses fixed viewport sizes
	pass

## Override: No UI viewport rescaling on web
func rescale_ui_viewport(_screen_size):
	# Web platform uses fixed UI viewport size
	pass

## Override: No game viewport rescaling on web
func rescale_game_viewport(_scale_factor):
	# Web platform uses fixed game viewport size
	pass

## Override: No aspect ratio updates on web
func update_aspect_ratio():
	# Web platform defers aspect ratio handling to browser
	pass

## Override: No aspect ratio resizing on web
func resize_to_aspect_ratio():
	# Web platform defers aspect ratio handling to browser
	pass

## Override: No game view resolution updates on web
func update_gameview_res():
	# Web platform uses fixed resolution
	pass

## Override: No theme updates based on resolution on web
func update_brimblo():
	# Web platform uses base theme without resolution-based scaling
	global_themer.scale_theme(BASE_UI_RENDER)

## Override: No resolution interpolation on web
func res_interpolate(_delta: float):
	# Web platform doesn't support dynamic resolution scaling
	pass

## Override: No process loop for resolution changes
func _process(_delta):
	# Web platform doesn't need resolution interpolation
	pass

## Override: No smooth zoom on web
func smoothly_zoom_render(_new_scale: float):
	# Web platform doesn't support zoom controls
	pass

## Override: No manual zoom on web
func zoom_render(_new_scale: float):
	# Web platform doesn't support zoom controls
	pass

## Override: Not needed on web
func get_usable_screen_size() -> Vector2i:
	# Web platform doesn't need screen size detection
	return BASE_UI_RENDER

## Override: Simplified config changes for web
func config_changed():
	# Handle basic FPS settings
	update_fps(_config.get_setting("fps_target"))
	
	# Handle VSync if supported on web
	handle_vsync()

## Handle VSync settings for web
func handle_vsync():
	if _config.get_setting("vsync") and DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_DISABLED:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	elif not _config.get_setting("vsync") and DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_ENABLED:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

## Override: Simplified FPS update for web
func update_fps(config_val: int) -> void:
	if current_fps_val == config_val:
		return
	
	current_fps_val = config_val	
	Engine.set_max_fps(fps_key_map[current_fps_val])
	print("Web FPS updated to:", str(Engine.get_max_fps()))
