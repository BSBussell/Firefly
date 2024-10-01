extends TextureProgressBar


# Called when the node enters the scene tree for the first time.
func _ready():
	
	_config.connect_to_config_changed(Callable(self, "config_changed"))
	config_changed()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# get_theme_constant("scale", "TextureProgressBar")
func config_changed():
	var theme_scale: float = get_theme_constant("scale", "TextureProgressBar")
	self.scale = Vector2(theme_scale, theme_scale)
