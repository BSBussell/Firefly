extends ProgressBar


## The speed at which the progress bar will move towards the target value.
@export var speed: float = 10.0


var target_value: float = 0
var interpolated_value: float = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame when there is a new target value to reach.
func _process(delta):

	interpolated_value = move_toward(interpolated_value, target_value, delta * speed)
	value = interpolated_value

	# If we have reached the interpolated value, stop calling the process function
	if interpolated_value == value:
		set_process(false)

func set_target_value(new_value: float):

	target_value = new_value
	set_process(true)