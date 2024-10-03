extends TextureRect
class_name UI_Jar

# Called when the node enters the scene tree for the first time.
func _ready():
	
	_config.connect_to_config_changed(Callable(self, "config_changed"))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func config_changed():
	
	var scale_const = theme.get_constant("scale", "UI_Jar")
	scale = Vector2(scale_const, scale_const)
