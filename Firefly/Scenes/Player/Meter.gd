extends TextureProgressBar

@export var increase_speed: float = 10
@export var decrease_speed: float = 20

@onready var particle = $Particle

var actual_score: float = 0
var interpolated_score: float = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	var multiplier = 1.0
	if interpolated_score > actual_score:
		multiplier = decrease_speed
	else:
		multiplier = increase_speed
	
	interpolated_score = move_toward(interpolated_score, actual_score, delta * multiplier)
	value = interpolated_score
	
	if value >= max_value:
		particle.emitting = true
	else:
		particle.emitting = false
	pass

func set_score(score):
	actual_score = min(score, 100)

# Adjust the ranges and fits the score inside it to score from jumping around weirdly
func update_range(min, max):
	var normalized_range = max_value - min_value
	var normalized_actual = (actual_score - min_value) / normalized_range
	var normalized_interp = (interpolated_score - min_value) / normalized_range
	
	var new_range = max - min
	actual_score = (normalized_actual * new_range) + min
	interpolated_score = (normalized_interp * new_range) + min
	
	min_value = min
	max_value = max
	
