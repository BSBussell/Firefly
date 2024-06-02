extends UiComponent
class_name GameTimer

@onready var timer: Label = $Label
@onready var animation: AnimationPlayer = $AnimationPlayer

var is_visible = true

func _ready():

	timer.text = _stats.get_timer_string()
	play_animation("show")
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	

	if is_visible:
		timer.text = _stats.get_timer_string()

## Hides the Speedrun Timer
func hide_timer():

	is_visible = false

	# Idk why this is so weird
	if timer:
		play_animation("hide")

## Shows the display timer
func show_timer():
	
	is_visible = true

	# Idk why this is so weird
	if timer:
		timer.text = _stats.get_timer_string()
		play_animation("show")


func play_animation(anim_name: String):
	var current_pos = timer.offset_bottom
	animation.get_animation(anim_name).track_set_key_value(0, 0, current_pos)
	animation.play(anim_name)