extends Label
@onready var flyph = $"../.."


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if _config.get_setting("show_speedometer"):
		visible = true
		text = "%d" % flyph.velocity.x
	else:
		visible = false
