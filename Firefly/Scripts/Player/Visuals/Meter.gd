extends UiComponent
class_name ScoreMeter


@export var increase_speed: float = 10
@export var decrease_speed: float = 20


@onready var progress_bar = $Meter
@onready var particle = $Meter/Particle
@onready var fire_lit = $Meter/FireLit
@onready var fire_rumble = $Meter/FireRumble


var actual_score: float = 0
var interpolated_score: float = 0

var played_sound: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	context.PLAYER.connect_meter(Callable(self, "set_score"))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	print("Meter _process")
	var multiplier = 1.0
	if interpolated_score > actual_score:
		multiplier = decrease_speed
	else:
		multiplier = increase_speed
	
	interpolated_score = move_toward(interpolated_score, actual_score, delta * multiplier)
	progress_bar.value = interpolated_score
	
	if progress_bar.value >= progress_bar.max_value:
		particle.emitting = true
		
		if not played_sound:
			fire_lit.play()
			fire_rumble.play()
			played_sound = true
	else:
		particle.emitting = false
		played_sound = false
		fire_rumble.stop()
		
	print("Meter Process End")

func set_score(score):
	actual_score = min(score, 100)

# Adjust the ranges and fits the score inside it to score from jumping around weirdly
func update_range(new_min, new_max):
	var normalized_range = progress_bar.max_value - progress_bar.min_value
	var normalized_actual = (actual_score - progress_bar.min_value) / normalized_range
	var normalized_interp = (interpolated_score - progress_bar.min_value) / normalized_range
	
	var new_range = new_max - new_min
	actual_score = (normalized_actual * new_range) + new_min
	interpolated_score = (normalized_interp * new_range) + new_min
	
	progress_bar.min_value = new_min
	progress_bar.max_value = new_max
	
