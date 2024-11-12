extends Node2D
class_name MovingPlatTrace

var DOT_SPRITE: PackedScene = preload("res://Scenes/Stuff/MovingPlats/PlatTraceDot.tscn")
var END_SPRITE: PackedScene = preload("res://Scenes/Stuff/MovingPlats/PlatTraceEnd.tscn")

# Number of points to sample along the curve for smoothness
@export var sample_count: int = 10

var platform_path: Path2D

func _ready():
	if get_parent() is MovingPlat:
		platform_path = get_parent() as Path2D
		update_line_from_curve()
	else:
		printerr("MovingPlatTrace needs MovingPlat as parent")

# Function to update the Line2D points based on the Curve2D
func update_line_from_curve():
	if not platform_path or not platform_path.curve:
		return
	
	# Get the total length of the curve in pixels
	var total_length = platform_path.curve.get_baked_length()
	var points = []
	
	# Sample `sample_count` points along the curve
	for i in range(sample_count):
		# Calculate the pixel offset along the curve
		var offset = total_length * (float(i) / (sample_count - 1))
		# Use the offset to get the position along the curve
		var point_pos: Vector2 = floor(platform_path.curve.sample_baked(offset))
		
		var sprite: Sprite2D 
		
		if i == 0 or i == sample_count-1:
			sprite = END_SPRITE.instantiate()
		
		else:
			sprite = DOT_SPRITE.instantiate()
			
		sprite.position = point_pos
		add_child(sprite)
		
