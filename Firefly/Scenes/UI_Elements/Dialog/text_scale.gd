extends RichTextLabel

@export var high_dpi_font: int = 64



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var current_resolution = DisplayServer.window_get_size()
	
	if current_resolution.x >   1920:
		add_theme_font_size_override("normal_font_size", high_dpi_font)
	else:
		remove_theme_font_size_override("normal_font_size")
