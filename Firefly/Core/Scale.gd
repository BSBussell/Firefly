extends Control

@export var high_dpi_scale: Vector2 = Vector2(2, 2)

@onready var base_scale: Vector2 = scale

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var current_resolution = DisplayServer.window_get_size()

	if current_resolution.x > 1920:
		scale = high_dpi_scale
	else:
		scale = base_scale
