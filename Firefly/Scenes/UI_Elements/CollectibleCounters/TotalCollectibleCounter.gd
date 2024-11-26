extends UiComponent
class_name TotalJarCounter

@export var CONTAINER: Control
@export var LEVEL_COUNTER: Label 
@export var GAME_COUNTER: Label
@export var COUNTER_ANIMATOR: AnimationPlayer
@export var ANIMATION_TIMER: Timer

var out: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# Get all the jars in the level that are not blue
	var yellow_jars: Array = _jar_tracker.filter(func (value): 
		
		var level_match: bool = value["level_id"] == _globals.ACTIVE_LEVEL.id
		var is_yellow: bool = value["blue"] == false
		return level_match and is_yellow
		
	)
	
	var jar_max: int = yellow_jars.size()
	var collected: int = _jar_tracker.num_found_jars(_globals.ACTIVE_LEVEL.id)
	
	LEVEL_COUNTER.text = "%d/%d" % [jar_max, collected]
	
	
	


	
func show_counter():
	
	# Get the levels jars thar are not blue
	var yellow_jars: Array = _jar_tracker.filter(func (value): 
		
		var level_match: bool = value["level_id"] == _globals.ACTIVE_LEVEL.id
		var is_yellow: bool = value["blue"] == false
		return level_match and is_yellow
		
	)
	var jar_max: int = yellow_jars.size()
	
	
	var collected: int = _jar_tracker.num_found_jars(_globals.ACTIVE_LEVEL.id)
	
	LEVEL_COUNTER.text = "%d/%d" % [collected, jar_max]
	
	collected = _jar_tracker.total_num_found_jars()
	jar_max = _jar_tracker.filter(func (value):
		return value["blue"] == false
	).size()
	
	GAME_COUNTER.text  = "%d/%d" % [collected, jar_max]
	
	
	if not out:
		play_show()
		out = true

func hide_counter(time: float = 3.0):
	ANIMATION_TIMER.start(time)

func _on_hide_timer_timeout():
	out = false
	play_hide()

## Ensures that on animation playing we don't teleport pos
func play_show():
	
	var current_pos = CONTAINER.anchor_left  
	COUNTER_ANIMATOR.get_animation("Show").track_set_key_value(0, 0, current_pos)
	COUNTER_ANIMATOR.play("Show")
	
## Ensures that on animation playing we don't teleport pos
func play_hide():
	var current_pos = CONTAINER.anchor_left
	COUNTER_ANIMATOR.get_animation("Hide").track_set_key_value(0, 0, current_pos)
	COUNTER_ANIMATOR.play("Hide")
	
