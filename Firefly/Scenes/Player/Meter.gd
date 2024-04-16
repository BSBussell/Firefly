extends TextureProgressBar

@export var increase_speed: float = 10
@export var decrease_speed: float = 20

@onready var particle = $Particle
@onready var fire_lit = $FireLit
@onready var fire_rumble = $FireRumble


var actual_score: float = 0
var interpolated_score: float = 0

var played_sound: bool = false

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
		
		if not played_sound:
			fire_lit.play()
			fire_rumble.play()
			played_sound = true
	else:
		particle.emitting = false
		played_sound = false
		fire_rumble.stop()
	pass

func set_score(score):
	actual_score = min(score, 100)

# Adjust the ranges and fits the score inside it to score from jumping around weirdly
func update_range(new_min, new_max):
	var normalized_range = max_value - min_value
	var normalized_actual = (actual_score - min_value) / normalized_range
	var normalized_interp = (interpolated_score - min_value) / normalized_range
	
	var new_range = new_max - new_min
	actual_score = (normalized_actual * new_range) + new_min
	interpolated_score = (normalized_interp * new_range) + new_min
	
	min_value = new_min
	max_value = new_max
	
