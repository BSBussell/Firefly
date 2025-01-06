extends Label
@onready var flyph = $"../.."


# Called when the node enters the scene tree for the first time.
func _ready():
	_config.connect_to_config_changed(Callable(self, "update_speedometer"))
	update_speedometer()
	

var axis: int

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	if axis != 0:
		var speed: float
		
		if axis == 1:
			speed = abs(flyph.velocity.x)
		elif axis == 2:
			speed = abs(flyph.velocity.y)
		else:
			speed = abs(flyph.velocity.length())
		
		text = "%d" % speed
		
func update_speedometer():
	
	axis = _config.get_setting("show_speedometer")
	
	if axis != 0:
		visible = true	
	else:
		visible = false
