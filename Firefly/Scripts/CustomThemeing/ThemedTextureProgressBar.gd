extends TextureProgressBar


# Called when the node enters the scene tree for the first time.
func _ready():
	
	_viewports.viewer.connect_to_res_changed(Callable(self, "config_changed"))
	config_changed()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# get_theme_constant("scale", "TextureProgressBar")
func config_changed():
	
	# For some reason it takes awhile for the theme to update after its been changed in parent idk
	await get_tree().create_timer(0.001).timeout
	var theme_scale: float = get_theme_constant("scale", "TextureProgressBar")
	self.scale = Vector2(theme_scale, theme_scale)
