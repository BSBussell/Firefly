extends Level


@export var STEPS: int = 3
@onready var ambience = $LevelAudio/Ambience
@onready var walking = $LevelAudio/Walking
 

# Called when the node enters the scene tree for the first time.
func local_ready():
	ambience.play(479)
	
	await get_tree().create_timer(2.0).timeout
	walking.play()
	


var num_loops = 0
func _on_walking_finished():
	num_loops += 1
	
	if num_loops >= STEPS:
		walking.stop()
	else:
		walking.play()
