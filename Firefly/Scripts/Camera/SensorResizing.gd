extends Node2D
## This script just resizes the camera sensor based on our camera's properties


# Establish our cam and parent
@onready var parent: Marker2D = $".."
@onready var cam: Camera2D = $"../Camera2D"

@onready var sensor_shape: CollisionShape2D = $Area2D/SensorShape

# The resolution we are currently rendering at (maybe should just reference this directly)
@onready var render_size: Vector2 = _globals.RENDER_SIZE

# Called when the node enters the scene tree for the first time.
func _ready():
	update_sensor()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	
	update_sensor()
	

func update_sensor():
	# Adjust the sensor's shape based on the camera's zoom
	
	var zoom_adjusted_size = _globals.RENDER_SIZE / cam.zoom
	sensor_shape.shape.extents = zoom_adjusted_size * 0.5  # Assuming a rectangular shape

	# Adjust the sensor's position to follow the camera's offset
	sensor_shape.position = cam.offset
