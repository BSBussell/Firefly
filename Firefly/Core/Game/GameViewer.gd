extends Node2D

@onready var game_container = $GameContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# Set our global viewports
	_viewports.game_viewport_container = $GameContainer
	_viewports.game_viewport = $GameContainer/GameViewPort

	_viewports.ui_viewport_container = $UI
	_viewports.ui_viewport = $UI/UIViewPort



func _unhandled_input(event: InputEvent) -> void:
	var base_resolution = Vector2i(320, 180)
	var scale_factors = {
		KEY_1: 1,
		KEY_2: 2,
		KEY_3: 3,
		KEY_4: 4,
		KEY_5: 5,
		KEY_6: 6,
		KEY_7: 7,
		KEY_8: 8,
		KEY_9: 9,
		KEY_0: 12
	}

	for key in scale_factors.keys():
		if Input.is_key_pressed(key):
			var scale_factor = scale_factors[key]
			game_container.scale = Vector2(scale_factor, scale_factor)
			get_window().content_scale_size = base_resolution * scale_factor
			break  # Exit the loop after the first match

	if Input.is_key_pressed(KEY_ESCAPE):
		swap_fullscreen_mode()

func swap_fullscreen_mode():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MAXIMIZED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)

		
		
			
