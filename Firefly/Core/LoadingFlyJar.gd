extends TextureRect
class_name UI_Jar

# Called when the node enters the scene tree for the first time.
func _ready():
	scale_jar()


func scale_jar():	
	var scale_const = theme.get_constant("scale", "UI_Jar")
	scale = Vector2(scale_const, scale_const)
