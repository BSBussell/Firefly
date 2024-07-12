extends ParallaxBackground

@export var scroll_speed: float = 50.0
var dst: float = 0

func _process(delta):
	dst -= scroll_speed * delta
	set_scroll_offset(Vector2(dst,0))
	
	
